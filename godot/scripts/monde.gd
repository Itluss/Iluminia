class_name Monde
extends Node2D
## Le monde circulaire d'Iluminia : quatre zones concentriques, décor procédural
## déterministe (même graine → même monde pour tous), 12 orbes de lumière
## secrets, apparition des ennemis et du boss, projectiles, butin et grille
## d'exploration.
##
## v2 multijoueur : ce nœud est conçu pour devenir l'autorité côté serveur
## (voir reseau.gd) — il ne lit jamais d'entrée locale.

const RAYON_MONDE := 2600.0
const RAYONS_ZONES := [650.0, 1300.0, 1950.0, 2600.0]
const NOMS_ZONES := ["Clairière", "Forêt", "Marais", "Terres Brûlées"]
const NIVEAUX_ZONES := [1, 3, 6, 10]
## Palette « bonbon » Eluminia : couleurs de sol saturées et distinctes.
const COULEURS_SOL := [
	Color(0.56, 0.85, 0.44), # Clairière — vert tendre
	Color(0.33, 0.68, 0.40), # Forêt — vert profond
	Color(0.55, 0.60, 0.38), # Marais — vert vaseux
	Color(0.72, 0.42, 0.30), # Terres Brûlées — terre cuite
]
const GRAINE := 20260813        ## graine fixe : décor identique à chaque partie
const TAILLE_CELLULE := 200.0   ## taille des cellules de la grille d'exploration
const NB_SECRETS := 12
const CHANCE_LOOT := 0.35
const DELAI_REAPPARITION := 30.0

var joueur: Joueur
var fx: FX
var hud: HUD

var ennemis: Array[Ennemi] = []
var boss: BossDragon = null
var reapparitions: Array = []   ## files d'attente {nom, pos, temps}
var secrets: Array = []         ## {pos: Vector2, trouve: bool}
var secrets_trouves := 0
var cellules_valides := {}      ## cellules situées dans le disque du monde
var cellules_visitees := {}
var couche_orbes: Node2D


## Construit le monde entier. Appelé par main.gd une fois les références câblées.
func demarrer() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = GRAINE
	_generer_decor(rng)
	_placer_secrets(rng)
	_compter_cellules()
	_peupler(rng)
	couche_orbes = CoucheOrbes.new()
	couche_orbes.monde = self
	add_child(couche_orbes)
	queue_redraw()


func _process(delta: float) -> void:
	if joueur == null:
		return
	_marquer_exploration()
	_verifier_secrets()
	_gerer_reapparitions(delta)


# ---------------------------------------------------------------- zones

## Zone (1 à 4) correspondant à une position du monde.
func zone_de(pos: Vector2) -> int:
	var d := pos.length()
	for i in RAYONS_ZONES.size():
		if d <= RAYONS_ZONES[i]:
			return i + 1
	return 4


# ---------------------------------------------------------------- ennemis

func ennemi_le_plus_proche(pos: Vector2, portee: float) -> Ennemi:
	var meilleur: Ennemi = null
	var meilleure_dist := portee
	for e in ennemis:
		if not is_instance_valid(e) or e.pv <= 0.0:
			continue
		var d := pos.distance_to(e.position)
		if d <= meilleure_dist:
			meilleure_dist = d
			meilleur = e
	return meilleur


func ennemis_dans_rayon(pos: Vector2, rayon: float) -> Array:
	var trouves: Array = []
	for e in ennemis:
		if is_instance_valid(e) and e.pv > 0.0 and pos.distance_to(e.position) <= rayon:
			trouves.append(e)
	return trouves


func _peupler(rng: RandomNumberGenerator) -> void:
	# Répartition par zone (types et niveaux croissants vers l'extérieur).
	# Rayon minimal 320 px : le sanctuaire central (aggro 260 px) reste sûr.
	_semer(rng, "sanglier", 12, 320.0, 600.0)
	_semer(rng, "loup", 9, 700.0, 1260.0)
	_semer(rng, "araignee", 8, 700.0, 1260.0)
	_semer(rng, "zombie", 9, 1340.0, 1900.0)
	_semer(rng, "scorpion", 8, 1340.0, 1900.0)
	_semer(rng, "ogre", 8, 2000.0, 2480.0)
	# Le dragon garde un coin des Terres Brûlées.
	var b := BossDragon.new()
	b.monde = self
	b.configurer("dragon", Vector2.from_angle(rng.randf_range(0.0, TAU)) * 2250.0)
	add_child(b)
	ennemis.append(b)
	boss = b


func _semer(rng: RandomNumberGenerator, nom: String, nombre: int, r_min: float, r_max: float) -> void:
	for i in nombre:
		var pos := Vector2.from_angle(rng.randf_range(0.0, TAU)) * rng.randf_range(r_min, r_max)
		_creer_ennemi(nom, pos)


func _creer_ennemi(nom: String, pos: Vector2) -> void:
	var e := Ennemi.new()
	e.monde = self
	e.configurer(nom, pos)
	add_child(e)
	ennemis.append(e)


## Un ennemi vient de mourir : expérience, butin éventuel, réapparition différée.
func sur_mort_ennemi(e: Ennemi) -> void:
	ennemis.erase(e)
	joueur.gagner_xp(e.xp_donnee)
	fx.eclat_etoiles(e.position, e.visuel.couleur, 12)
	fx.texte_flottant(e.position, "+%d xp" % int(e.xp_donnee), Color(0.7, 1.0, 0.7))
	Audio.jouer("mort_ennemi")
	if randf() < CHANCE_LOOT:
		_lacher_objet(e.position, zone_de(e.position), 0)
	reapparitions.append({"nom": e.type_nom, "pos": e.origine, "temps": DELAI_REAPPARITION})


## Le boss est vaincu : triple butin Légendaire/Mythique, pas de réapparition.
func sur_mort_boss(b: BossDragon) -> void:
	ennemis.erase(b)
	boss = null
	joueur.gagner_xp(b.xp_donnee)
	fx.eclat_etoiles(b.position, Color(1.0, 0.6, 0.2), 30)
	fx.secousse(1.0)
	Audio.jouer("victoire")
	hud.message("Le dragon est vaincu ! Les Terres d'Émeraude respirent…", 5.0)
	for i in 3:
		var rarete_min := 4 if randf() < 0.35 else 3 # Légendaire, parfois Mythique
		_lacher_objet(b.position + Vector2.from_angle(TAU * i / 3.0) * 40.0, 4, rarete_min)


func _gerer_reapparitions(delta: float) -> void:
	for i in range(reapparitions.size() - 1, -1, -1):
		reapparitions[i].temps -= delta
		if reapparitions[i].temps <= 0.0:
			_creer_ennemi(reapparitions[i].nom, reapparitions[i].pos)
			reapparitions.remove_at(i)


# ---------------------------------------------------------------- projectiles et butin

func creer_projectile(pos: Vector2, velocite: Vector2, degats: float, teinte: Color) -> void:
	var p := Projectile.new()
	p.monde = self
	p.position = pos
	p.velocite = velocite
	p.degats = degats
	p.teinte = teinte
	add_child(p)


func _lacher_objet(pos: Vector2, zone: int, rarete_min: int) -> void:
	var o := ObjetLoot.new()
	o.monde = self
	o.objet = ObjetLoot.generer(zone, rarete_min)
	o.position = pos + Vector2(randf_range(-24.0, 24.0), randf_range(-24.0, 24.0))
	add_child(o)


# ---------------------------------------------------------------- secrets

func _placer_secrets(rng: RandomNumberGenerator) -> void:
	# Trois orbes de lumière par zone, cachés n'importe où dans l'anneau.
	for zone in 4:
		var r_min: float = 120.0 if zone == 0 else RAYONS_ZONES[zone - 1] + 80.0
		var r_max: float = RAYONS_ZONES[zone] - 80.0
		for i in 3:
			secrets.append({
				"pos": Vector2.from_angle(rng.randf_range(0.0, TAU)) * rng.randf_range(r_min, r_max),
				"trouve": false,
			})


func _verifier_secrets() -> void:
	for s in secrets:
		if not s.trouve and joueur.position.distance_to(s.pos) < 46.0:
			s.trouve = true
			secrets_trouves += 1
			joueur.bonus_secret()
			fx.eclat_etoiles(s.pos, Color(1.0, 0.95, 0.5), 18)
			fx.texte_flottant(s.pos, "Orbe de lumière ! (%d/%d)" % [secrets_trouves, NB_SECRETS], Color(1.0, 0.95, 0.5))
			fx.secousse(0.2)
			Audio.jouer("orbe")


# ---------------------------------------------------------------- exploration

func _compter_cellules() -> void:
	# Cellules dont le centre est dans le disque du monde : base du % d'exploration.
	var n := int(ceil(RAYON_MONDE / TAILLE_CELLULE))
	for cx in range(-n, n + 1):
		for cy in range(-n, n + 1):
			var centre := Vector2((cx + 0.5) * TAILLE_CELLULE, (cy + 0.5) * TAILLE_CELLULE)
			if centre.length() <= RAYON_MONDE:
				cellules_valides[Vector2i(cx, cy)] = true


func _marquer_exploration() -> void:
	var cellule := Vector2i(int(floor(joueur.position.x / TAILLE_CELLULE)), int(floor(joueur.position.y / TAILLE_CELLULE)))
	if cellules_valides.has(cellule):
		cellules_visitees[cellule] = true


func exploration_pourcent() -> float:
	if cellules_valides.is_empty():
		return 0.0
	return cellules_visitees.size() * 100.0 / cellules_valides.size()


# ---------------------------------------------------------------- décor

func _generer_decor(rng: RandomNumberGenerator) -> void:
	# Le décor est découpé en tuiles (nœuds ChunkDecor) pour que Godot ignore
	# automatiquement les tuiles hors écran (culling par canvas item).
	var chunks := {}
	var cote := 650.0
	for i in 420:
		var pos := Vector2.from_angle(rng.randf_range(0.0, TAU)) * rng.randf_range(130.0, RAYON_MONDE - 40.0)
		var zone := zone_de(pos)
		var genre := _genre_decor(rng, zone)
		var item := {
			"genre": genre,
			"pos": pos,
			"taille": rng.randf_range(0.8, 1.35),
			"variation": rng.randf(),
		}
		var cle := Vector2i(int(floor(pos.x / cote)), int(floor(pos.y / cote)))
		if not chunks.has(cle):
			chunks[cle] = []
		chunks[cle].append(item)
	for cle in chunks:
		var chunk := ChunkDecor.new()
		chunk.items = chunks[cle]
		add_child(chunk)


func _genre_decor(rng: RandomNumberGenerator, zone: int) -> String:
	var tirage := rng.randf()
	match zone:
		1:
			if tirage < 0.35: return "buisson"
			if tirage < 0.6: return "arbre"
			if tirage < 0.8: return "fleur"
			return "rocher"
		2:
			if tirage < 0.65: return "arbre"
			if tirage < 0.85: return "buisson"
			return "rocher"
		3:
			if tirage < 0.4: return "roseau"
			if tirage < 0.7: return "arbre_mort"
			return "rocher"
		_:
			if tirage < 0.5: return "rocher"
			if tirage < 0.85: return "arbre_mort"
			return "buisson"


func _draw() -> void:
	# Anneau extérieur sombre (bord du monde), puis les zones de l'extérieur
	# vers l'intérieur pour former les anneaux concentriques.
	draw_circle(Vector2.ZERO, RAYON_MONDE + 130.0, Color(0.13, 0.10, 0.16))
	for i in range(3, -1, -1):
		draw_circle(Vector2.ZERO, RAYONS_ZONES[i], COULEURS_SOL[i])
		draw_arc(Vector2.ZERO, RAYONS_ZONES[i], 0.0, TAU, 128, Color(0.13, 0.10, 0.16, 0.35), 6.0)
	# Le sanctuaire central : dalle claire et pierres dressées.
	draw_circle(Vector2.ZERO, 96.0, Color(0.13, 0.10, 0.16, 0.4))
	draw_circle(Vector2.ZERO, 90.0, Color(0.92, 0.88, 0.75))
	for i in 8:
		var p := Vector2.from_angle(TAU * i / 8.0) * 74.0
		draw_circle(p, 9.0, Color(0.13, 0.10, 0.16))
		draw_circle(p, 7.0, Color(0.65, 0.62, 0.58))


## Tuile de décor : dessinée une seule fois puis mise en cache par le moteur.
class ChunkDecor extends Node2D:
	const CONTOUR := Color(0.13, 0.10, 0.16)
	var items: Array = []

	func _draw() -> void:
		for d in items:
			var pos: Vector2 = d.pos
			var t: float = d.taille
			match d.genre:
				"arbre":
					var feuillage := Color(0.24, 0.55, 0.30).lerp(Color(0.38, 0.72, 0.33), d.variation)
					draw_line(pos, pos + Vector2(0.0, -26.0 * t), Color(0.42, 0.28, 0.18), 8.0 * t)
					draw_circle(pos + Vector2(0.0, -34.0 * t), 22.0 * t + 3.0, CONTOUR)
					draw_circle(pos + Vector2(0.0, -34.0 * t), 22.0 * t, feuillage)
					draw_circle(pos + Vector2(-8.0 * t, -42.0 * t), 12.0 * t, feuillage.lightened(0.15))
				"arbre_mort":
					draw_line(pos, pos + Vector2(0.0, -30.0 * t), CONTOUR, 7.0 * t)
					draw_line(pos + Vector2(0.0, -16.0 * t), pos + Vector2(11.0 * t, -26.0 * t), CONTOUR, 5.0 * t)
					draw_line(pos + Vector2(0.0, -22.0 * t), pos + Vector2(-9.0 * t, -30.0 * t), CONTOUR, 4.0 * t)
				"rocher":
					var gris := Color(0.55, 0.55, 0.6).lerp(Color(0.68, 0.62, 0.55), d.variation)
					draw_circle(pos, 14.0 * t + 3.0, CONTOUR)
					draw_circle(pos, 14.0 * t, gris)
					draw_circle(pos + Vector2(-4.0 * t, -4.0 * t), 6.0 * t, gris.lightened(0.2))
				"buisson":
					var vert := Color(0.30, 0.62, 0.28).lerp(Color(0.45, 0.75, 0.35), d.variation)
					draw_circle(pos, 12.0 * t + 3.0, CONTOUR)
					draw_circle(pos, 12.0 * t, vert)
					draw_circle(pos + Vector2(9.0 * t, 2.0), 8.0 * t, vert.darkened(0.1))
				"fleur":
					draw_line(pos, pos + Vector2(0.0, -8.0 * t), Color(0.30, 0.55, 0.25), 2.5)
					for i in 5:
						draw_circle(pos + Vector2(0.0, -11.0 * t) + Vector2.from_angle(TAU * i / 5.0) * 4.0 * t,
							3.0 * t, Color(1.0, 0.6, 0.75) if d.variation < 0.5 else Color(1.0, 0.85, 0.4))
					draw_circle(pos + Vector2(0.0, -11.0 * t), 2.5 * t, Color(1.0, 0.95, 0.6))
				"roseau":
					for i in 3:
						var px := pos + Vector2((i - 1) * 5.0 * t, 0.0)
						draw_line(px, px + Vector2((i - 1) * 2.0, -18.0 * t), Color(0.45, 0.60, 0.30), 3.0)
						draw_circle(px + Vector2((i - 1) * 2.0, -18.0 * t), 3.5 * t, Color(0.55, 0.42, 0.28))


## Couche animée des orbes de lumière restants (pulsation douce).
class CoucheOrbes extends Node2D:
	var monde = null
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		if monde == null:
			return
		for s in monde.secrets:
			if s.trouve:
				continue
			var pulsation: float = 0.75 + sin(_t * 3.0 + s.pos.x * 0.01) * 0.25
			var pos: Vector2 = s.pos
			draw_circle(pos, 26.0 * pulsation, Color(1.0, 0.95, 0.5, 0.16))
			draw_circle(pos, 14.0 * pulsation, Color(1.0, 0.95, 0.55, 0.35))
			draw_circle(pos, 7.0, Color(1.0, 0.98, 0.85))
			# Petit scintillement en croix.
			for i in 4:
				var dir := Vector2.from_angle(TAU * i / 4.0 + _t * 1.5)
				draw_line(pos + dir * 10.0, pos + dir * (16.0 + 4.0 * pulsation), Color(1.0, 0.98, 0.85, 0.7), 2.0)

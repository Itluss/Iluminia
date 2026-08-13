class_name Arene
extends Node3D
## L'arène 3D « Chasse au dragon » — le cœur d'Iluminia.
##
## Boucle V5 (spec Camille 2026-08-11) : la question se traite AVANT
## l'action, jamais pendant. QUESTION (6 s, tout le monde figé, chacun
## choisit) → JEU (45 s : dragon fuyard, vol entre chasseurs, dépôt dans la
## zone de SA réponse) → INTERLUDE → … → PODIUM à la fin du match.
## Mauvaise zone : refus, dragon lâché, fautif gelé 2 s, réponse barrée
## POUR LUI seulement — la partie ne s'arrête jamais pour les autres.
##
## Construit aussi le monde 3D : sol bonbon, fleurs, couronne d'arbres,
## colonnes de lumière des zones, chevrons-boussole, cristaux.
## v2 multijoueur : ce nœud est l'autorité (voir reseau.gd).

enum Etat { QUESTION, JEU, INTERLUDE, PODIUM }

const RAYON_ARENE := 18.0
const COMPTE_QUESTION := 6.0    ## questionCountdown
const DUREE_MANCHE := 45.0      ## mancheDuration
const GEL_MAUVAISE := 2.0       ## wrongFreezeSeconds
const DUREE_MATCH := 180.0      ## chrono global du match → podium
const DUREE_INTERLUDE := 3.0
const RAYON_ZONE := 2.3
const DISTANCE_ZONES := 12.5
const CRISTAL_PERIODE := 8.0
const CRISTAL_MAX := 3
const CRISTAL_ENERGIE := 20.0
const LETTRES := ["A", "B", "C", "D"]
const COULEURS_ZONES := [
	Color(1.0, 0.42, 0.5),   # A — rose
	Color(0.35, 0.62, 1.0),  # B — bleu
	Color(1.0, 0.78, 0.25),  # C — or
	Color(0.4, 0.85, 0.45),  # D — vert
]

var fx: FX
var hud: HUD
var joueur: Chasseur
var chasseurs: Array = []
var dragon: Dragon = null
var zones: Array = []           ## {pos, teinte, lettre, colonne, mat, label, croix}
var cristaux: Array = []
var question := {"enonce": "", "reponses": ["", "", "", ""], "bonne": 0}
var etat := Etat.QUESTION
var temps_etat := COMPTE_QUESTION
var temps_match := DUREE_MATCH
var cristal_temps := CRISTAL_PERIODE
var message_interlude := ""
var _chevrons: Array = []       ## flèches-boussole vers la zone choisie
var _label_distance: Label3D
var _t := 0.0


## Construit l'arène entière. Appelé par le jeu une fois les références câblées.
func demarrer() -> void:
	_construire_sol()
	_construire_zones()
	_construire_chevrons()
	_nouvelle_manche()


func _process(delta: float) -> void:
	_t += delta
	_animer_zones()
	_animer_chevrons()
	match etat:
		Etat.QUESTION:
			temps_etat -= delta
			if temps_etat <= 0.0:
				_lancer_jeu()
		Etat.JEU:
			temps_etat -= delta
			temps_match -= delta
			_gerer_cristaux(delta)
			_verifier_zones()
			if temps_etat <= 0.0:
				_fin_manche_chrono()
		Etat.INTERLUDE:
			temps_etat -= delta
			if temps_etat <= 0.0:
				if temps_match <= 0.0:
					_podium()
				else:
					_nouvelle_manche()
		Etat.PODIUM:
			pass # redémarrage via hud → rejouer()


# ---------------------------------------------------------------- monde 3D

func _construire_sol() -> void:
	# Prairie extérieure sombre, arène claire, lisière peinte.
	Materiaux.mesh(self, Materiaux.cylindre(RAYON_ARENE + 14.0, 0.3),
		Materiaux.toon(Color(0.30, 0.52, 0.30)), Vector3(0.0, -0.32, 0.0), Vector3.ONE, false)
	Materiaux.mesh(self, Materiaux.cylindre(RAYON_ARENE + 0.5, 0.3),
		Materiaux.toon(Color(0.20, 0.16, 0.26)), Vector3(0.0, -0.25, 0.0), Vector3.ONE, false)
	Materiaux.mesh(self, Materiaux.cylindre(RAYON_ARENE, 0.3),
		Materiaux.toon(Color(0.55, 0.83, 0.45)), Vector3(0.0, -0.15, 0.0), Vector3.ONE, false)
	# Anneaux de tonte légers + motif central.
	for i in range(1, 4):
		Materiaux.mesh(self, Materiaux.cylindre(RAYON_ARENE * i / 4.0, 0.02),
			Materiaux.toon(Color(0.50, 0.78, 0.42)), Vector3(0.0, -0.008 * i, 0.0), Vector3.ONE, false)
	Materiaux.mesh(self, Materiaux.cylindre(1.4, 0.06),
		Materiaux.toon(Color(0.66, 0.82, 0.52)), Vector3.ZERO, Vector3.ONE, false)

	var rng := RandomNumberGenerator.new()
	rng.seed = 20260813
	# Fleurs et touffes d'herbe dans l'arène.
	for i in 60:
		var p := Vector2.from_angle(rng.randf_range(0.0, TAU)) * rng.randf_range(2.0, RAYON_ARENE - 1.0)
		if rng.randf() < 0.5:
			var teinte := Color(1.0, 0.6, 0.75) if rng.randf() < 0.5 else Color(1.0, 0.85, 0.4)
			Materiaux.mesh(self, Materiaux.sphere(0.12), Materiaux.toon(teinte),
				Vector3(p.x, 0.12, p.y), Vector3.ONE, false)
		else:
			Materiaux.mesh(self, Materiaux.cone(0.14, 0.35), Materiaux.toon(Color(0.38, 0.68, 0.32)),
				Vector3(p.x, 0.15, p.y), Vector3.ONE, false)
	# Couronne d'arbres bonbon autour de l'arène.
	for i in 26:
		var ang := TAU * i / 26.0 + rng.randf_range(-0.06, 0.06)
		var r := RAYON_ARENE + rng.randf_range(2.5, 9.0)
		var p := Vector2.from_angle(ang) * r
		var taille := rng.randf_range(0.8, 1.5)
		var arbre := Node3D.new()
		arbre.position = Vector3(p.x, 0.0, p.y)
		add_child(arbre)
		Materiaux.mesh(arbre, Materiaux.cylindre(0.22 * taille, 1.2 * taille),
			Materiaux.toon(Color(0.45, 0.30, 0.20)), Vector3(0.0, 0.6 * taille, 0.0))
		var feuillage := Color(0.24, 0.55, 0.30).lerp(Color(0.40, 0.74, 0.34), rng.randf())
		Materiaux.mesh(arbre, Materiaux.sphere(0.9 * taille), Materiaux.toon(feuillage),
			Vector3(0.0, 1.6 * taille, 0.0), Vector3.ONE, true, 0.08)
		Materiaux.mesh(arbre, Materiaux.sphere(0.55 * taille), Materiaux.toon(feuillage.lightened(0.15)),
			Vector3(0.35 * taille, 2.0 * taille, 0.1), Vector3.ONE, false)


func _construire_zones() -> void:
	for i in 4:
		var pos := Vector2.from_angle(-PI / 4.0 - TAU * i / 4.0) * DISTANCE_ZONES
		var teinte: Color = COULEURS_ZONES[i]
		var noeud := Node3D.new()
		noeud.position = Vector3(pos.x, 0.0, pos.y)
		add_child(noeud)
		# Colonne de lumière : tube sans capuchons (sinon disques blancs à l'écran).
		var mat := Materiaux.verre(teinte, 0.16, 0.5)
		var tube := CylinderMesh.new()
		tube.top_radius = RAYON_ZONE
		tube.bottom_radius = RAYON_ZONE
		tube.height = 7.0
		tube.radial_segments = 24
		tube.cap_top = false
		tube.cap_bottom = false
		var colonne := Materiaux.mesh(noeud, tube, mat, Vector3(0.0, 3.5, 0.0), Vector3.ONE, false)
		# Anneau peint au sol (non émissif : le glow le transformait en halo blanc).
		Materiaux.mesh(noeud, Materiaux.tore(0.12, RAYON_ZONE),
			Materiaux.toon(teinte), Vector3(0.0, 0.06, 0.0), Vector3.ONE, false)
		# Lettre géante.
		var lettre := Label3D.new()
		lettre.text = LETTRES[i]
		lettre.font_size = 340
		lettre.outline_size = 60
		lettre.modulate = Color.WHITE
		lettre.outline_modulate = Materiaux.COULEUR_CONTOUR
		lettre.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lettre.position = Vector3(0.0, 2.2, 0.0)
		noeud.add_child(lettre)
		# Réponse courte au-dessus de la colonne.
		var reponse := Label3D.new()
		reponse.font_size = 120
		reponse.outline_size = 34
		reponse.modulate = teinte.lightened(0.35)
		reponse.outline_modulate = Materiaux.COULEUR_CONTOUR
		reponse.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		reponse.no_depth_test = true
		reponse.position = Vector3(0.0, 5.4, 0.0)
		noeud.add_child(reponse)
		# Croix rouge « refusée » (perspective du joueur), masquée par défaut.
		var croix := Node3D.new()
		croix.position = Vector3(0.0, 0.15, 0.0)
		noeud.add_child(croix)
		for angle: float in [0.785, -0.785]:
			var barre := BoxMesh.new()
			barre.size = Vector3(RAYON_ZONE * 1.7, 0.08, 0.35)
			var mi := Materiaux.mesh(croix, barre, Materiaux.emissif(Color(0.9, 0.2, 0.15), 1.6),
				Vector3.ZERO, Vector3.ONE, false)
			mi.rotation.y = angle
		croix.visible = false
		zones.append({"pos": pos, "teinte": teinte, "lettre": LETTRES[i],
			"colonne": colonne, "mat": mat, "label": reponse, "croix": croix})


func _animer_zones() -> void:
	var en_jeu := etat == Etat.JEU or etat == Etat.INTERLUDE
	for i in zones.size():
		var z: Dictionary = zones[i]
		var colonne: MeshInstance3D = z.colonne
		var pulse: float = 1.0 + sin(_t * 2.0 + i * 1.3) * 0.05
		colonne.scale = Vector3(pulse, 1.0, pulse)
		var label: Label3D = z.label
		label.visible = en_jeu
		if en_jeu:
			label.text = str(question.reponses[i])
		var refusee: bool = joueur != null and joueur.testees.has(i)
		var croix: Node3D = z.croix
		croix.visible = refusee
		var mat: StandardMaterial3D = z.mat
		var teinte: Color = Color(0.45, 0.45, 0.5) if refusee else z.teinte
		mat.albedo_color = Color(teinte.r, teinte.g, teinte.b, 0.22)
		mat.emission = teinte


func _construire_chevrons() -> void:
	for k in 6:
		var fleche := PrismMesh.new()
		fleche.size = Vector3(0.7, 0.5, 0.12)
		var mi := MeshInstance3D.new()
		mi.mesh = fleche
		mi.material_override = Materiaux.emissif(Color.WHITE, 1.6)
		mi.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
		mi.visible = false
		add_child(mi)
		_chevrons.append(mi)
	_label_distance = Label3D.new()
	_label_distance.font_size = 110
	_label_distance.outline_size = 30
	_label_distance.outline_modulate = Materiaux.COULEUR_CONTOUR
	_label_distance.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label_distance.no_depth_test = true
	_label_distance.visible = false
	add_child(_label_distance)


## Traînée de chevrons du joueur vers la zone de SON choix + distance.
func _animer_chevrons() -> void:
	var actif := etat == Etat.JEU and joueur != null and joueur.choix >= 0
	for c in _chevrons:
		c.visible = false
	_label_distance.visible = actif
	if not actif:
		return
	var cible: Vector2 = zones[joueur.choix].pos
	var teinte: Color = zones[joueur.choix].teinte
	var v := cible - joueur.pos2()
	var distance := v.length()
	if distance < RAYON_ZONE:
		_label_distance.visible = false
		return
	var dir := v.normalized()
	var defilement := fposmod(_t * 1.6, 1.2)
	var n := int(minf((distance - 1.6) / 1.2, 6.0))
	for k in n:
		var chevron: MeshInstance3D = _chevrons[k]
		var p := joueur.pos2() + dir * (1.4 + k * 1.2 + defilement)
		chevron.visible = true
		chevron.position = Vector3(p.x, 0.1, p.y)
		chevron.rotation.y = atan2(dir.x, dir.y)
		chevron.rotation.x = deg_to_rad(-90.0)
		var mat: StandardMaterial3D = chevron.material_override
		mat.albedo_color = teinte
		mat.emission = teinte
	var bout := joueur.pos2() + dir * minf(1.4 + n * 1.2 + defilement, distance - 1.0)
	_label_distance.position = Vector3(bout.x, 1.0, bout.y)
	_label_distance.modulate = teinte.lightened(0.25)
	_label_distance.text = "%d m" % int(distance)


# ---------------------------------------------------------------- manches

func _nouvelle_manche() -> void:
	etat = Etat.QUESTION
	temps_etat = COMPTE_QUESTION
	question = Questions.generer()
	if dragon != null:
		dragon.queue_free()
		dragon = null
	for c in chasseurs:
		c.choix = -1
		c.testees = []
		c.gel_restant = 0.0
	# Les bots réfléchissent pendant le décompte (précision 0,5).
	for c in chasseurs:
		if not c.est_joueur:
			c.bot_choisir()
	if hud != null:
		hud.sur_nouvelle_question()


func _lancer_jeu() -> void:
	etat = Etat.JEU
	temps_etat = DUREE_MANCHE
	_faire_apparaitre_dragon()
	Audio.jouer("depart")


func _faire_apparaitre_dragon() -> void:
	dragon = Dragon.new()
	dragon.arene = self
	# Le plus loin possible de tous les chasseurs (souvent hors écran :
	# suivre l'indicateur de bord d'écran avec la distance).
	var meilleure := Vector2.ZERO
	var meilleure_d := -1.0
	for essai in 24:
		var p := Vector2.from_angle(randf_range(0.0, TAU)) * randf_range(3.5, RAYON_ARENE - 3.0)
		var d_min := INF
		for c in chasseurs:
			d_min = minf(d_min, p.distance_to(c.pos2()))
		if d_min > meilleure_d:
			meilleure_d = d_min
			meilleure = p
	dragon.position = Vector3(meilleure.x, 0.0, meilleure.y)
	add_child(dragon)
	fx.eclat_etoiles(meilleure, Color(0.55, 0.9, 0.6), 14)


func _verifier_zones() -> void:
	if dragon == null or dragon.porteur == null:
		return
	var c := dragon.porteur
	for i in zones.size():
		var pos_zone: Vector2 = zones[i].pos
		if c.pos2().distance_to(pos_zone) < RAYON_ZONE:
			_tenter_zone(c, i)
			return


func _tenter_zone(c: Chasseur, i: int) -> void:
	if c.testees.has(i):
		return # zone déjà refusée POUR LUI : elle l'ignore
	var bonne: int = question.bonne
	var pos_zone: Vector2 = zones[i].pos
	if i == bonne:
		# +100, +15 d'énergie, fin de manche immédiate.
		c.score += 100
		c.energie = minf(c.energie + 15.0, Chasseur.ENERGIE_MAX)
		fx.eclat_etoiles(pos_zone, zones[i].teinte, 30)
		fx.anneau(pos_zone, RAYON_ZONE * 2.0, zones[i].teinte)
		fx.texte_flottant(pos_zone, "+100 !", Color(1.0, 0.95, 0.6))
		Audio.jouer("victoire")
		if c.est_joueur:
			fx.secousse(0.4)
		dragon.queue_free()
		dragon = null
		message_interlude = "%s dépose le dragon : +100 points !" % c.nom
		etat = Etat.INTERLUDE
		temps_etat = DUREE_INTERLUDE
	else:
		# Refus : réponse barrée pour lui, dragon lâché, fautif gelé.
		c.testees.append(i)
		c.choix = -1
		c.perdre_energie_reponse()
		lacher_dragon(c.pos2())
		c.geler(GEL_MAUVAISE)
		fx.texte_flottant(c.pos2(), "MAUVAISE RÉPONSE !", Color(1.0, 0.35, 0.3))
		fx.eclat_etoiles(pos_zone, Color(0.6, 0.6, 0.6), 12)
		Audio.jouer("mauvaise")
		if c.est_joueur:
			fx.secousse(0.5)
			if hud != null:
				hud.sur_mauvaise_reponse()


func _fin_manche_chrono() -> void:
	# Garder le dragon reste un objectif quand on doute de la réponse.
	if dragon != null and dragon.porteur != null:
		dragon.porteur.score += 100
		message_interlude = "%s garde le dragon au gong : +100 !" % dragon.porteur.nom
		Audio.jouer("victoire")
	else:
		message_interlude = "Temps écoulé — le dragon s'échappe, personne ne marque."
	if dragon != null:
		dragon.queue_free()
		dragon = null
	etat = Etat.INTERLUDE
	temps_etat = DUREE_INTERLUDE


func _podium() -> void:
	etat = Etat.PODIUM
	Audio.jouer("podium")
	if hud != null:
		hud.sur_podium()


## Nouveau match complet (depuis le podium).
func rejouer() -> void:
	temps_match = DUREE_MATCH
	for c in chasseurs:
		c.score = 0
		c.energie = Chasseur.ENERGIE_MAX
		c.ko_restant = 0.0
		c.visible = true
	for cr in cristaux:
		cr.queue_free()
	cristaux = []
	_nouvelle_manche()


# ---------------------------------------------------------------- dragon

func prendre_dragon(c: Chasseur, mode: String) -> void:
	if dragon == null:
		return
	var ancien := dragon.porteur
	dragon.porteur = c
	c.immunite = Chasseur.IMMUNITE_VOL
	fx.eclat_etoiles(dragon.pos2(), Color(1.0, 0.85, 0.4), 10)
	if mode == "vol":
		Audio.jouer("vol")
		fx.texte_flottant(c.pos2(), "Dragon volé !", Color(1.0, 0.8, 0.3))
	else:
		Audio.jouer("ramasser")
	# Toast pédagogique quand un adversaire prend le dragon.
	if not c.est_joueur and hud != null and (ancien == null or ancien.est_joueur):
		hud.toast_pedagogique()


func lacher_dragon(pos: Vector2) -> void:
	if dragon == null:
		return
	dragon.porteur = null
	dragon.fixer_pos2(borner(pos + Vector2(randf_range(-0.4, 0.4), randf_range(-0.4, 0.4))))


# ---------------------------------------------------------------- cristaux

func _gerer_cristaux(delta: float) -> void:
	cristal_temps -= delta
	if cristal_temps <= 0.0:
		cristal_temps = CRISTAL_PERIODE
		if cristaux.size() < CRISTAL_MAX:
			var cr := Cristal3D.new()
			var p := Vector2.from_angle(randf_range(0.0, TAU)) * randf_range(2.5, RAYON_ARENE - 3.5)
			cr.position = Vector3(p.x, 0.0, p.y)
			add_child(cr)
			cristaux.append(cr)


func ramasser_cristaux(c: Chasseur) -> void:
	for cr in cristaux:
		if is_instance_valid(cr) and c.pos2().distance_to(cr.pos2()) < 0.8:
			cristaux.erase(cr)
			c.energie = minf(c.energie + CRISTAL_ENERGIE, Chasseur.ENERGIE_MAX)
			fx.eclat_etoiles(cr.pos2(), Color(0.5, 0.95, 1.0), 10)
			fx.texte_flottant(cr.pos2(), "+20", Color(0.5, 0.95, 1.0))
			Audio.jouer("cristal")
			cr.queue_free()
			return


func cristal_le_plus_proche(pos: Vector2) -> Cristal3D:
	var meilleur: Cristal3D = null
	var meilleure_d := INF
	for cr in cristaux:
		if is_instance_valid(cr):
			var d := pos.distance_to(cr.pos2())
			if d < meilleure_d:
				meilleure_d = d
				meilleur = cr
	return meilleur


# ---------------------------------------------------------------- aides

func borner(pos: Vector2) -> Vector2:
	if pos.length() > RAYON_ARENE - 0.7:
		return pos.normalized() * (RAYON_ARENE - 0.7)
	return pos


func chasseur_le_plus_proche(pos: Vector2) -> Chasseur:
	var meilleur: Chasseur = null
	var meilleure_d := INF
	for c in chasseurs:
		if c.ko_restant > 0.0:
			continue
		var d: float = pos.distance_to(c.pos2())
		if d < meilleure_d:
			meilleure_d = d
			meilleur = c
	return meilleur


func menace_proche(c: Chasseur, rayon: float) -> bool:
	for autre in chasseurs:
		if autre != c and autre.ko_restant <= 0.0 and c.pos2().distance_to(autre.pos2()) < rayon:
			return true
	return false


## Meilleure cible de l'onde (visée assistée) : le porteur du dragon en
## priorité, sinon le chasseur le plus proche, à portée uniquement.
func meilleure_cible_onde(lanceur: Chasseur) -> Chasseur:
	var porteur: Chasseur = dragon.porteur if dragon != null else null
	if porteur != null and porteur != lanceur and porteur.ko_restant <= 0.0 \
			and lanceur.pos2().distance_to(porteur.pos2()) <= Chasseur.PORTEE_ONDE + 0.35:
		return porteur
	var meilleur: Chasseur = null
	var meilleure_d: float = Chasseur.PORTEE_ONDE + 0.35
	for c in chasseurs:
		if c == lanceur or c.ko_restant > 0.0:
			continue
		var d: float = lanceur.pos2().distance_to(c.pos2())
		if d <= meilleure_d:
			meilleure_d = d
			meilleur = c
	return meilleur


## Réapparition K.O. : aléatoire parmi les points les plus éloignés du dragon.
func point_reapparition() -> Vector2:
	var points: Array = []
	for i in 4:
		points.append(Vector2.from_angle(TAU * i / 4.0) * 15.0)
	if dragon == null:
		return points[randi() % 4]
	points.sort_custom(func(a, b): return a.distance_to(dragon.pos2()) > b.distance_to(dragon.pos2()))
	return points[randi() % 2] # un des deux plus éloignés


## Cristal d'énergie : gemme émissive qui tourne et flotte.
class Cristal3D extends Node3D:
	var _t := 0.0

	func _ready() -> void:
		var mat := Materiaux.emissif(Color(0.55, 0.9, 1.0), 2.2)
		Materiaux.mesh(self, Materiaux.cone(0.32, 0.5), mat, Vector3(0.0, 0.85, 0.0))
		var bas := Materiaux.mesh(self, Materiaux.cone(0.32, 0.5), mat, Vector3(0.0, 0.35, 0.0))
		bas.rotation_degrees = Vector3(180.0, 0.0, 0.0)

	func pos2() -> Vector2:
		return Vector2(position.x, position.z)

	func _process(delta: float) -> void:
		_t += delta
		rotation.y += delta * 2.0
		position.y = sin(_t * 3.0) * 0.12

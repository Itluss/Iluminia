class_name Arene
extends Node2D
## L'arène « Chasse au dragon » — le cœur d'Iluminia.
##
## Boucle V5 (spec Camille 2026-08-11) : la question se traite AVANT
## l'action, jamais pendant. Machine d'états de la manche :
##   QUESTION (6 s, tout le monde figé, chacun choisit sa réponse)
##   → JEU (45 s : le dragon apparaît ; l'attraper, se le voler, le
##     déposer dans la zone de SA réponse)
##   → INTERLUDE (résultat) → nouvelle manche, jusqu'au PODIUM.
##
## Fins de manche : bonne zone déposée → +100, fin immédiate. Chrono à 0 →
## le porteur actuel gagne (+100). Dragon au sol à 0 : personne ne marque.
## Mauvaise zone : refus, dragon lâché sur place, fautif gelé 2 s, réponse
## barrée POUR LUI seulement — la partie ne s'arrête jamais pour les autres.
##
## v2 multijoueur : ce nœud est l'autorité (voir reseau.gd).

enum Etat { QUESTION, JEU, INTERLUDE, PODIUM }

const RAYON_ARENE := 1080.0
const COMPTE_QUESTION := 6.0   ## questionCountdown
const DUREE_MANCHE := 45.0     ## mancheDuration
const GEL_MAUVAISE := 2.0      ## wrongFreezeSeconds
const DUREE_MATCH := 180.0     ## chrono global du match → podium
const DUREE_INTERLUDE := 3.0
const RAYON_ZONE := 130.0
const DISTANCE_ZONES := 760.0
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
var zones: Array = []          ## {pos, teinte, lettre}
var cristaux: Array = []
var question := {"enonce": "", "reponses": ["", "", "", ""], "bonne": 0}
var etat := Etat.QUESTION
var temps_etat := COMPTE_QUESTION
var temps_match := DUREE_MATCH
var cristal_temps := CRISTAL_PERIODE
var message_interlude := ""
var couche_zones: CoucheZones


## Construit l'arène. Appelé par main.gd une fois les références câblées.
func demarrer() -> void:
	for i in 4:
		zones.append({
			"pos": Vector2.from_angle(-PI / 4.0 - TAU * i / 4.0) * DISTANCE_ZONES,
			"teinte": COULEURS_ZONES[i],
			"lettre": LETTRES[i],
		})
	couche_zones = CoucheZones.new()
	couche_zones.arene = self
	add_child(couche_zones)
	queue_redraw()
	_nouvelle_manche()


func _process(delta: float) -> void:
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
		var p := Vector2.from_angle(randf_range(0.0, TAU)) * randf_range(200.0, RAYON_ARENE - 180.0)
		var d_min := INF
		for c in chasseurs:
			d_min = minf(d_min, p.distance_to(c.position))
		if d_min > meilleure_d:
			meilleure_d = d_min
			meilleure = p
	dragon.position = meilleure
	add_child(dragon)


func _verifier_zones() -> void:
	if dragon == null or dragon.porteur == null:
		return
	var c := dragon.porteur
	for i in zones.size():
		var pos_zone: Vector2 = zones[i].pos
		if c.position.distance_to(pos_zone) < RAYON_ZONE:
			_tenter_zone(c, i)
			return


func _tenter_zone(c: Chasseur, i: int) -> void:
	if c.testees.has(i):
		return # zone déjà refusée POUR LUI : elle l'ignore
	var bonne: int = question.bonne
	if i == bonne:
		# +100, +15 d'énergie, fin de manche immédiate.
		c.score += 100
		c.energie = minf(c.energie + 15.0, Chasseur.ENERGIE_MAX)
		fx.eclat_etoiles(zones[i].pos, zones[i].teinte, 26)
		fx.texte_flottant(zones[i].pos + Vector2(0.0, -60.0), "BONNE RÉPONSE ! +100", Color(1.0, 0.95, 0.6))
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
		lacher_dragon(c.position)
		c.geler(GEL_MAUVAISE)
		fx.texte_flottant(c.position + Vector2(0.0, -48.0), "MAUVAISE RÉPONSE !", Color(1.0, 0.35, 0.3))
		fx.eclat_etoiles(zones[i].pos, Color(0.6, 0.6, 0.6), 10)
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
	fx.eclat_etoiles(dragon.position, Color(1.0, 0.85, 0.4), 10)
	if mode == "vol":
		Audio.jouer("vol")
		fx.texte_flottant(c.position + Vector2(0.0, -44.0), "Dragon volé !", Color(1.0, 0.8, 0.3))
	else:
		Audio.jouer("ramasser")
	# Toast pédagogique quand un adversaire prend le dragon.
	if not c.est_joueur and hud != null and (ancien == null or ancien.est_joueur):
		hud.toast_pedagogique()


func lacher_dragon(pos: Vector2) -> void:
	if dragon == null:
		return
	dragon.porteur = null
	dragon.position = borner(pos + Vector2(randf_range(-24.0, 24.0), randf_range(-24.0, 24.0)))


# ---------------------------------------------------------------- cristaux

func _gerer_cristaux(delta: float) -> void:
	cristal_temps -= delta
	if cristal_temps <= 0.0:
		cristal_temps = CRISTAL_PERIODE
		if cristaux.size() < CRISTAL_MAX:
			var cr := Cristal.new()
			cr.position = Vector2.from_angle(randf_range(0.0, TAU)) * randf_range(150.0, RAYON_ARENE - 200.0)
			add_child(cr)
			cristaux.append(cr)


func ramasser_cristaux(c: Chasseur) -> void:
	for cr in cristaux:
		if is_instance_valid(cr) and c.position.distance_to(cr.position) < 42.0:
			cristaux.erase(cr)
			c.energie = minf(c.energie + CRISTAL_ENERGIE, Chasseur.ENERGIE_MAX)
			fx.eclat_etoiles(cr.position, Color(0.5, 0.95, 1.0), 10)
			fx.texte_flottant(cr.position + Vector2(0.0, -26.0), "+20", Color(0.5, 0.95, 1.0))
			Audio.jouer("cristal")
			cr.queue_free()
			return


func cristal_le_plus_proche(pos: Vector2) -> Node2D:
	var meilleur: Node2D = null
	var meilleure_d := INF
	for cr in cristaux:
		if is_instance_valid(cr):
			var d := pos.distance_to(cr.position)
			if d < meilleure_d:
				meilleure_d = d
				meilleur = cr
	return meilleur


# ---------------------------------------------------------------- aides

func borner(pos: Vector2) -> Vector2:
	if pos.length() > RAYON_ARENE - 40.0:
		return pos.normalized() * (RAYON_ARENE - 40.0)
	return pos


func chasseur_le_plus_proche(pos: Vector2) -> Chasseur:
	var meilleur: Chasseur = null
	var meilleure_d := INF
	for c in chasseurs:
		if c.ko_restant > 0.0:
			continue
		var d: float = pos.distance_to(c.position)
		if d < meilleure_d:
			meilleure_d = d
			meilleur = c
	return meilleur


func menace_proche(c: Chasseur, rayon: float) -> bool:
	for autre in chasseurs:
		if autre != c and autre.ko_restant <= 0.0 and c.position.distance_to(autre.position) < rayon:
			return true
	return false


## Meilleure cible de l'onde (visée assistée) : le porteur du dragon en
## priorité, sinon le chasseur le plus proche, à portée uniquement.
func meilleure_cible_onde(lanceur: Chasseur) -> Chasseur:
	var porteur: Chasseur = dragon.porteur if dragon != null else null
	if porteur != null and porteur != lanceur and porteur.ko_restant <= 0.0 \
			and lanceur.position.distance_to(porteur.position) <= Chasseur.PORTEE_ONDE + 20.0:
		return porteur
	var meilleur: Chasseur = null
	var meilleure_d := Chasseur.PORTEE_ONDE + 20.0
	for c in chasseurs:
		if c == lanceur or c.ko_restant > 0.0:
			continue
		var d: float = lanceur.position.distance_to(c.position)
		if d <= meilleure_d:
			meilleure_d = d
			meilleur = c
	return meilleur


## Réapparition K.O. : aléatoire parmi les 4 points les plus éloignés du dragon.
func point_reapparition() -> Vector2:
	var points: Array = []
	for i in 4:
		points.append(Vector2.from_angle(TAU * i / 4.0) * 900.0)
	if dragon == null:
		return points[randi() % 4]
	points.sort_custom(func(a, b): return a.distance_to(dragon.position) > b.distance_to(dragon.position))
	return points[randi() % 2] # un des deux plus éloignés


# ---------------------------------------------------------------- dessin

func _draw() -> void:
	# Fond nuit autour, herbe bonbon dans l'arène, lisière marquée.
	draw_circle(Vector2.ZERO, RAYON_ARENE + 220.0, Color(0.14, 0.11, 0.20))
	draw_circle(Vector2.ZERO, RAYON_ARENE + 14.0, Color(0.10, 0.08, 0.14))
	draw_circle(Vector2.ZERO, RAYON_ARENE, Color(0.55, 0.83, 0.45))
	# Anneaux de tonte concentriques, très légers.
	for i in range(1, 5):
		draw_arc(Vector2.ZERO, RAYON_ARENE * i / 5.0, 0.0, TAU, 96, Color(0.0, 0.35, 0.1, 0.06), 26.0)
	# Motif central.
	draw_circle(Vector2.ZERO, 60.0, Color(0.48, 0.76, 0.40))
	draw_arc(Vector2.ZERO, 60.0, 0.0, TAU, 48, Color(0.10, 0.08, 0.14, 0.25), 4.0)
	# Décor léger déterministe : fleurs et touffes d'herbe.
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260813
	for i in 70:
		var p := Vector2.from_angle(rng.randf_range(0.0, TAU)) * rng.randf_range(90.0, RAYON_ARENE - 60.0)
		if rng.randf() < 0.45:
			for j in 5:
				draw_circle(p + Vector2.from_angle(TAU * j / 5.0) * 4.0, 2.6,
					Color(1.0, 0.6, 0.75) if rng.randf() < 0.5 else Color(1.0, 0.85, 0.4))
			draw_circle(p, 2.2, Color(1.0, 0.95, 0.6))
		else:
			for j in 3:
				var px := p + Vector2((j - 1) * 4.0, 0.0)
				draw_line(px, px + Vector2((j - 1) * 2.0, -7.0), Color(0.38, 0.66, 0.30), 2.0)


## Couche animée : zones de réponse (colonnes de lumière), croix des refus
## du joueur, chevrons-boussole vers la zone choisie, cristaux scintillants.
class CoucheZones extends Node2D:
	var arene: Arene = null
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		if arene == null or arene.zones.is_empty():
			return
		var visibles := arene.etat == Arene.Etat.JEU or arene.etat == Arene.Etat.INTERLUDE
		var police := ThemeDB.fallback_font
		for i in arene.zones.size():
			var z: Dictionary = arene.zones[i]
			var teinte: Color = z.teinte
			var pos: Vector2 = z.pos
			var refusee: bool = arene.joueur != null and arene.joueur.testees.has(i)
			if refusee:
				teinte = Color(0.5, 0.5, 0.5)
			# Colonne de lumière : disque + anneaux pulsés.
			draw_circle(pos, Arene.RAYON_ZONE, Color(teinte.r, teinte.g, teinte.b, 0.30))
			draw_arc(pos, Arene.RAYON_ZONE, 0.0, TAU, 64, Color(0.10, 0.08, 0.14, 0.6), 5.0)
			var pulse := Arene.RAYON_ZONE * (0.55 + 0.35 * fposmod(_t * 0.7 + i * 0.25, 1.0))
			draw_arc(pos, pulse, 0.0, TAU, 48, Color(teinte.r, teinte.g, teinte.b, 0.5 * (1.0 - pulse / Arene.RAYON_ZONE)), 8.0)
			# Lettre de la zone.
			var lettre: String = z.lettre
			var largeur := police.get_string_size(lettre, HORIZONTAL_ALIGNMENT_LEFT, -1, 64).x
			draw_string_outline(police, pos + Vector2(-largeur / 2.0, 22.0), lettre,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 64, 10, Color(0.10, 0.08, 0.14))
			draw_string(police, pos + Vector2(-largeur / 2.0, 22.0), lettre,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 64, Color(1.0, 1.0, 1.0, 0.95))
			# Réponse en mode court dans la colonne (pendant le jeu).
			if visibles:
				var texte: String = str(arene.question.reponses[i])
				var lt := police.get_string_size(texte, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
				draw_string_outline(police, pos + Vector2(-lt / 2.0, -Arene.RAYON_ZONE - 14.0), texte,
					HORIZONTAL_ALIGNMENT_LEFT, -1, 22, 6, Color(0.10, 0.08, 0.14))
				draw_string(police, pos + Vector2(-lt / 2.0, -Arene.RAYON_ZONE - 14.0), texte,
					HORIZONTAL_ALIGNMENT_LEFT, -1, 22, teinte.lightened(0.3))
			# Croix sur les zones refusées par le joueur.
			if refusee:
				draw_line(pos + Vector2(-46.0, -46.0), pos + Vector2(46.0, 46.0), Color(0.9, 0.25, 0.2, 0.8), 10.0)
				draw_line(pos + Vector2(46.0, -46.0), pos + Vector2(-46.0, 46.0), Color(0.9, 0.25, 0.2, 0.8), 10.0)
		_dessiner_chevrons(police)

	## Traînée de chevrons-boussole du joueur vers la zone de SON choix,
	## avec un marqueur de distance au bout.
	func _dessiner_chevrons(police: Font) -> void:
		var j := arene.joueur
		if j == null or arene.etat != Arene.Etat.JEU or j.choix < 0:
			return
		var cible: Vector2 = arene.zones[j.choix].pos
		var teinte: Color = arene.zones[j.choix].teinte
		var v := cible - j.position
		var distance := v.length()
		if distance < Arene.RAYON_ZONE:
			return
		var dir := v.normalized()
		var perp := Vector2(-dir.y, dir.x)
		var defilement := fposmod(_t * 90.0, 70.0)
		var n := int(minf((distance - 100.0) / 70.0, 6.0))
		for k in n:
			var p := j.position + dir * (70.0 + k * 70.0 + defilement)
			var alpha := 0.85 - 0.1 * k
			draw_line(p - dir * 12.0 - perp * 10.0, p, Color(teinte.r, teinte.g, teinte.b, alpha), 6.0)
			draw_line(p - dir * 12.0 + perp * 10.0, p, Color(teinte.r, teinte.g, teinte.b, alpha), 6.0)
		# Marqueur de distance au bout de la traînée (« 23 m »).
		var texte := "%d m" % int(distance / 60.0)
		var p_texte := j.position + dir * minf(70.0 + n * 70.0 + defilement, distance - 60.0)
		var lt := police.get_string_size(texte, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
		draw_string_outline(police, p_texte + Vector2(-lt / 2.0, -14.0), texte,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 18, 6, Color(0.10, 0.08, 0.14))
		draw_string(police, p_texte + Vector2(-lt / 2.0, -14.0), texte,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 18, teinte.lightened(0.25))


## Cristal d'énergie : +20 à qui marche dessus, scintille en flottant.
class Cristal extends Node2D:
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var flottement := sin(_t * 3.0) * 4.0
		var p := Vector2(0.0, -10.0 - flottement)
		draw_circle(Vector2(0.0, 6.0), 10.0, Color(0.0, 0.0, 0.0, 0.18))
		draw_circle(p, 18.0 + sin(_t * 5.0) * 2.0, Color(0.5, 0.95, 1.0, 0.15))
		var pts := PackedVector2Array([
			p + Vector2(0.0, -16.0), p + Vector2(11.0, 0.0), p + Vector2(0.0, 16.0), p + Vector2(-11.0, 0.0),
		])
		draw_colored_polygon(PackedVector2Array([
			p + Vector2(0.0, -19.0), p + Vector2(14.0, 0.0), p + Vector2(0.0, 19.0), p + Vector2(-14.0, 0.0),
		]), Color(0.10, 0.08, 0.14))
		draw_colored_polygon(pts, Color(0.55, 0.9, 1.0))
		draw_line(p + Vector2(-4.0, -8.0), p + Vector2(4.0, 8.0), Color(1.0, 1.0, 1.0, 0.6), 3.0)

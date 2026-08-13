class_name Chasseur
extends Node2D
## Un chasseur de dragon : Max (le joueur) ou un bot (Zep, Nova, Ficelle).
## Énergie, trois pouvoirs à recharge pure (Onde de choc, Dash, Bouclier),
## vol du dragon, K.O. et réapparition. Toutes les valeurs viennent du
## spike Three.js (1 u = 60 px), cf. docs/mecaniques-arene.md.
##
## v2 multijoueur : ce nœud est instanciable N fois ; les bots deviendront
## des joueurs distants en remplaçant _ia_* par des entrées répliquées.

const VITESSE_JOUEUR := 264.0  ## 4,4 u/s
const VITESSE_BOT := 192.0     ## 3,2 u/s
const ENERGIE_MAX := 100.0

# Onde de choc : contrôle + vol du dragon, pas une exécution (10 ≪ 34).
const CD_ONDE := 4.0
const PORTEE_ONDE := 192.0     ## 3,2 u
const DEMI_CONE := 0.68        ## cône ~78°
const DEGATS_ONDE := 10.0
const RECUL_ONDE := 650.0      ## vitesse initiale de poussée (décroît vite)

const CD_DASH := 5.0
const DIST_DASH := 360.0       ## exactement 6 u, décomptée frame par frame
const VITESSE_DASH := 1560.0   ## 26 u/s

const CD_BOUCLIER := 7.0
const DUREE_BOUCLIER := 2.0

const IMMUNITE_VOL := 1.0      ## anti ping-pong après toute prise
const DUREE_KO := 3.0
const BOUCLIER_REAPPARITION := 1.5
const PENALITE_KO := 5

var arene: Arene
var hud: HUD                   ## renseigné uniquement pour le joueur
var est_joueur := false
var nom := "Max"
var teinte := Color(0.35, 0.78, 0.75)
var vitesse := VITESSE_BOT

var energie := ENERGIE_MAX
var score := 0
var choix := -1                ## réponse choisie (-1 : aucune)
var testees: Array = []        ## indices de réponses déjà refusées (individuel)

var derniere_dir := Vector2.RIGHT
var recul := Vector2.ZERO      ## vitesse de poussée subie
var cd_onde := 0.0
var cd_dash := 0.0
var cd_bouclier := 0.0
var dash_restant := 0.0
var dir_dash := Vector2.RIGHT
var bouclier_restant := 0.0
var bouclier_spawn := 0.0      ## bouclier de réapparition (1,5 s)
var immunite := 0.0
var gel_restant := 0.0
var ko_restant := 0.0

var visuel: VisuelCartoon


## À appeler AVANT l'ajout à l'arbre.
func configurer(p_nom: String, p_teinte: Color, p_est_joueur: bool, pos: Vector2) -> void:
	nom = p_nom
	teinte = p_teinte
	est_joueur = p_est_joueur
	vitesse = VITESSE_JOUEUR if est_joueur else VITESSE_BOT
	position = pos


func _ready() -> void:
	visuel = VisuelCartoon.new()
	visuel.genre = "chasseur"
	visuel.rayon = 16.0
	visuel.couleur = teinte
	visuel.etiquette = nom
	add_child(visuel)
	# Emplacement prévu pour un vrai sprite (voir assets/README.md).
	var sprite := Sprite2D.new()
	sprite.name = "Sprite2D"
	add_child(sprite)


func regard() -> Vector2:
	return derniere_dir


func porte_dragon() -> bool:
	return arene.dragon != null and arene.dragon.porteur == self


func protege() -> bool:
	return bouclier_restant > 0.0 or bouclier_spawn > 0.0


func _process(delta: float) -> void:
	cd_onde = maxf(cd_onde - delta, 0.0)
	cd_dash = maxf(cd_dash - delta, 0.0)
	cd_bouclier = maxf(cd_bouclier - delta, 0.0)
	immunite = maxf(immunite - delta, 0.0)
	bouclier_restant = maxf(bouclier_restant - delta, 0.0)
	bouclier_spawn = maxf(bouclier_spawn - delta, 0.0)
	gel_restant = maxf(gel_restant - delta, 0.0)

	# État du visuel (anneau doré du porteur, bulles de protection).
	visuel.anneau_dore = porte_dragon()
	visuel.bulle = 1.0 if bouclier_restant > 0.0 else (0.6 if bouclier_spawn > 0.0 else 0.0)
	visuel.bulle_teinte = Color(0.7, 0.45, 1.0) if bouclier_restant > 0.0 else Color(0.5, 0.85, 1.0)

	if ko_restant > 0.0:
		ko_restant -= delta
		visible = false
		if ko_restant <= 0.0:
			_reapparaitre()
		return

	position += recul * delta
	recul *= pow(0.002, delta) # la poussée s'amortit très vite

	# Personne ne bouge pendant la QUESTION, l'interlude ou le podium.
	if arene.etat != Arene.Etat.JEU:
		visuel.en_marche = false
		position = arene.borner(position)
		return

	if gel_restant > 0.0:
		visuel.en_marche = false
		position = arene.borner(position)
		return

	if dash_restant > 0.0:
		# Distance décomptée frame par frame : identique quel que soit le framerate.
		var pas := minf(VITESSE_DASH * delta, dash_restant)
		position += dir_dash * pas
		dash_restant -= pas
		arene.fx.traine(position, Color(0.45, 0.9, 1.0))
	else:
		var dir := _direction_voulue()
		if dir.length() > 0.05:
			position += dir.normalized() * vitesse * minf(dir.length(), 1.0) * delta
			derniere_dir = dir.normalized()
			visuel.en_marche = true
		else:
			visuel.en_marche = false
		visuel.regard = derniere_dir

	position = arene.borner(position)

	# Attraper le dragon libre = marcher dessus.
	if arene.dragon != null and arene.dragon.libre() \
			and position.distance_to(arene.dragon.position) < Dragon.RAYON_CONTACT:
		arene.prendre_dragon(self, "capture")

	arene.ramasser_cristaux(self)

	if est_joueur:
		_entrees_pouvoirs()
	else:
		_ia_pouvoirs(delta)


# ---------------------------------------------------------------- entrées / IA

func _direction_voulue() -> Vector2:
	if est_joueur:
		var dir := Input.get_vector("mv_gauche", "mv_droite", "mv_haut", "mv_bas")
		if hud != null and hud.vecteur_joystick.length() > 0.12:
			dir = hud.vecteur_joystick
		return dir
	return _ia_direction()


func _entrees_pouvoirs() -> void:
	if Input.is_action_just_pressed("comp_onde"):
		if cd_onde > 0.0 and hud != null:
			hud.refus("onde")
		else:
			utiliser_onde()
	if Input.is_action_just_pressed("comp_dash"):
		if cd_dash > 0.0 and hud != null:
			hud.refus("dash")
		else:
			utiliser_dash()
	if Input.is_action_just_pressed("comp_bouclier"):
		if cd_bouclier > 0.0 and hud != null:
			hud.refus("bouclier")
		else:
			utiliser_bouclier()


func _ia_direction() -> Vector2:
	var dr := arene.dragon
	if dr == null:
		return Vector2.ZERO
	if porte_dragon():
		# Court vers la zone de SON choix (re-choisit après un refus).
		if choix == -1:
			bot_choisir()
		if choix >= 0:
			var cible_zone: Vector2 = arene.zones[choix].pos
			return (cible_zone - position).normalized()
		return Vector2.ZERO
	# Un besoin d'énergie passe avant la chasse.
	if energie < 40.0:
		var cristal := arene.cristal_le_plus_proche(position)
		if cristal != null and position.distance_to(cristal.position) < 420.0:
			return (cristal.position - position).normalized()
	if dr.libre():
		return (dr.position - position).normalized()
	if dr.porteur != self:
		return (dr.porteur.position - position).normalized()
	return Vector2.ZERO


## Réflexes des bots : mêmes pouvoirs et cooldowns que le joueur.
func _ia_pouvoirs(delta: float) -> void:
	var dr := arene.dragon
	if dr == null:
		return
	var porteur := dr.porteur
	# Onde si le porteur adverse est tout près (~1,2 chance/s).
	if porteur != null and porteur != self and cd_onde <= 0.0 \
			and position.distance_to(porteur.position) <= 210.0 and randf() < 1.2 * delta:
		utiliser_onde()
	# Dash pour combler une grande distance vers la cible.
	var cible: Node2D = dr if dr.libre() else porteur
	if cible != null and cible != self and cd_dash <= 0.0 \
			and position.distance_to(cible.position) > 540.0:
		utiliser_dash()
	# Bouclier quand on porte le dragon avec une menace proche (~0,5 chance/s).
	if porte_dragon() and cd_bouclier <= 0.0 and randf() < 0.5 * delta \
			and arene.menace_proche(self, 192.0):
		utiliser_bouclier()


## Choix de réponse d'un bot : bonne réponse avec probabilité 0,5
## (botAnswerAccuracy), sinon au hasard parmi ses réponses restantes.
func bot_choisir() -> void:
	var restantes: Array = []
	for i in 4:
		if not testees.has(i):
			restantes.append(i)
	if restantes.is_empty():
		return
	var bonne: int = arene.question.bonne
	if not testees.has(bonne) and randf() < 0.5:
		choix = bonne
	else:
		choix = restantes[randi() % restantes.size()]


# ---------------------------------------------------------------- pouvoirs

func utiliser_onde() -> void:
	if cd_onde > 0.0 or gel_restant > 0.0 or ko_restant > 0.0 or arene.etat != Arene.Etat.JEU:
		return
	cd_onde = CD_ONDE
	# Visée assistée : pivote vers la meilleure cible à portée (porteur en priorité).
	var cible := arene.meilleure_cible_onde(self)
	if cible != null:
		derniere_dir = (cible.position - position).normalized()
		visuel.regard = derniere_dir
	arene.fx.cone(position, derniere_dir.angle(), PORTEE_ONDE, DEMI_CONE)
	visuel.squash(0.2)
	Audio.jouer("onde")
	for c in arene.chasseurs:
		if c == self or c.ko_restant > 0.0:
			continue
		var v: Vector2 = c.position - position
		if v.length() <= PORTEE_ONDE + 20.0 and absf(derniere_dir.angle_to(v.normalized())) <= DEMI_CONE:
			c.subir_poussee(self)


func utiliser_dash() -> void:
	if cd_dash > 0.0 or gel_restant > 0.0 or ko_restant > 0.0 or arene.etat != Arene.Etat.JEU:
		return
	cd_dash = CD_DASH
	var dir := _direction_voulue()
	dir_dash = dir.normalized() if dir.length() > 0.05 else derniere_dir
	dash_restant = DIST_DASH
	visuel.squash(0.25)
	Audio.jouer("dash")


func utiliser_bouclier() -> void:
	if cd_bouclier > 0.0 or gel_restant > 0.0 or ko_restant > 0.0 or arene.etat != Arene.Etat.JEU:
		return
	cd_bouclier = CD_BOUCLIER
	bouclier_restant = DUREE_BOUCLIER
	arene.fx.anneau(position, 52.0, Color(0.7, 0.45, 1.0))
	Audio.jouer("bouclier")


# ---------------------------------------------------------------- subir

func subir_poussee(source: Chasseur) -> void:
	if protege():
		arene.fx.texte_flottant(position + Vector2(0.0, -36.0), "protégé !", Color(0.8, 0.65, 1.0))
		return
	recul = (position - source.position).normalized() * RECUL_ONDE
	subir_degats(DEGATS_ONDE, source)
	# Vol propre : l'onde prend le dragon au porteur touché (sauf immunité).
	if ko_restant <= 0.0 and porte_dragon() and immunite <= 0.0:
		arene.prendre_dragon(source, "vol")


func subir_degats(deg: float, source: Chasseur) -> void:
	if protege() or ko_restant > 0.0:
		return
	energie = maxf(energie - deg, 0.0)
	visuel.flash()
	visuel.squash(0.18)
	arene.fx.texte_flottant(position + Vector2(0.0, -36.0), "-%d" % int(deg), Color(1.0, 0.35, 0.3))
	if est_joueur:
		arene.fx.secousse(0.35)
		Audio.jouer("coup_recu")
		if hud != null and source != null:
			hud.toast("%s t'attaque !" % source.nom)
	if energie <= 0.0:
		_ko()


func perdre_energie_reponse() -> void:
	# Mauvaise réponse : -10 énergie (le bouclier ne protège pas de ça).
	energie = maxf(energie - 10.0, 0.0)
	if energie <= 0.0:
		_ko()


func geler(duree: float) -> void:
	gel_restant = duree
	dash_restant = 0.0


func _ko() -> void:
	if ko_restant > 0.0:
		return
	ko_restant = DUREE_KO
	dash_restant = 0.0
	score -= PENALITE_KO
	if porte_dragon():
		arene.lacher_dragon(position)
	arene.fx.eclat_etoiles(position, teinte, 16)
	arene.fx.texte_flottant(position + Vector2(0.0, -30.0), "K.O. !", Color(1.0, 0.5, 0.3))
	Audio.jouer("ko")
	if est_joueur:
		arene.fx.secousse(0.7)


func _reapparaitre() -> void:
	# Réapparition loin du dragon, énergie pleine, bouclier 1,5 s.
	visible = true
	ko_restant = 0.0
	position = arene.point_reapparition()
	energie = ENERGIE_MAX
	bouclier_spawn = BOUCLIER_REAPPARITION
	recul = Vector2.ZERO
	arene.fx.eclat_etoiles(position, Color(0.6, 1.0, 0.7), 10)

class_name Chasseur
extends Node3D
## Un chasseur de dragon : Max (le joueur) ou un bot (Zep, Nova, Ficelle).
## Énergie, trois pouvoirs à recharge pure (Onde de choc, Dash, Bouclier),
## vol du dragon, K.O. et réapparition. Valeurs du spike Three.js, unités
## identiques (1 u = 1 m), cf. docs/mecaniques-arene.md.
##
## v2 multijoueur : instanciable N fois ; les bots (_ia_*) deviendront des
## joueurs distants en remplaçant leurs entrées (voir reseau.gd).

const VITESSE_JOUEUR := 4.4
const VITESSE_BOT := 3.0
const ENERGIE_MAX := 100.0

# Onde de choc : contrôle + vol du dragon, pas une exécution (10 ≪ 34).
const CD_ONDE := 4.0
const PORTEE_ONDE := 3.2
const DEMI_CONE := 0.68      ## cône ~78°
const DEGATS_ONDE := 10.0
const RECUL_ONDE := 10.5     ## vitesse initiale de poussée (décroît vite)

const CD_DASH := 5.0
const DIST_DASH := 6.0       ## exactement 6 u, décomptée frame par frame
const VITESSE_DASH := 26.0

const CD_BOUCLIER := 7.0
const DUREE_BOUCLIER := 2.0

const IMMUNITE_VOL := 1.0    ## anti ping-pong après toute prise
const DUREE_KO := 3.0
const BOUCLIER_REAPPARITION := 1.5
const PENALITE_KO := 5

## L'ÉVEIL : chaque bonne dépose fait ÉVOLUER le Lumin en plein match.
## Réussir en maths rend PLUS FORT, visiblement : plus grand, plus rapide,
## recharges plus courtes, onde plus longue — ailes de lumière au niveau 3.
const EVEIL_MAX := 3
const EVEIL_VITESSE := 0.09     ## +9 % de vitesse par niveau
const EVEIL_RECHARGE := 0.08    ## -8 % de recharge par niveau
const EVEIL_PORTEE := 0.35      ## +0,35 u de portée d'onde par niveau

## LE SUPER : un pouvoir signature par héros, chargé en ramassant des
## éclats (cristaux) et en mettant K.O. — l'action paie, façon Brawl Stars.
const COUT_SUPER := 3
const NOMS_SUPERS := {
	"Max": "Nova Solaire", "Zep": "Overdrive",
	"Nova": "Appel de l'étoile", "Ficelle": "Cercle de braise",
}
const RAYON_NOVA_SOLAIRE := 5.5
const DUREE_OVERDRIVE := 4.0
const PORTEE_APPEL := 9.0
const RAYON_BRAISE := 3.6

var arene: Arene
var hud: HUD                 ## renseigné uniquement pour le joueur
var est_joueur := false
var nom := "Max"
var teinte := Color(0.30, 0.75, 0.72)
var vitesse := VITESSE_BOT

var energie := ENERGIE_MAX
var score := 0
var choix := -1              ## réponse choisie (-1 : aucune)
var testees: Array = []      ## indices de réponses déjà refusées (individuel)

var derniere_dir := Vector2.DOWN
var recul := Vector2.ZERO
var cd_onde := 0.0
var cd_dash := 0.0
var cd_bouclier := 0.0
var dash_restant := 0.0
var dir_dash := Vector2.DOWN
var bouclier_restant := 0.0
var bouclier_spawn := 0.0
var immunite := 0.0
var gel_restant := 0.0
var ko_restant := 0.0

var eveil := 0               ## niveau d'Éveil du match (0..3)
var charge_super := 0        ## éclats accumulés vers le Super
var surcharge_restant := 0.0 ## Overdrive de Zep (vitesse boostée)

var visuel: Personnage3D
var _traine_delai := 0.0  ## cadence de la traînée dorée du porteur
var _pause_ia := 0.0      ## temps de réaction des bots (laisse jouer l'humain)


var facteur_cd := 1.0  ## la Puissance du héros raccourcit ses recharges


## À appeler AVANT l'ajout à l'arbre.
func configurer(p_nom: String, p_teinte: Color, p_est_joueur: bool, pos: Vector2) -> void:
	nom = p_nom
	teinte = p_teinte
	est_joueur = p_est_joueur
	vitesse = VITESSE_JOUEUR if est_joueur else VITESSE_BOT
	if est_joueur:
		# Puissance du héros (Route/pièces) : +3 % vitesse, −3 % recharge par niveau.
		vitesse *= Profil.bonus_puissance(nom)
		facteur_cd = 1.0 / Profil.bonus_puissance(nom)
	position = Vector3(pos.x, 0.0, pos.y)


var _compagnon: Personnage3D  ## le dragon de collection qui vole à tes côtés


func _ready() -> void:
	visuel = Personnage3D.new()
	visuel.genre = "chasseur"
	visuel.couleur = teinte
	visuel.utiliser_fiche_couleur = false # la variante de la garde-robe prime
	visuel.etiquette = nom
	add_child(visuel)
	# Le compagnon du joueur : son dragon du Sanctuaire, visible par tous.
	if est_joueur and Personnage3D.ESPECES.has(Profil.compagnon):
		_compagnon = Personnage3D.new()
		_compagnon.genre = "dragon"
		_compagnon.couleur = Personnage3D.ESPECES[Profil.compagnon].couleur
		_compagnon.scale = Vector3.ONE * 0.55
		_compagnon.position = Vector3(-0.9, 1.5, -0.7)
		add_child(_compagnon)


func pos2() -> Vector2:
	return Vector2(position.x, position.z)


func fixer_pos2(v: Vector2) -> void:
	position = Vector3(v.x, position.y, v.y)


func regard() -> Vector2:
	return derniere_dir


func porte_dragon() -> bool:
	return arene.dragon != null and arene.dragon.porteur == self


func protege() -> bool:
	return bouclier_restant > 0.0 or bouclier_spawn > 0.0


# ---------------------------------------------------------------- Éveil / Super

## Vitesse réelle : base × Éveil × Overdrive éventuel.
func vitesse_effective() -> float:
	var v := vitesse * (1.0 + EVEIL_VITESSE * eveil)
	if surcharge_restant > 0.0:
		v *= 1.65
	return v


## Facteur de recharge réel : Puissance (méta) × Éveil (match).
func facteur_recharge() -> float:
	return facteur_cd * (1.0 - EVEIL_RECHARGE * eveil)


func portee_onde() -> float:
	return PORTEE_ONDE + EVEIL_PORTEE * eveil


func super_pret() -> bool:
	return charge_super >= COUT_SUPER


## +1 niveau d'Éveil (bonne dépose) : transformation visible + annonce.
func monter_eveil() -> void:
	if eveil >= EVEIL_MAX:
		return
	eveil += 1
	visuel.fixer_eveil(eveil)
	arene.fx.anneau(pos2(), 2.4, teinte)
	arene.fx.eclat_etoiles(pos2(), teinte.lightened(0.2), 26)
	arene.fx.texte_flottant(pos2(), "ÉVEIL %d !" % eveil, teinte.lightened(0.35))
	Audio.jouer("eveil")
	if est_joueur:
		arene.fx.secousse(0.35)
		if hud != null:
			hud.toast(["", "ÉVEIL I — tu cours plus vite !",
				"ÉVEIL II — recharges plus courtes, onde plus longue !",
				"ÉVEIL III — AILES DE LUMIÈRE ! Tu es au maximum !"][eveil])


## +n éclats vers le Super ; annonce quand il devient prêt.
func charger_super(n := 1) -> void:
	var etait_pret := super_pret()
	charge_super = mini(charge_super + n, COUT_SUPER)
	if super_pret() and not etait_pret:
		arene.fx.texte_flottant(pos2(), "SUPER PRÊT !", Identite.OR)
		if est_joueur:
			Audio.jouer("super_pret")
			if hud != null:
				hud.toast("SUPER PRÊT — %s ! (bouton étoile ou F)" % NOMS_SUPERS.get(nom, "Super"))


func _process(delta: float) -> void:
	cd_onde = maxf(cd_onde - delta, 0.0)
	cd_dash = maxf(cd_dash - delta, 0.0)
	cd_bouclier = maxf(cd_bouclier - delta, 0.0)
	surcharge_restant = maxf(surcharge_restant - delta, 0.0)
	immunite = maxf(immunite - delta, 0.0)
	bouclier_restant = maxf(bouclier_restant - delta, 0.0)
	bouclier_spawn = maxf(bouclier_spawn - delta, 0.0)
	gel_restant = maxf(gel_restant - delta, 0.0)

	# Le compagnon volette à côté, toujours en battement d'ailes.
	if _compagnon != null:
		_compagnon.position.y = 1.5 + sin(Time.get_ticks_msec() / 400.0) * 0.15
		_compagnon.en_marche = visuel.en_marche
		_compagnon.regarder(derniere_dir)

	# État du visuel : anneau doré du porteur, bulles de protection.
	visuel.montrer_anneau(porte_dragon())
	if bouclier_restant > 0.0:
		visuel.montrer_bulle(1.0, Color(0.7, 0.45, 1.0))
	elif bouclier_spawn > 0.0:
		visuel.montrer_bulle(0.7, Color(0.5, 0.85, 1.0))
	else:
		visuel.montrer_bulle(0.0, Color.WHITE)

	if ko_restant > 0.0:
		ko_restant -= delta
		visible = false
		if ko_restant <= 0.0:
			_reapparaitre()
		return

	fixer_pos2(pos2() + recul * delta)
	recul *= pow(0.002, delta) # la poussée s'amortit très vite

	# Personne ne bouge pendant la QUESTION, l'interlude ou le podium.
	if arene.etat != Arene.Etat.JEU:
		visuel.en_marche = false
		fixer_pos2(arene.borner(pos2()))
		return

	if gel_restant > 0.0:
		visuel.en_marche = false
		fixer_pos2(arene.borner(pos2()))
		return

	if dash_restant > 0.0:
		# Distance décomptée frame par frame : identique quel que soit le framerate.
		var pas := minf(VITESSE_DASH * delta, dash_restant)
		fixer_pos2(pos2() + dir_dash * pas)
		dash_restant -= pas
		arene.fx.traine(pos2(), Color(0.45, 0.9, 1.0))
	else:
		var dir := _direction_voulue()
		if dir.length() > 0.05:
			fixer_pos2(pos2() + dir.normalized() * vitesse_effective() * minf(dir.length(), 1.0) * delta)
			derniere_dir = dir.normalized()
			visuel.en_marche = true
		else:
			visuel.en_marche = false
		visuel.regarder(derniere_dir)
		# Traînée cyan de l'Overdrive de Zep.
		if surcharge_restant > 0.0 and visuel.en_marche:
			arene.fx.traine(pos2(), Identite.CYAN)

	fixer_pos2(arene.borner(pos2()))

	# Traînée dorée du porteur : la poursuite se lit d'un coup d'œil.
	if porte_dragon() and visuel.en_marche:
		_traine_delai -= delta
		if _traine_delai <= 0.0:
			_traine_delai = 0.09
			arene.fx.traine(pos2(), Identite.OR)

	# Attraper le dragon libre = marcher dessus.
	if arene.dragon != null and arene.dragon.libre() \
			and pos2().distance_to(arene.dragon.pos2()) < Dragon.RAYON_CONTACT:
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
	if Input.is_action_just_pressed("comp_super"):
		if not super_pret() and hud != null:
			hud.refus("super")
		else:
			utiliser_super()


func _ia_direction() -> Vector2:
	# Les bots « réfléchissent » par instants : l'humain a des fenêtres pour agir.
	if _pause_ia > 0.0:
		return Vector2.ZERO
	var dr := arene.dragon
	if dr == null:
		return Vector2.ZERO
	if porte_dragon():
		# Court vers la zone de SON choix (re-choisit après un refus).
		if choix == -1:
			bot_choisir()
		if choix >= 0:
			var cible_zone: Vector2 = arene.zones[choix].pos
			return (cible_zone - pos2()).normalized()
		return Vector2.ZERO
	# Un besoin d'énergie passe avant la chasse.
	if energie < 40.0:
		var cristal := arene.cristal_le_plus_proche(pos2())
		if cristal != null and pos2().distance_to(cristal.pos2()) < 7.0:
			return (cristal.pos2() - pos2()).normalized()
	# Un éclat tout proche vaut le détour tant que le Super n'est pas prêt.
	if not super_pret():
		var eclat := arene.cristal_le_plus_proche(pos2())
		if eclat != null and pos2().distance_to(eclat.pos2()) < 4.0:
			return (eclat.pos2() - pos2()).normalized()
	if dr.libre():
		return (dr.pos2() - pos2()).normalized()
	if dr.porteur != self:
		return (dr.porteur.pos2() - pos2()).normalized()
	return Vector2.ZERO


## Réflexes des bots : mêmes pouvoirs et cooldowns que le joueur.
func _ia_pouvoirs(delta: float) -> void:
	_pause_ia = maxf(_pause_ia - delta, 0.0)
	# De temps en temps, un bot hésite (~1 pause de 0,7 s toutes les 5 s).
	if _pause_ia <= 0.0 and randf() < 0.2 * delta:
		_pause_ia = 0.7
	var dr := arene.dragon
	if dr == null:
		return
	var porteur := dr.porteur
	# Onde si le porteur adverse est tout près (~1,2 chance/s).
	if porteur != null and porteur != self and cd_onde <= 0.0 \
			and pos2().distance_to(porteur.pos2()) <= 3.5 and randf() < 1.2 * delta:
		utiliser_onde()
	# Dash pour combler une grande distance vers la cible.
	var cible_pos := Vector2.INF
	if dr.libre():
		cible_pos = dr.pos2()
	elif porteur != self:
		cible_pos = porteur.pos2()
	if cible_pos != Vector2.INF and cd_dash <= 0.0 and pos2().distance_to(cible_pos) > 9.0:
		utiliser_dash()
	# Bouclier quand on porte le dragon avec une menace proche (~0,5 chance/s).
	if porte_dragon() and cd_bouclier <= 0.0 and randf() < 0.5 * delta \
			and arene.menace_proche(self, 3.2):
		utiliser_bouclier()
	# SUPER : chaque bot déclenche le sien au bon moment (~0,8 chance/s).
	if super_pret() and randf() < 0.8 * delta:
		match nom:
			"Max":
				if porteur != null and porteur != self \
						and pos2().distance_to(porteur.pos2()) <= RAYON_NOVA_SOLAIRE - 0.5:
					utiliser_super()
			"Zep":
				if cible_pos != Vector2.INF and pos2().distance_to(cible_pos) > 7.0:
					utiliser_super()
			"Nova":
				if dr.porteur != self and pos2().distance_to(dr.pos2()) <= PORTEE_APPEL - 0.5:
					utiliser_super()
			"Ficelle":
				if porte_dragon() and arene.menace_proche(self, RAYON_BRAISE - 0.4):
					utiliser_super()


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
	cd_onde = CD_ONDE * facteur_recharge()
	# Visée assistée : pivote vers la meilleure cible à portée (porteur en priorité).
	var cible := arene.meilleure_cible_onde(self)
	if cible != null:
		derniere_dir = (cible.pos2() - pos2()).normalized()
		visuel.regarder(derniere_dir)
	arene.fx.cone(pos2(), derniere_dir, portee_onde())
	visuel.squash(0.2)
	Audio.jouer("onde")
	for c in arene.chasseurs:
		if c == self or c.ko_restant > 0.0:
			continue
		var v: Vector2 = c.pos2() - pos2()
		if v.length() <= portee_onde() + 0.35 and absf(derniere_dir.angle_to(v.normalized())) <= DEMI_CONE:
			c.subir_poussee(self)


func utiliser_dash() -> void:
	if cd_dash > 0.0 or gel_restant > 0.0 or ko_restant > 0.0 or arene.etat != Arene.Etat.JEU:
		return
	cd_dash = CD_DASH * facteur_recharge()
	var dir := _direction_voulue()
	dir_dash = dir.normalized() if dir.length() > 0.05 else derniere_dir
	dash_restant = DIST_DASH
	visuel.squash(0.25)
	Audio.jouer("dash")


func utiliser_bouclier() -> void:
	if cd_bouclier > 0.0 or gel_restant > 0.0 or ko_restant > 0.0 or arene.etat != Arene.Etat.JEU:
		return
	cd_bouclier = CD_BOUCLIER * facteur_recharge()
	bouclier_restant = DUREE_BOUCLIER
	arene.fx.anneau(pos2(), 1.4, Color(0.7, 0.45, 1.0))
	Audio.jouer("bouclier")


# ---------------------------------------------------------------- supers

## Le SUPER signature du héros : dépense les éclats accumulés.
func utiliser_super() -> void:
	if not super_pret() or gel_restant > 0.0 or ko_restant > 0.0 or arene.etat != Arene.Etat.JEU:
		return
	# L'Appel de Nova exige le dragon à portée — sinon on garde la charge.
	if nom == "Nova":
		var dr := arene.dragon
		if dr == null or dr.porteur == self or pos2().distance_to(dr.pos2()) > PORTEE_APPEL:
			if est_joueur and hud != null:
				hud.refus("super")
				hud.toast("Le dragon est trop loin pour l'Appel de l'étoile !")
			return
	charge_super = 0
	Audio.jouer("super")
	arene.fx.texte_flottant(pos2(), str(NOMS_SUPERS.get(nom, "SUPER")) + " !", Identite.OR)
	if est_joueur:
		arene.fx.secousse(0.5)
	match nom:
		"Max":
			_super_nova_solaire()
		"Zep":
			_super_overdrive()
		"Nova":
			_super_appel()
		"Ficelle":
			_super_braise()


## Max — NOVA SOLAIRE : déflagration circulaire géante qui repousse tout le
## monde et vole le dragon au porteur touché.
func _super_nova_solaire() -> void:
	arene.fx.anneau(pos2(), RAYON_NOVA_SOLAIRE, Identite.OR)
	arene.fx.anneau(pos2(), RAYON_NOVA_SOLAIRE * 0.6, Color.WHITE)
	arene.fx.eclat_etoiles(pos2(), Identite.OR, 32)
	visuel.squash(0.35)
	for c in arene.chasseurs:
		if c != self and c.ko_restant <= 0.0 \
				and pos2().distance_to(c.pos2()) <= RAYON_NOVA_SOLAIRE:
			c.subir_poussee(self)


## Zep — OVERDRIVE : 4 s de vitesse fulgurante, insaisissable (immunité).
func _super_overdrive() -> void:
	surcharge_restant = DUREE_OVERDRIVE
	immunite = maxf(immunite, DUREE_OVERDRIVE)
	arene.fx.anneau(pos2(), 1.8, Identite.CYAN)
	arene.fx.eclat_etoiles(pos2(), Identite.CYAN, 20)


## Nova — APPEL DE L'ÉTOILE : le dragon est arraché (même des bras d'un
## porteur) et vole jusqu'à elle en pluie d'étoiles.
func _super_appel() -> void:
	var dr := arene.dragon
	var depart := dr.pos2()
	# Pluie d'étoiles sur la trajectoire du rappel.
	for k in 7:
		arene.fx.eclat_etoiles(depart.lerp(pos2(), float(k) / 6.0), Identite.CREME, 5)
	arene.prendre_dragon(self, "vol")
	arene.fx.anneau(pos2(), 2.2, Identite.CREME)


## Ficelle — CERCLE DE BRAISE : anneau de feu qui repousse, brûle et gèle
## les adversaires trop proches — parfait pour protéger sa dépose.
func _super_braise() -> void:
	arene.fx.anneau(pos2(), RAYON_BRAISE, Identite.ORANGE)
	arene.fx.anneau(pos2(), RAYON_BRAISE * 0.7, Identite.ROUGE)
	arene.fx.eclat_etoiles(pos2(), Identite.ORANGE, 28)
	for c in arene.chasseurs:
		if c != self and c.ko_restant <= 0.0 \
				and pos2().distance_to(c.pos2()) <= RAYON_BRAISE:
			c.recul = (c.pos2() - pos2()).normalized() * RECUL_ONDE * 1.4
			c.subir_degats(20.0, self)
			c.geler(1.0)


# ---------------------------------------------------------------- subir

func subir_poussee(source: Chasseur) -> void:
	if protege():
		arene.fx.texte_flottant(pos2(), "protégé !", Color(0.8, 0.65, 1.0))
		return
	recul = (pos2() - source.pos2()).normalized() * RECUL_ONDE
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
	arene.fx.texte_flottant(pos2(), "-%d" % int(deg), Color(1.0, 0.35, 0.3))
	if est_joueur:
		arene.fx.secousse(0.35)
		Audio.jouer("coup_recu")
		if hud != null and source != null:
			hud.toast("%s t'attaque !" % source.nom)
	if energie <= 0.0:
		_ko(source)


func perdre_energie_reponse() -> void:
	# Mauvaise réponse : -10 énergie (le bouclier ne protège pas de ça).
	energie = maxf(energie - 10.0, 0.0)
	if energie <= 0.0:
		_ko()


func geler(duree: float) -> void:
	gel_restant = duree
	dash_restant = 0.0


func _ko(source: Chasseur = null) -> void:
	if ko_restant > 0.0:
		return
	ko_restant = DUREE_KO
	dash_restant = 0.0
	score -= PENALITE_KO
	# Le K.O. infligé charge le Super de l'attaquant : l'action paie.
	if source != null and source != self:
		source.charger_super(1)
	if porte_dragon():
		arene.lacher_dragon(pos2())
	arene.fx.eclat_etoiles(pos2(), teinte, 16)
	arene.fx.texte_flottant(pos2(), "K.O. !", Color(1.0, 0.5, 0.3))
	Audio.jouer("ko")
	if est_joueur:
		arene.fx.secousse(0.7)


func _reapparaitre() -> void:
	# Réapparition loin du dragon, énergie pleine, bouclier 1,5 s.
	visible = true
	ko_restant = 0.0
	fixer_pos2(arene.point_reapparition())
	energie = ENERGIE_MAX
	bouclier_spawn = BOUCLIER_REAPPARITION
	recul = Vector2.ZERO
	arene.fx.eclat_etoiles(pos2(), Color(0.6, 1.0, 0.7), 10)

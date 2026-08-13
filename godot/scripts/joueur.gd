class_name Joueur
extends Node2D
## Le héros : déplacement (joystick tactile flottant + clavier), auto-attaque
## sur l'ennemi le plus proche, trois compétences actives, statistiques,
## expérience et équipement auto-équipé.
##
## v2 multijoueur : ce script ne contient QUE la logique locale du personnage.
## L'état (position, pv, niveau) est conçu pour être répliqué par reseau.gd.

const VITESSE := 210.0
const PORTEE_ATTAQUE := 80.0   ## portée de l'auto-attaque (px)
const CADENCE_ATTAQUE := 0.55  ## secondes entre deux coups automatiques

# Compétences (portées et temps de recharge du cahier des charges).
const RAYON_TOURBILLON := 110.0
const CD_TOURBILLON := 5.0
const RAYON_NOVA := 190.0
const CD_NOVA := 9.0
const DUREE_ROULADE := 0.32
const CD_ROULADE := 1.6
const VITESSE_ROULADE := 640.0

var monde: Monde
var fx: FX
var hud: HUD

# --- Statistiques ---
var niveau := 1
var xp := 0.0
var pv_max := 100.0
var pv := 100.0
var vivant := true
var arme := {"emplacement": "arme", "nom": "Épée rouillée", "rarete": 0, "valeur": 2.0}
var armure := {"emplacement": "armure", "nom": "Tunique usée", "rarete": 0, "valeur": 0.0}

# --- États transitoires ---
var cd_attaque := 0.0
var cd_tourbillon := 0.0
var cd_nova := 0.0
var cd_roulade := 0.0
var roulade_restante := 0.0
var direction_roulade := Vector2.RIGHT
var derniere_direction := Vector2.RIGHT

var visuel: VisuelCartoon


func _ready() -> void:
	visuel = VisuelCartoon.new()
	visuel.genre = "joueur"
	visuel.rayon = 16.0
	visuel.couleur = Color(0.36, 0.72, 0.47)
	add_child(visuel)
	# Emplacement prévu pour un vrai sprite (voir assets/README.md).
	var sprite := Sprite2D.new()
	sprite.name = "Sprite2D"
	add_child(sprite)


func attaque_totale() -> float:
	return 8.0 + (niveau - 1) * 2.0 + float(arme.valeur)


func defense_totale() -> float:
	return (niveau - 1) * 1.0 + float(armure.valeur)


## Courbe d'expérience demandée : 40 × 1,4^niveau.
func xp_requise() -> float:
	return 40.0 * pow(1.4, niveau - 1)


func invincible() -> bool:
	return roulade_restante > 0.0


func _process(delta: float) -> void:
	if not vivant:
		return

	cd_attaque = maxf(cd_attaque - delta, 0.0)
	cd_tourbillon = maxf(cd_tourbillon - delta, 0.0)
	cd_nova = maxf(cd_nova - delta, 0.0)
	cd_roulade = maxf(cd_roulade - delta, 0.0)

	# --- Déplacement : clavier OU joystick tactile (le joystick gagne). ---
	var dir := Input.get_vector("mv_gauche", "mv_droite", "mv_haut", "mv_bas")
	if hud != null and hud.vecteur_joystick.length() > 0.12:
		dir = hud.vecteur_joystick
	if dir.length() > 1.0:
		dir = dir.normalized()

	if roulade_restante > 0.0:
		roulade_restante -= delta
		position += direction_roulade * VITESSE_ROULADE * delta
	elif dir != Vector2.ZERO:
		position += dir * VITESSE * delta
		derniere_direction = dir.normalized()

	visuel.en_marche = dir != Vector2.ZERO or roulade_restante > 0.0
	visuel.regard = derniere_direction

	# On reste dans le disque du monde.
	if position.length() > Monde.RAYON_MONDE - 40.0:
		position = position.normalized() * (Monde.RAYON_MONDE - 40.0)

	# --- Compétences au clavier (les boutons tactiles appellent les mêmes fonctions). ---
	if Input.is_action_just_pressed("comp_tourbillon"):
		utiliser_tourbillon()
	if Input.is_action_just_pressed("comp_nova"):
		utiliser_nova()
	if Input.is_action_just_pressed("comp_roulade"):
		utiliser_roulade()

	_auto_attaque()


## Frappe automatiquement l'ennemi le plus proche à portée (arc de mêlée).
func _auto_attaque() -> void:
	if cd_attaque > 0.0 or monde == null:
		return
	var cible := monde.ennemi_le_plus_proche(position, PORTEE_ATTAQUE)
	if cible == null:
		return
	cd_attaque = CADENCE_ATTAQUE
	var dir := (cible.position - position).normalized()
	derniere_direction = dir
	visuel.squash(0.15)
	fx.coup_d_epee(position, dir.angle())
	Audio.jouer("coup")
	cible.subir_degats(attaque_totale() * randf_range(0.9, 1.1))


func utiliser_tourbillon() -> void:
	if not vivant or cd_tourbillon > 0.0:
		return
	cd_tourbillon = CD_TOURBILLON
	fx.anneau(position, RAYON_TOURBILLON, Color(0.55, 0.85, 1.0))
	fx.secousse(0.25)
	Audio.jouer("tourbillon")
	for e in monde.ennemis_dans_rayon(position, RAYON_TOURBILLON):
		e.subir_degats(attaque_totale() * 1.7)


func utiliser_nova() -> void:
	if not vivant or cd_nova > 0.0:
		return
	cd_nova = CD_NOVA
	fx.anneau(position, RAYON_NOVA, Color(1.0, 0.8, 0.3))
	fx.eclat_etoiles(position, Color(1.0, 0.85, 0.35), 14)
	fx.secousse(0.5)
	Audio.jouer("nova")
	for e in monde.ennemis_dans_rayon(position, RAYON_NOVA):
		e.subir_degats(attaque_totale() * 2.6)
		# Petit recul pour la lisibilité du combat.
		e.position += (e.position - position).normalized() * 46.0


func utiliser_roulade() -> void:
	if not vivant or cd_roulade > 0.0:
		return
	cd_roulade = CD_ROULADE
	roulade_restante = DUREE_ROULADE
	var dir := Input.get_vector("mv_gauche", "mv_droite", "mv_haut", "mv_bas")
	if hud != null and hud.vecteur_joystick.length() > 0.12:
		dir = hud.vecteur_joystick
	direction_roulade = dir.normalized() if dir.length() > 0.01 else derniere_direction
	visuel.squash(0.3)
	Audio.jouer("roulade")


func subir_degats(brut: float) -> void:
	if not vivant:
		return
	if invincible():
		fx.texte_flottant(position + Vector2(0.0, -26.0), "esquivé !", Color(0.8, 0.9, 1.0))
		return
	var deg := maxf(brut - defense_totale() * 0.6, 1.0)
	pv -= deg
	visuel.flash()
	visuel.squash(0.2)
	fx.texte_flottant(position + Vector2(0.0, -30.0), str(int(round(deg))), Color(1.0, 0.45, 0.35))
	fx.secousse(0.35)
	Audio.jouer("coup_recu")
	if pv <= 0.0:
		_mourir()


## Mort : retour au sanctuaire central, PV restaurés.
func _mourir() -> void:
	vivant = false
	pv = 0.0
	fx.eclat_etoiles(position, Color(0.9, 0.3, 0.3), 14)
	fx.secousse(0.8)
	Audio.jouer("mort")
	if hud != null:
		hud.message("Vous succombez… retour au sanctuaire.", 2.2)
	get_tree().create_timer(1.8).timeout.connect(_reapparaitre)


func _reapparaitre() -> void:
	position = Vector2.ZERO
	pv = pv_max
	vivant = true
	fx.eclat_etoiles(position, Color(0.5, 1.0, 0.6), 12)


func gagner_xp(quantite: float) -> void:
	xp += quantite
	while xp >= xp_requise():
		xp -= xp_requise()
		niveau += 1
		pv_max += 12.0
		pv = pv_max
		fx.texte_flottant(position + Vector2(0.0, -44.0), "Niveau %d !" % niveau, Color(1.0, 0.9, 0.3))
		fx.eclat_etoiles(position, Color(1.0, 0.9, 0.3), 16)
		Audio.jouer("niveau")


## Secret ramassé : bonus permanent de PV max + expérience.
func bonus_secret() -> void:
	pv_max += 10.0
	pv = minf(pv + 30.0, pv_max)
	gagner_xp(xp_requise() * 0.35)


## Équipe l'objet s'il est meilleur que l'actuel, sinon le recycle en XP.
func recevoir_objet(objet: Dictionary) -> void:
	var actuel: Dictionary = arme if objet.emplacement == "arme" else armure
	if float(objet.valeur) > float(actuel.valeur):
		if objet.emplacement == "arme":
			arme = objet
		else:
			armure = objet
		fx.texte_flottant(position + Vector2(0.0, -40.0), str(objet.nom), ObjetLoot.COULEURS[int(objet.rarete)])
		Audio.jouer("ramasser")
	else:
		gagner_xp(6.0)
		fx.texte_flottant(position + Vector2(0.0, -34.0), "recyclé (+6 xp)", Color(0.75, 0.75, 0.75))

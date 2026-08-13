class_name Main
extends Node2D
## Point d'entrée du jeu : construit toutes les couches (monde, joueur, caméra,
## effets, interface) et relie leurs références entre elles.
## La logique est volontairement découpée par responsabilité (un script = un rôle)
## afin de pouvoir brancher le multijoueur v2 sans réécriture (voir reseau.gd).

var monde: Monde
var joueur: Joueur
var fx: FX
var hud: HUD
var camera: Camera2D


func _ready() -> void:
	_declarer_actions_clavier()

	# L'ordre d'ajout est l'ordre de dessin : le monde dessous,
	# le joueur au milieu, les effets au-dessus, l'interface tout en haut.
	monde = Monde.new()
	add_child(monde)

	joueur = Joueur.new()
	joueur.position = Vector2.ZERO # le sanctuaire central
	add_child(joueur)

	fx = FX.new()
	add_child(fx)

	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	joueur.add_child(camera)
	camera.make_current()

	hud = HUD.new()
	add_child(hud)

	# Câblage des références croisées. En v2 multijoueur, c'est ici que le
	# nœud Reseau s'insérera entre le monde (autorité) et les joueurs distants.
	monde.joueur = joueur
	monde.fx = fx
	monde.hud = hud
	joueur.monde = monde
	joueur.fx = fx
	joueur.hud = hud
	hud.joueur = joueur
	hud.monde = monde
	fx.camera = camera

	monde.demarrer()
	hud.message("Bienvenue dans les Terres d'Émeraude !", 3.0)


## Déclare les actions clavier en code (plus robuste qu'un fichier projet édité à la main).
## Les touches « physiques » WASD couvrent automatiquement ZQSD sur clavier AZERTY.
func _declarer_actions_clavier() -> void:
	_action("mv_gauche", [KEY_LEFT, KEY_A])
	_action("mv_droite", [KEY_RIGHT, KEY_D])
	_action("mv_haut", [KEY_UP, KEY_W])
	_action("mv_bas", [KEY_DOWN, KEY_S])
	_action("comp_tourbillon", [KEY_E])
	_action("comp_nova", [KEY_R])
	_action("comp_roulade", [KEY_SPACE])


func _action(nom: String, touches: Array) -> void:
	if InputMap.has_action(nom):
		return
	InputMap.add_action(nom)
	for t in touches:
		var ev := InputEventKey.new()
		ev.physical_keycode = t
		InputMap.action_add_event(nom, ev)

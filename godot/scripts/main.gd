class_name Main
extends Node2D
## Point d'entrée de l'arène « Chasse au dragon » : construit toutes les
## couches (arène, chasseurs, caméra, effets, interface) et câble leurs
## références. La logique est découpée par responsabilité (un script = un
## rôle) pour brancher le multijoueur v2 sans réécriture (voir reseau.gd).

## Personnages : Max (joueur) et les bots de la planche Eluminia.
const CHASSEURS := [
	{"nom": "Max", "teinte": Color(0.30, 0.75, 0.72), "joueur": true, "pos": Vector2(0.0, 360.0)},
	{"nom": "Zep", "teinte": Color(0.48, 0.25, 0.84), "joueur": false, "pos": Vector2(0.0, -360.0)},
	{"nom": "Nova", "teinte": Color(0.54, 0.44, 0.84), "joueur": false, "pos": Vector2(360.0, 180.0)},
	{"nom": "Ficelle", "teinte": Color(0.88, 0.52, 0.69), "joueur": false, "pos": Vector2(-360.0, 180.0)},
]

var arene: Arene
var joueur: Chasseur
var fx: FX
var hud: HUD
var camera: Camera2D


func _ready() -> void:
	_declarer_actions_clavier()

	# Ordre d'ajout = ordre de dessin : l'arène dessous, les chasseurs au
	# milieu, les effets au-dessus, l'interface tout en haut.
	arene = Arene.new()
	add_child(arene)

	fx = FX.new()

	for def in CHASSEURS:
		var c := Chasseur.new()
		c.arene = arene
		c.configurer(def.nom, def.teinte, def.joueur, def.pos)
		arene.add_child(c)
		arene.chasseurs.append(c)
		if def.joueur:
			joueur = c
	add_child(fx)

	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	joueur.add_child(camera)
	camera.make_current()

	hud = HUD.new()
	add_child(hud)

	# Câblage des références croisées. En v2 multijoueur, le nœud Reseau
	# s'insérera ici entre l'arène (autorité) et les chasseurs distants.
	arene.fx = fx
	arene.hud = hud
	arene.joueur = joueur
	joueur.hud = hud
	hud.joueur = joueur
	hud.arene = arene
	fx.camera = camera

	arene.demarrer()
	hud.toast("Attrape le dragon et dépose-le dans la zone de TA réponse !")


## Déclare les actions clavier en code (plus robuste qu'un fichier projet
## édité à la main). Les touches « physiques » WASD couvrent automatiquement
## ZQSD sur clavier AZERTY.
func _declarer_actions_clavier() -> void:
	_action("mv_gauche", [KEY_LEFT, KEY_A])
	_action("mv_droite", [KEY_RIGHT, KEY_D])
	_action("mv_haut", [KEY_UP, KEY_W])
	_action("mv_bas", [KEY_DOWN, KEY_S])
	_action("comp_onde", [KEY_E])
	_action("comp_dash", [KEY_R])
	_action("comp_bouclier", [KEY_SPACE])
	_action("rep_1", [KEY_1, KEY_KP_1])
	_action("rep_2", [KEY_2, KEY_KP_2])
	_action("rep_3", [KEY_3, KEY_KP_3])
	_action("rep_4", [KEY_4, KEY_KP_4])


func _action(nom: String, touches: Array) -> void:
	if InputMap.has_action(nom):
		return
	InputMap.add_action(nom)
	for t in touches:
		var ev := InputEventKey.new()
		ev.physical_keycode = t
		InputMap.action_add_event(nom, ev)

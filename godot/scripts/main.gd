class_name Jeu
extends Node3D
## Scène de jeu 3D : caméra isométrique orthographique (le style validé du
## spike), ambiance bonbon (ciel dégradé, soleil + ombres, glow), arène,
## chasseurs, effets et interface. Chaque couche est câblée ici — en v2
## multijoueur, le nœud Reseau s'insérera entre l'arène et les chasseurs.

## Les quatre Lumins ; le joueur incarne celui choisi dans le lobby
## (Profil.personnage), les autres deviennent les bots. Positions du spike.
const NOMS := ["Max", "Zep", "Nova", "Ficelle"]
const POSTES := [Vector2(0.0, 6.0), Vector2(0.0, -6.0), Vector2(6.0, 3.0), Vector2(-6.0, 3.0)]

## Recul isométrique de la caméra par rapport au héros.
const DECALAGE_CAMERA := Vector3(14.0, 17.0, 14.0)

var arene: Arene
var joueur: Chasseur
var fx: FX
var hud: HUD
var camera: Camera3D
var _cible_camera := Vector3.ZERO


func _ready() -> void:
	declarer_actions_clavier()
	Ambiance.installer(self)

	arene = Arene.new()
	add_child(arene)

	fx = FX.new()
	add_child(fx)

	# Le Lumin choisi au lobby en premier (joueur), les autres en bots —
	# chacun avec sa variante de couleur de la garde-robe.
	var noms: Array = NOMS.duplicate()
	noms.erase(Profil.personnage)
	noms.insert(0, Profil.personnage)
	for i in noms.size():
		var nom: String = noms[i]
		var c := Chasseur.new()
		c.arene = arene
		c.configurer(nom, Profil.couleur_de(nom), i == 0, POSTES[i])
		arene.add_child(c)
		arene.chasseurs.append(c)
		if i == 0:
			joueur = c

	# Caméra isométrique orthographique — angle du spike, ne pas changer
	# sans demande explicite de Camille.
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 14.5
	add_child(camera)
	_cible_camera = joueur.position
	camera.position = _cible_camera + DECALAGE_CAMERA
	camera.look_at(_cible_camera)
	camera.current = true

	hud = HUD.new()
	add_child(hud)

	# Câblage des références croisées.
	arene.fx = fx
	arene.hud = hud
	arene.joueur = joueur
	joueur.hud = hud
	hud.joueur = joueur
	hud.arene = arene
	hud.camera = camera
	fx.camera = camera

	arene.demarrer()
	hud.toast("Attrape le dragon et dépose-le dans la zone de TA réponse !")


func _process(delta: float) -> void:
	# Suivi lissé du héros (le look_at initial fixe l'angle une fois pour toutes).
	_cible_camera = _cible_camera.lerp(joueur.position, minf(delta * 6.0, 1.0))
	camera.position = _cible_camera + DECALAGE_CAMERA


## Déclare les actions clavier en code (statique : le menu l'appelle aussi).
## Les touches « physiques » WASD couvrent automatiquement ZQSD sur AZERTY.
static func declarer_actions_clavier() -> void:
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


static func _action(nom: String, touches: Array) -> void:
	if InputMap.has_action(nom):
		return
	InputMap.add_action(nom)
	for t in touches:
		var ev := InputEventKey.new()
		ev.physical_keycode = t
		InputMap.action_add_event(nom, ev)

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
var _boussole: Node3D            ## flèche 3D qui pointe le dragon en continu
var _mat_boussole: StandardMaterial3D


func _ready() -> void:
	declarer_actions_clavier()
	# Thème d'ambiance du match, tiré au sort (variété des arènes).
	var noms_themes: Array = Ambiance.THEMES.keys()
	var theme: Dictionary = Ambiance.THEMES[noms_themes[randi() % noms_themes.size()]]
	Ambiance.installer(self, theme)

	arene = Arene.new()
	arene.theme = theme
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

	# Boussole du dragon : une flèche qui tourne autour du héros et pointe
	# le dragon en permanence — dorée s'il est libre, rouge s'il est porté
	# par un adversaire, éteinte quand C'EST TOI qui le portes.
	_boussole = Node3D.new()
	add_child(_boussole)
	var pointe := Materiaux.mesh(_boussole, Materiaux.cone(0.3, 0.85),
		Materiaux.emissif(Identite.OR, 2.2), Vector3.ZERO, Vector3.ONE, false)
	pointe.rotation_degrees = Vector3(0.0, 0.0, -90.0) # le cône pointe vers +X
	_mat_boussole = pointe.material_override

	arene.demarrer()
	hud.toast("Attrape le dragon et dépose-le dans la zone de TA réponse !")

	# Crochet de dev (captures et tests de rendu automatisés) :
	# ILUMINIA_DEMO="eveil" → Éveil élevé + Super prêt ;
	# ILUMINIA_DEMO="supers" → passe en JEU et déclenche les 4 Supers.
	match OS.get_environment("ILUMINIA_DEMO"):
		"eveil":
			for c in arene.chasseurs:
				if not c.est_joueur:
					c.eveil = 2
					c.visuel.fixer_eveil(2)
			joueur.eveil = 2
			joueur.visuel.fixer_eveil(2)
			joueur.monter_eveil()
			joueur.charger_super(Chasseur.COUT_SUPER)
		"supers":
			arene._lancer_jeu()
			for c in arene.chasseurs:
				c.charger_super(Chasseur.COUT_SUPER)
				c.utiliser_super()


func _process(delta: float) -> void:
	# Suivi lissé du héros (le look_at initial fixe l'angle une fois pour toutes).
	_cible_camera = _cible_camera.lerp(joueur.position, minf(delta * 6.0, 1.0))
	camera.position = _cible_camera + DECALAGE_CAMERA
	# Boussole du dragon.
	var dr := arene.dragon
	var actif: bool = arene.etat == Arene.Etat.JEU and dr != null \
		and dr.porteur != joueur and joueur.pos2().distance_to(dr.pos2()) > 3.0
	_boussole.visible = actif
	if actif:
		var d2 := (dr.pos2() - joueur.pos2()).normalized()
		var t := Time.get_ticks_msec() / 1000.0
		_boussole.position = joueur.position + Vector3(d2.x * 2.1, 1.1 + sin(t * 4.0) * 0.12, d2.y * 2.1)
		_boussole.rotation.y = atan2(-d2.y, d2.x)
		var teinte := Identite.OR if dr.libre() else Identite.ROUGE
		_mat_boussole.albedo_color = teinte
		_mat_boussole.emission = teinte


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
	_action("comp_super", [KEY_F])
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

class_name Menu
extends Node3D
## Écran d'accueil d'Iluminia — la nuit lumineuse : une petite île
## flottante en diorama, les quatre Lumins avec leurs crêtes-lumières, le
## bébé dragon qui vole en cercle, des lucioles — et l'interface de la
## planche ILLUMINIA : logo étoilé doré, gros bouton JOUER pulsé.

var _dragon_pivot: Node3D
var _dragon: Personnage3D
var _persos: Array = []
var _t := 0.0
var _lancement := false
var surface: Control


func _ready() -> void:
	Jeu.declarer_actions_clavier()
	Ambiance.installer(self)

	# — Île de nuit : pelouse sombre, lisière-lumière, falaise, cristaux —
	Materiaux.mesh(self, Materiaux.cylindre(9.0, 0.3), Materiaux.toon(Identite.PELOUSE_NUIT),
		Vector3(0.0, -0.15, 0.0), Vector3.ONE, false)
	Materiaux.mesh(self, Materiaux.tore(9.1, 0.12), Materiaux.emissif(Identite.LUEUR_LISIERE, 1.4),
		Vector3(0.0, 0.05, 0.0), Vector3.ONE, false)
	var falaise := CylinderMesh.new()
	falaise.top_radius = 9.4
	falaise.bottom_radius = 1.6
	falaise.height = 8.0
	falaise.radial_segments = 24
	Materiaux.mesh(self, falaise, Materiaux.toon(Identite.ROCHE), Vector3(0.0, -4.3, 0.0), Vector3.ONE, false)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 20:
		var p := Vector2.from_angle(rng.randf_range(0.0, TAU)) * rng.randf_range(2.5, 8.4)
		var teinte: Color = [Identite.OR, Identite.CYAN, Identite.MAGENTA][rng.randi() % 3]
		Materiaux.mesh(self, Materiaux.sphere(0.1), Materiaux.emissif(teinte, 1.3),
			Vector3(p.x, 0.12, p.y), Vector3.ONE, false)
	for i in 6:
		var ang := TAU * i / 6.0 + 0.3
		var p := Vector2.from_angle(ang) * 8.6
		var cristal := Materiaux.mesh(self, Materiaux.cone(0.22, rng.randf_range(0.7, 1.2)),
			Materiaux.emissif(Identite.CYAN if i % 2 == 0 else Identite.VIOLET, 1.3),
			Vector3(p.x, 0.3, p.y))
		cristal.rotation_degrees = Vector3(rng.randf_range(-12.0, 12.0), 0.0, rng.randf_range(-12.0, 12.0))
	# Lucioles du menu.
	var lucioles := CPUParticles3D.new()
	lucioles.amount = 24
	lucioles.lifetime = 7.0
	lucioles.preprocess = 7.0
	lucioles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	lucioles.emission_box_extents = Vector3(8.0, 1.5, 8.0)
	lucioles.direction = Vector3.UP
	lucioles.spread = 180.0
	lucioles.initial_velocity_min = 0.1
	lucioles.initial_velocity_max = 0.5
	lucioles.gravity = Vector3.ZERO
	var etincelle := SphereMesh.new()
	etincelle.radius = 0.05
	etincelle.height = 0.1
	etincelle.radial_segments = 6
	etincelle.rings = 3
	etincelle.material = Materiaux.emissif(Identite.CREME, 1.8)
	lucioles.mesh = etincelle
	lucioles.position = Vector3(0.0, 1.5, 0.0)
	add_child(lucioles)
	lucioles.emitting = true

	# — Les quatre Lumins en rang face à la caméra, derrière le bouton JOUER —
	var perpendiculaire := Vector3(-1.0, 0.0, 1.0).normalized()
	var vers_camera := Vector3(1.0, 0.0, 1.0).normalized()
	for i in Jeu.CHASSEURS.size():
		var def: Dictionary = Jeu.CHASSEURS[i]
		var perso := Personnage3D.new()
		perso.genre = "chasseur"
		perso.etiquette = def.nom
		perso.position = perpendiculaire * (i - 1.5) * 2.6 - vers_camera * 1.6
		add_child(perso)
		perso.regarder(Vector2(1.0, 1.0).normalized())
		_persos.append(perso)

	_dragon_pivot = Node3D.new()
	add_child(_dragon_pivot)
	_dragon = Personnage3D.new()
	_dragon.genre = "dragon"
	_dragon.couleur = Color(0.45, 0.82, 0.55)
	_dragon.position = Vector3(3.0, 2.6, 0.0)
	_dragon.regarder(Vector2(0.0, 1.0))
	_dragon_pivot.add_child(_dragon)

	# Caméra du diorama : même angle isométrique que le jeu.
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 10.5
	camera.position = Vector3(10.0, 11.0, 10.0)
	add_child(camera)
	camera.look_at(Vector3(0.0, 1.4, 0.0))
	camera.current = true

	# — Interface —
	var couche := CanvasLayer.new()
	add_child(couche)
	surface = SurfaceMenu.new()
	surface.menu = self
	surface.set_anchors_preset(Control.PRESET_FULL_RECT)
	couche.add_child(surface)


func _process(delta: float) -> void:
	_t += delta
	_dragon_pivot.rotation.y += delta * 0.5
	_dragon.position.y = 2.6 + sin(_t * 2.0) * 0.3
	_dragon.en_marche = true
	for i in _persos.size():
		var perso: Personnage3D = _persos[i]
		perso.en_marche = fmod(_t + i * 1.7, 5.0) < 1.2
	surface.queue_redraw()


func _input(event: InputEvent) -> void:
	if _lancement:
		return
	if event is InputEventScreenTouch and event.pressed:
		if surface != null and (surface as SurfaceMenu).rect_jouer.has_point(event.position):
			_jouer()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ENTER or event.physical_keycode == KEY_SPACE:
			_jouer()


func _jouer() -> void:
	_lancement = true
	Audio.jouer("clic")
	Audio.jouer("depart")
	get_tree().change_scene_to_file.call_deferred("res://scenes/jeu.tscn")


## L'interface du menu : logo étoilé + JOUER doré, composants ui.gd.
class SurfaceMenu extends Control:
	var menu: Menu = null
	var rect_jouer := Rect2()

	func _draw() -> void:
		var t := Time.get_ticks_msec() / 1000.0
		var centre_x := size.x / 2.0
		var ballant := sin(t * 1.6) * 4.0
		# — Logo : étoile-couronne dorée à ailes bleues (planche), titre or —
		var haut := size.y * 0.16 + ballant
		for cote: float in [-1.0, 1.0]:
			c_aile(Vector2(centre_x + cote * 34.0, haut - 58.0), cote)
		UI.etoile(self, Vector2(centre_x, haut - 62.0), 22.0, Identite.OR)
		UI.texte(self, Vector2(centre_x, haut), "ILUMINIA", 84, Identite.OR, true, 14)
		UI.texte(self, Vector2(centre_x, haut + 38.0), "La chasse au dragon", 26, Identite.MAGENTA, true)
		UI.texte(self, Vector2(centre_x, haut + 68.0), "Réponds • Attrape • Vole-le à tes amis !", 16,
			Color(0.9, 0.93, 1.0, 0.85), true, 5)
		# — Gros bouton JOUER doré pulsé —
		var pulse := 1.0 + 0.045 * sin(t * 4.5)
		var bl := 300.0 * pulse
		var bh := 84.0 * pulse
		rect_jouer = Rect2(Vector2(centre_x - bl / 2.0, size.y * 0.76 - bh / 2.0), Vector2(bl, bh))
		UI.bouton(self, rect_jouer, Identite.OR, "jouer", false, Identite.RAYON_LG + 4)
		UI.texte(self, Vector2(centre_x, rect_jouer.position.y + rect_jouer.size.y / 2.0 + 12.0),
			"JOUER !", 36, Identite.TEXTE, true, 10)
		# — Aide contrôles —
		UI.texte(self, Vector2(centre_x, size.y - 18.0),
			"Mobile : joystick au pouce + boutons  •  Clavier : ZQSD, E/R/Espace, réponses 1-4", 14,
			Color(1.0, 1.0, 1.0, 0.7), true, 5)

	## Petite aile bleue du logo (triangle étagé).
	func c_aile(pos: Vector2, cote: float) -> void:
		for i in 3:
			var l := 18.0 - i * 5.0
			draw_colored_polygon(PackedVector2Array([
				pos + Vector2(cote * (10.0 + i * 12.0), -4.0 + i * 5.0),
				pos + Vector2(cote * (10.0 + i * 12.0 + l), 2.0 + i * 5.0),
				pos + Vector2(cote * (10.0 + i * 12.0), 8.0 + i * 5.0),
			]), Identite.BLEU if i % 2 == 0 else Identite.CYAN)

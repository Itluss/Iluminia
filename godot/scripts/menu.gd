class_name Menu
extends Node3D
## Écran d'accueil « mobile premium » (référence Clash Royale) : diorama 3D
## animé (les quatre chasseurs autour du bébé dragon qui vole en cercle),
## logo doré à gros contour, énorme bouton JOUER qui pulse, panneau des
## personnages. Un toucher n'importe où sur le bouton lance la partie.

var _dragon_pivot: Node3D
var _dragon: Personnage3D
var _persos: Array = []
var _t := 0.0
var _lancement := false
var surface: Control


func _ready() -> void:
	Jeu.declarer_actions_clavier()
	Ambiance.installer(self)

	# — Diorama : pelouse ronde, fleurs, personnages en arc, dragon en vol —
	Materiaux.mesh(self, Materiaux.cylindre(9.0, 0.3), Materiaux.toon(Color(0.55, 0.83, 0.45)),
		Vector3(0.0, -0.15, 0.0), Vector3.ONE, false)
	Materiaux.mesh(self, Materiaux.cylindre(9.5, 0.3), Materiaux.toon(Color(0.20, 0.16, 0.26)),
		Vector3(0.0, -0.25, 0.0), Vector3.ONE, false)
	Materiaux.mesh(self, Materiaux.cylindre(30.0, 0.3), Materiaux.toon(Color(0.30, 0.52, 0.30)),
		Vector3(0.0, -0.32, 0.0), Vector3.ONE, false)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 26:
		var p := Vector2.from_angle(rng.randf_range(0.0, TAU)) * rng.randf_range(2.5, 8.4)
		var teinte := Color(1.0, 0.6, 0.75) if rng.randf() < 0.5 else Color(1.0, 0.85, 0.4)
		Materiaux.mesh(self, Materiaux.sphere(0.12), Materiaux.emissif(teinte, 0.6),
			Vector3(p.x, 0.12, p.y), Vector3.ONE, false)

	# Les quatre héros en rang face à la caméra, derrière le bouton JOUER.
	var perpendiculaire := Vector3(-1.0, 0.0, 1.0).normalized()
	var vers_camera := Vector3(1.0, 0.0, 1.0).normalized()
	for i in Jeu.CHASSEURS.size():
		var def: Dictionary = Jeu.CHASSEURS[i]
		var perso := Personnage3D.new()
		perso.genre = "chasseur"
		perso.couleur = def.teinte
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

	# Caméra du diorama : même angle isométrique que le jeu, un peu basse.
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
	# Le dragon tourne en volant, avec un petit ballant vertical.
	_dragon_pivot.rotation.y += delta * 0.5
	_dragon.position.y = 2.6 + sin(_t * 2.0) * 0.3
	_dragon.en_marche = true
	# Les personnages se dandinent chacun à leur rythme.
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


## Toute l'interface du menu, dessinée façon « jeu mobile premium ».
class SurfaceMenu extends Control:
	const CONTOUR := Color(0.10, 0.08, 0.16)
	const OR := Color(1.0, 0.8, 0.25)
	var menu: Menu = null
	var rect_jouer := Rect2()
	var _styles := {}

	func _style(cle: String, fond: Color, bord: Color, rayon := 16, epaisseur := 4, ombre := 6) -> StyleBoxFlat:
		if _styles.has(cle):
			return _styles[cle]
		var sb := StyleBoxFlat.new()
		sb.bg_color = fond
		sb.border_color = bord
		sb.set_border_width_all(epaisseur)
		sb.set_corner_radius_all(rayon)
		sb.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
		sb.shadow_size = ombre
		sb.shadow_offset = Vector2(0.0, 4.0)
		_styles[cle] = sb
		return sb

	func _texte(pos: Vector2, texte: String, taille: int, teinte: Color, contour_taille := 8) -> void:
		var police := ThemeDB.fallback_font
		var p := pos - Vector2(police.get_string_size(texte, HORIZONTAL_ALIGNMENT_LEFT, -1, taille).x / 2.0, 0.0)
		draw_string_outline(police, p, texte, HORIZONTAL_ALIGNMENT_LEFT, -1, taille, contour_taille, CONTOUR)
		draw_string(police, p, texte, HORIZONTAL_ALIGNMENT_LEFT, -1, taille, teinte)

	func _draw() -> void:
		var t := Time.get_ticks_msec() / 1000.0
		var centre_x := size.x / 2.0
		# — Logo : ILUMINIA en or, sous-titre, léger ballant —
		var ballant := sin(t * 1.6) * 4.0
		_texte(Vector2(centre_x, size.y * 0.17 + ballant), "ILUMINIA", 84, OR, 14)
		_texte(Vector2(centre_x, size.y * 0.17 + 40.0 + ballant), "La chasse au dragon", 26, Color.WHITE)
		# — Bandeau pédagogique discret —
		_texte(Vector2(centre_x, size.y * 0.17 + 72.0 + ballant), "Réponds • Attrape • Vole-le à tes amis !", 16, Color(0.9, 0.93, 1.0, 0.85))
		# — Gros bouton JOUER doré qui pulse —
		var pulse := 1.0 + 0.045 * sin(t * 4.5)
		var bl := 300.0 * pulse
		var bh := 84.0 * pulse
		rect_jouer = Rect2(Vector2(centre_x - bl / 2.0, size.y * 0.76 - bh / 2.0), Vector2(bl, bh))
		draw_style_box(_style("jouer", OR, Color(0.62, 0.44, 0.08), 26, 5, 8), rect_jouer)
		draw_style_box(_style("gloss", Color(1.0, 1.0, 1.0, 0.16), Color(0, 0, 0, 0), 16, 0, 0),
			Rect2(rect_jouer.position + Vector2(10.0, 6.0), Vector2(rect_jouer.size.x - 20.0, rect_jouer.size.y * 0.42)))
		_texte(Vector2(centre_x, rect_jouer.position.y + rect_jouer.size.y / 2.0 + 12.0), "JOUER !", 36, Color.WHITE, 10)
		# — Aide contrôles en bas —
		_texte(Vector2(centre_x, size.y - 18.0),
			"Mobile : joystick au pouce + boutons  •  Clavier : ZQSD, E/R/Espace, réponses 1-4", 14,
			Color(1.0, 1.0, 1.0, 0.7), 5)

class_name FX
extends Node2D
## Effets « game feel » : chiffres de dégâts flottants à contour, éclats
## d'étoiles, anneaux d'onde de choc, arcs d'épée et secousse d'écran.
## Chaque effet est un petit nœud autonome qui se détruit tout seul.

var camera: Camera2D
var _trauma := 0.0 ## intensité de secousse (décroît toute seule)


func _process(delta: float) -> void:
	if camera != null:
		_trauma = maxf(_trauma - delta * 2.2, 0.0)
		var force := _trauma * _trauma * 16.0
		camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * force


## Secousse d'écran légère (0.2) à forte (1.0).
func secousse(intensite: float) -> void:
	_trauma = minf(_trauma + intensite, 1.0)


func texte_flottant(pos: Vector2, texte: String, teinte: Color) -> void:
	var n := TexteFlottant.new()
	n.texte = texte
	n.teinte = teinte
	n.position = pos
	add_child(n)


func eclat_etoiles(pos: Vector2, teinte: Color, nombre := 8) -> void:
	for i in nombre:
		var e := Etoile.new()
		e.position = pos
		e.velocite = Vector2.from_angle(randf_range(0.0, TAU)) * randf_range(60.0, 220.0)
		e.teinte = teinte
		add_child(e)


func anneau(pos: Vector2, rayon_max: float, teinte: Color) -> void:
	var a := Anneau.new()
	a.position = pos
	a.rayon_max = rayon_max
	a.teinte = teinte
	add_child(a)


## Éclair conique de l'Onde de choc (l'arc blanc = limite de portée).
func cone(pos: Vector2, angle: float, portee: float, demi_cone: float) -> void:
	var s := ConeOnde.new()
	s.position = pos
	s.angle_cone = angle
	s.portee = portee
	s.demi_cone = demi_cone
	add_child(s)


## Petit rond de traînée (dash) qui s'estompe sur place.
func traine(pos: Vector2, teinte: Color) -> void:
	var t := Traine.new()
	t.position = pos
	t.teinte = teinte
	add_child(t)


## Chiffre (ou mot) qui monte et s'efface, avec gros contour lisible.
class TexteFlottant extends Node2D:
	const DUREE := 0.9
	var texte := ""
	var teinte := Color.WHITE
	var _vie := 0.0

	func _process(delta: float) -> void:
		_vie += delta
		position.y -= 46.0 * delta
		if _vie >= DUREE:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var police := ThemeDB.fallback_font
		var alpha := clampf(1.6 - _vie / DUREE * 1.6, 0.0, 1.0)
		var taille := 19
		var largeur := police.get_string_size(texte, HORIZONTAL_ALIGNMENT_LEFT, -1, taille).x
		var p := Vector2(-largeur / 2.0, 0.0)
		draw_string_outline(police, p, texte, HORIZONTAL_ALIGNMENT_LEFT, -1, taille, 6,
			Color(0.13, 0.10, 0.16, alpha))
		draw_string(police, p, texte, HORIZONTAL_ALIGNMENT_LEFT, -1, taille,
			Color(teinte.r, teinte.g, teinte.b, alpha))


## Particule en étoile à cinq branches qui file puis freine.
class Etoile extends Node2D:
	const DUREE := 0.55
	var velocite := Vector2.ZERO
	var teinte := Color.WHITE
	var _vie := 0.0

	func _process(delta: float) -> void:
		_vie += delta
		position += velocite * delta
		velocite *= pow(0.05, delta) # frottement exponentiel
		if _vie >= DUREE:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var a := clampf(1.0 - _vie / DUREE, 0.0, 1.0)
		var r := 7.0 * a + 2.0
		var pts := PackedVector2Array()
		for i in 10:
			var rayon := r if i % 2 == 0 else r * 0.45
			pts.append(Vector2.from_angle(TAU * i / 10.0 + _vie * 6.0) * rayon)
		draw_colored_polygon(pts, Color(teinte.r, teinte.g, teinte.b, a))


## Onde de choc circulaire des compétences de zone.
class Anneau extends Node2D:
	const DUREE := 0.35
	var rayon_max := 100.0
	var teinte := Color.WHITE
	var _vie := 0.0

	func _process(delta: float) -> void:
		_vie += delta
		if _vie >= DUREE:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var t := clampf(_vie / DUREE, 0.0, 1.0)
		var r := rayon_max * (1.0 - (1.0 - t) * (1.0 - t)) # sortie amortie
		var a := 1.0 - t
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(0.13, 0.10, 0.16, a * 0.8), 14.0)
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(teinte.r, teinte.g, teinte.b, a), 8.0)


## Cône éclair de l'Onde de choc : arcs qui s'étendent jusqu'à la portée.
class ConeOnde extends Node2D:
	const DUREE := 0.22
	var angle_cone := 0.0
	var portee := 192.0
	var demi_cone := 0.68
	var _vie := 0.0

	func _process(delta: float) -> void:
		_vie += delta
		if _vie >= DUREE:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var t := clampf(_vie / DUREE, 0.0, 1.0)
		var a := 1.0 - t
		# Trois arcs successifs qui gonflent vers la limite de portée.
		for i in 3:
			var r := portee * (0.35 + 0.65 * t) * (0.55 + 0.225 * i)
			draw_arc(Vector2.ZERO, r, angle_cone - demi_cone, angle_cone + demi_cone,
				14, Color(1.0, 1.0, 0.95, a * (0.9 - 0.2 * i)), 8.0 - 2.0 * i)
		# L'arc blanc de limite de portée.
		draw_arc(Vector2.ZERO, portee, angle_cone - demi_cone, angle_cone + demi_cone,
			16, Color(1.0, 1.0, 1.0, a * 0.5), 3.0)


## Rond de traînée du dash, s'estompe sur place.
class Traine extends Node2D:
	const DUREE := 0.3
	var teinte := Color(0.45, 0.9, 1.0)
	var _vie := 0.0

	func _process(delta: float) -> void:
		_vie += delta
		if _vie >= DUREE:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var a := (1.0 - _vie / DUREE) * 0.5
		draw_circle(Vector2.ZERO, 14.0 * (1.0 - _vie / DUREE) + 4.0, Color(teinte.r, teinte.g, teinte.b, a))

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


func coup_d_epee(pos: Vector2, angle: float) -> void:
	var s := ArcEpee.new()
	s.position = pos
	s.angle_coup = angle
	add_child(s)


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


## Arc de mêlée de l'auto-attaque, balayé dans la direction du coup.
class ArcEpee extends Node2D:
	const DUREE := 0.16
	var angle_coup := 0.0
	var _vie := 0.0

	func _process(delta: float) -> void:
		_vie += delta
		if _vie >= DUREE:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var t := clampf(_vie / DUREE, 0.0, 1.0)
		var a := 1.0 - t
		var balayage := lerpf(-0.9, 0.5, t)
		draw_arc(Vector2.ZERO, 46.0, angle_coup + balayage - 0.5, angle_coup + balayage + 0.5,
			12, Color(1.0, 1.0, 0.95, a * 0.9), 12.0 * a + 2.0)

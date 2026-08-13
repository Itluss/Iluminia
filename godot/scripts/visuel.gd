class_name VisuelCartoon
extends Node2D
## Dessin « cartoon » par code : formes vectorielles saturées, gros contours,
## petit trottinement animé — palette bonbon Eluminia. Chaque entité possède
## aussi un Sprite2D vide, prêt à recevoir un vrai sprite (assets/README.md).

const CONTOUR := Color(0.10, 0.08, 0.14)

var genre := "chasseur"     ## silhouette : "chasseur" ou "dragon"
var rayon := 16.0
var couleur := Color(0.35, 0.78, 0.75)
var regard := Vector2.RIGHT ## direction du regard (oriente yeux et détails)
var en_marche := false
var etiquette := ""         ## nom affiché au-dessus de la tête
var anneau_dore := false    ## anneau du porteur du dragon
var bulle := 0.0            ## bulle de protection (0 = aucune)
var bulle_teinte := Color(0.7, 0.45, 1.0)
var _t := 0.0
var _flash := 0.0


func _process(delta: float) -> void:
	_t += delta
	if _flash > 0.0:
		_flash = maxf(_flash - delta * 6.0, 0.0)
	queue_redraw()


## Éclair blanc à l'impact.
func flash() -> void:
	_flash = 1.0


## Écrase/étire la silhouette (squash & stretch) puis revient à la normale.
func squash(force := 0.25) -> void:
	scale = Vector2(1.0 + force, 1.0 - force)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _teinte() -> Color:
	return couleur.lerp(Color.WHITE, _flash)


func _draw() -> void:
	var saut := absf(sin(_t * 10.0)) * (3.0 if en_marche else 0.8)
	var p := Vector2(0.0, -saut)

	# Anneau doré du porteur du dragon, aux pieds.
	if anneau_dore:
		var r_anneau := rayon + 10.0 + sin(_t * 6.0) * 2.0
		draw_arc(Vector2(0.0, rayon * 0.5), r_anneau, 0.0, TAU, 40, Color(1.0, 0.8, 0.2, 0.9), 5.0)

	# Ombre portée.
	draw_circle(Vector2(0.0, rayon * 0.55), rayon * 0.85, Color(0.0, 0.0, 0.0, 0.18))

	match genre:
		"dragon":
			_dessiner_dragon(p)
		_:
			_dessiner_chasseur(p)

	# Bulle de protection (bouclier ou réapparition), par-dessus tout.
	if bulle > 0.0:
		var r_bulle := rayon + 14.0 + sin(_t * 8.0) * 1.5
		draw_circle(Vector2.ZERO, r_bulle, Color(bulle_teinte.r, bulle_teinte.g, bulle_teinte.b, 0.18 * bulle))
		draw_arc(Vector2.ZERO, r_bulle, 0.0, TAU, 40, Color(bulle_teinte.r, bulle_teinte.g, bulle_teinte.b, 0.8 * bulle), 3.0)

	# Étiquette de nom.
	if etiquette != "":
		var police := ThemeDB.fallback_font
		var largeur := police.get_string_size(etiquette, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		var p_nom := Vector2(-largeur / 2.0, -rayon - 16.0)
		draw_string_outline(police, p_nom, etiquette, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 5, CONTOUR)
		draw_string(police, p_nom, etiquette, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1.0, 1.0, 1.0, 0.9))


func _yeux(p: Vector2, ecart := 0.34) -> void:
	var dir := regard.normalized() if regard.length() > 0.01 else Vector2.RIGHT
	var perp := Vector2(-dir.y, dir.x)
	for cote: float in [-1.0, 1.0]:
		var oeil: Vector2 = p + dir * rayon * 0.38 + perp * cote * rayon * ecart + Vector2(0.0, -rayon * 0.18)
		draw_circle(oeil, rayon * 0.26, Color.WHITE)
		draw_circle(oeil + dir * rayon * 0.1, rayon * 0.13, CONTOUR)


## Petit héros encapuchonné (style planche Eluminia) coloré par personnage.
func _dessiner_chasseur(p: Vector2) -> void:
	var dir := regard.normalized() if regard.length() > 0.01 else Vector2.RIGHT
	var perp := Vector2(-dir.y, dir.x)
	# Pieds trottinants.
	for cote: float in [-1.0, 1.0]:
		var pied: Vector2 = Vector2(0.0, rayon * 0.6) + perp * cote * rayon * 0.4 \
			+ dir * sin(_t * 12.0 + cote * PI) * (4.0 if en_marche else 0.0)
		draw_circle(pied, rayon * 0.28, CONTOUR)
	# Corps.
	draw_circle(p, rayon + 3.0, CONTOUR)
	draw_circle(p, rayon, _teinte())
	draw_circle(p + Vector2(0.0, rayon * 0.3), rayon * 0.55, _teinte().lightened(0.22))
	# Capuche : croissant clair sur le haut du crâne.
	draw_arc(p, rayon * 0.85, PI + 0.4, TAU - 0.4, 16, _teinte().lightened(0.45), 6.0)
	_yeux(p)


## Bébé dragon tout rond : ailes battantes, cornes, grands yeux, queue.
func _dessiner_dragon(p: Vector2) -> void:
	var dir := regard.normalized() if regard.length() > 0.01 else Vector2.RIGHT
	var perp := Vector2(-dir.y, dir.x)
	var bat := sin(_t * 6.0) * 0.3
	# Ailes.
	for cote: float in [-1.0, 1.0]:
		var attache: Vector2 = p + perp * cote * rayon * 0.5 + Vector2(0.0, -rayon * 0.2)
		var bout: Vector2 = attache + perp * cote * rayon * (1.0 + bat) + Vector2(0.0, -rayon * (0.7 + bat))
		draw_colored_polygon(PackedVector2Array([
			attache, bout, attache + perp * cote * rayon * 0.7 + Vector2(0.0, rayon * 0.2),
		]), CONTOUR)
		draw_colored_polygon(PackedVector2Array([
			attache + Vector2(0.0, 2.0), bout + Vector2(0.0, 5.0),
			attache + perp * cote * rayon * 0.55 + Vector2(0.0, rayon * 0.2),
		]), couleur.darkened(0.2))
	# Queue.
	var queue: Vector2 = p - dir * rayon * 1.1 + Vector2(0.0, sin(_t * 4.0) * 2.0)
	draw_line(p - dir * rayon * 0.5, queue, CONTOUR, 6.0)
	draw_colored_polygon(PackedVector2Array([
		queue + Vector2(0.0, -5.0), queue + Vector2(0.0, 5.0), queue - dir * 8.0,
	]), Color(1.0, 0.62, 0.3))
	# Corps.
	draw_circle(p, rayon + 3.0, CONTOUR)
	draw_circle(p, rayon, _teinte())
	draw_circle(p + Vector2(0.0, rayon * 0.35), rayon * 0.55, Color(0.95, 0.93, 0.7))
	# Cornes.
	for cote: float in [-1.0, 1.0]:
		var base: Vector2 = p + perp * cote * rayon * 0.4 + Vector2(0.0, -rayon * 0.75)
		draw_colored_polygon(PackedVector2Array([
			base + perp * cote * 4.0, base - perp * cote * 3.0, base + Vector2(0.0, -9.0),
		]), Color(0.95, 0.9, 0.75))
	# Grands yeux attendrissants.
	_yeux(p, 0.3)
	# Petites narines fumantes.
	draw_circle(p + dir * rayon * 0.85, 2.0, CONTOUR)

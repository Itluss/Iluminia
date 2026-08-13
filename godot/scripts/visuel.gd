class_name VisuelCartoon
extends Node2D
## Dessin « cartoon » par code : formes vectorielles saturées, gros contours,
## petite animation de trottinement. Chaque entité possède aussi un Sprite2D
## vide, prêt à recevoir un vrai sprite plus tard (voir assets/README.md).

const CONTOUR := Color(0.10, 0.08, 0.12)

var genre := "joueur"       ## silhouette à dessiner (joueur, sanglier, loup…)
var rayon := 16.0           ## taille de base du corps
var couleur := Color(0.30, 0.75, 0.42)
var regard := Vector2.RIGHT ## direction du regard (oriente yeux et détails)
var en_marche := false      ## anime le trottinement si vrai
var _t := 0.0               ## horloge d'animation
var _flash := 0.0           ## blanchit le corps quand touché


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
	# Petit rebond quand on marche, respiration légère sinon.
	var saut := absf(sin(_t * 10.0)) * (3.0 if en_marche else 0.8)
	var p := Vector2(0.0, -saut)

	# Ombre portée au sol (donne du volume, ancre le personnage).
	draw_circle(Vector2(0.0, rayon * 0.55), rayon * 0.85, Color(0.0, 0.0, 0.0, 0.18))

	match genre:
		"joueur":
			_corps(p)
			_details_joueur(p)
		"sanglier":
			_corps(p)
			_details_sanglier(p)
		"loup":
			_corps(p)
			_details_loup(p)
		"araignee":
			_details_araignee(p) # les pattes se dessinent sous le corps
			_corps(p)
			_yeux(p)
		"zombie":
			_corps(p)
			_details_zombie(p)
		"scorpion":
			_corps(p)
			_details_scorpion(p)
		"ogre":
			_corps(p)
			_details_ogre(p)
		"dragon":
			_details_ailes(p)
			_corps(p)
			_details_dragon(p)
		_:
			_corps(p)


## Corps générique : disque à gros contour + ventre clair + yeux.
func _corps(p: Vector2) -> void:
	draw_circle(p, rayon + 3.0, CONTOUR)
	draw_circle(p, rayon, _teinte())
	draw_circle(p + Vector2(0.0, rayon * 0.3), rayon * 0.55, _teinte().lightened(0.22))
	if genre != "araignee":
		_yeux(p)


func _yeux(p: Vector2) -> void:
	var dir := regard.normalized() if regard.length() > 0.01 else Vector2.RIGHT
	var perp := Vector2(-dir.y, dir.x)
	for cote: float in [-1.0, 1.0]:
		var oeil := p + dir * rayon * 0.38 + perp * cote * rayon * 0.34 + Vector2(0.0, -rayon * 0.18)
		draw_circle(oeil, rayon * 0.26, Color.WHITE)
		draw_circle(oeil + dir * rayon * 0.1, rayon * 0.13, CONTOUR)


func _details_joueur(p: Vector2) -> void:
	var dir := regard.normalized() if regard.length() > 0.01 else Vector2.RIGHT
	# Bandana de héros.
	draw_arc(p, rayon * 0.9, PI + 0.5, TAU - 0.5, 14, Color(0.85, 0.25, 0.25), 5.0)
	# Épée tenue sur le côté (pivotée avec le regard).
	var garde := p + dir.rotated(0.9) * (rayon + 2.0)
	var pointe := garde + dir.rotated(0.35) * (rayon * 1.15)
	draw_line(garde, pointe, CONTOUR, 7.0)
	draw_line(garde, pointe, Color(0.85, 0.88, 0.95), 3.5)
	draw_circle(garde, 4.0, Color(0.55, 0.36, 0.2))


func _details_sanglier(p: Vector2) -> void:
	var dir := regard.normalized() if regard.length() > 0.01 else Vector2.RIGHT
	# Groin.
	draw_circle(p + dir * rayon * 0.8, rayon * 0.3, Color(0.85, 0.6, 0.55))
	# Défenses blanches.
	var perp := Vector2(-dir.y, dir.x)
	for cote: float in [-1.0, 1.0]:
		var base := p + dir * rayon * 0.65 + perp * cote * rayon * 0.45
		draw_colored_polygon(PackedVector2Array([
			base, base + dir * 6.0 + perp * cote * 5.0, base + Vector2(0.0, -7.0),
		]), Color(0.96, 0.93, 0.85))
	# Oreilles.
	for cote: float in [-1.0, 1.0]:
		draw_circle(p + perp * cote * rayon * 0.75 + Vector2(0.0, -rayon * 0.5), rayon * 0.28, couleur.darkened(0.25))


func _details_loup(p: Vector2) -> void:
	var dir := regard.normalized() if regard.length() > 0.01 else Vector2.RIGHT
	var perp := Vector2(-dir.y, dir.x)
	# Oreilles pointues.
	for cote: float in [-1.0, 1.0]:
		var base := p + perp * cote * rayon * 0.55 + Vector2(0.0, -rayon * 0.55)
		draw_colored_polygon(PackedVector2Array([
			base + perp * cote * 5.0, base - perp * cote * 4.0, base + Vector2(0.0, -12.0),
		]), CONTOUR)
		draw_colored_polygon(PackedVector2Array([
			base + perp * cote * 3.0, base - perp * cote * 2.0, base + Vector2(0.0, -9.0),
		]), couleur.darkened(0.2))
	# Museau.
	draw_circle(p + dir * rayon * 0.75, rayon * 0.3, couleur.lightened(0.3))
	draw_circle(p + dir * rayon * 0.95, rayon * 0.12, CONTOUR)


func _details_araignee(p: Vector2) -> void:
	# Huit pattes animées.
	for i in 4:
		for cote: float in [-1.0, 1.0]:
			var ang := cote * (0.5 + i * 0.5) + sin(_t * 8.0 + i) * 0.08
			var pied := p + Vector2.from_angle(ang) * (rayon + 10.0) + Vector2(0.0, 4.0)
			var coude := p + Vector2.from_angle(ang) * rayon * 0.8 + Vector2(0.0, -5.0)
			draw_line(p, coude, CONTOUR, 3.5)
			draw_line(coude, pied, CONTOUR, 3.5)


func _details_zombie(p: Vector2) -> void:
	var dir := regard.normalized() if regard.length() > 0.01 else Vector2.RIGHT
	var perp := Vector2(-dir.y, dir.x)
	# Bras tendus devant (démarche classique de zombie).
	for cote: float in [-1.0, 1.0]:
		var epaule := p + perp * cote * rayon * 0.6
		var main := epaule + dir * (rayon * 1.1 + sin(_t * 6.0 + cote) * 2.0)
		draw_line(epaule, main, CONTOUR, 7.0)
		draw_line(epaule, main, couleur.darkened(0.15), 4.0)
	# Cicatrice.
	draw_line(p + Vector2(-4.0, -rayon * 0.5), p + Vector2(4.0, -rayon * 0.4), CONTOUR, 2.0)


func _details_scorpion(p: Vector2) -> void:
	var dir := regard.normalized() if regard.length() > 0.01 else Vector2.RIGHT
	var perp := Vector2(-dir.y, dir.x)
	# Pinces.
	for cote: float in [-1.0, 1.0]:
		var pince := p + dir * rayon * 0.8 + perp * cote * rayon * 0.7
		draw_circle(pince, rayon * 0.34 + 2.0, CONTOUR)
		draw_circle(pince, rayon * 0.34, couleur.darkened(0.15))
	# Queue recourbée au-dessus, avec dard.
	var haut := p - dir * rayon * 0.7 + Vector2(0.0, -rayon * 1.1)
	draw_line(p - dir * rayon * 0.6, haut, CONTOUR, 5.0)
	var dard := haut + dir * 8.0 + Vector2(0.0, sin(_t * 5.0) * 2.0)
	draw_line(haut, dard, CONTOUR, 4.0)
	draw_circle(dard, 3.5, Color(0.9, 0.3, 0.2))


func _details_ogre(p: Vector2) -> void:
	var dir := regard.normalized() if regard.length() > 0.01 else Vector2.RIGHT
	var perp := Vector2(-dir.y, dir.x)
	# Cornes.
	for cote: float in [-1.0, 1.0]:
		var base := p + perp * cote * rayon * 0.6 + Vector2(0.0, -rayon * 0.6)
		draw_colored_polygon(PackedVector2Array([
			base + perp * cote * 6.0, base - perp * cote * 4.0,
			base + perp * cote * 10.0 + Vector2(0.0, -14.0),
		]), Color(0.92, 0.88, 0.78))
	# Massue en bois.
	var poing := p + perp * rayon * 0.9
	var bout := poing + dir.rotated(0.5) * rayon * 1.1
	draw_line(poing, bout, Color(0.45, 0.3, 0.18), 8.0)
	draw_circle(bout, 9.0, CONTOUR)
	draw_circle(bout, 7.0, Color(0.5, 0.34, 0.2))


func _details_ailes(p: Vector2) -> void:
	# Battement d'ailes du dragon.
	var bat := sin(_t * 4.0) * 0.25
	for cote: float in [-1.0, 1.0]:
		var attache := p + Vector2(cote * rayon * 0.5, -rayon * 0.3)
		var bout := attache + Vector2(cote * rayon * 1.5, -rayon * (0.9 + bat))
		var creux := attache + Vector2(cote * rayon * 1.1, rayon * 0.2)
		draw_colored_polygon(PackedVector2Array([attache, bout, creux]), CONTOUR)
		draw_colored_polygon(PackedVector2Array([
			attache + Vector2(cote * 2.0, 2.0),
			bout + Vector2(-cote * 4.0, 6.0),
			creux + Vector2(-cote * 3.0, -2.0),
		]), couleur.darkened(0.3))


func _details_dragon(p: Vector2) -> void:
	var dir := regard.normalized() if regard.length() > 0.01 else Vector2.RIGHT
	var perp := Vector2(-dir.y, dir.x)
	# Cornes.
	for cote: float in [-1.0, 1.0]:
		var base := p + perp * cote * rayon * 0.45 + Vector2(0.0, -rayon * 0.7)
		draw_colored_polygon(PackedVector2Array([
			base + perp * cote * 7.0, base - perp * cote * 5.0,
			base + perp * cote * 6.0 + Vector2(0.0, -18.0),
		]), Color(0.95, 0.9, 0.75))
	# Museau + naseaux fumants.
	draw_circle(p + dir * rayon * 0.75, rayon * 0.32, couleur.lightened(0.15))
	for cote: float in [-1.0, 1.0]:
		var naseau := p + dir * rayon * 0.95 + perp * cote * rayon * 0.12
		draw_circle(naseau, 3.0, CONTOUR)
		var fume := naseau + dir * 10.0 + Vector2(0.0, -6.0 - fmod(_t * 20.0, 12.0))
		draw_circle(fume, 3.0, Color(0.6, 0.6, 0.6, 0.35))
	# Crête dorsale.
	for i in 3:
		var pos_crete := p - dir * rayon * (0.2 + i * 0.3)
		draw_colored_polygon(PackedVector2Array([
			pos_crete + Vector2(-5.0, 0.0), pos_crete + Vector2(5.0, 0.0),
			pos_crete + Vector2(0.0, -12.0),
		]), Color(0.95, 0.55, 0.15))

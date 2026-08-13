class_name Projectile
extends Node2D
## Projectile ennemi : trajectoire rectiligne, durée de vie limitée,
## touche le joueur au contact (sauf pendant la roulade — invincibilité).

var monde: Monde
var velocite := Vector2.ZERO
var degats := 5.0
var duree := 3.2
var teinte := Color(1.0, 0.6, 0.2)


func _process(delta: float) -> void:
	position += velocite * delta
	duree -= delta
	queue_redraw()
	if duree <= 0.0 or position.length() > Monde.RAYON_MONDE + 60.0:
		queue_free()
		return
	var j := monde.joueur
	if j.vivant and position.distance_to(j.position) < 22.0:
		j.subir_degats(degats)
		monde.fx.eclat_etoiles(position, teinte, 5)
		queue_free()


func _draw() -> void:
	# Traînée dans le sens inverse du déplacement.
	var arriere := -velocite.normalized()
	draw_circle(arriere * 8.0, 4.0, Color(teinte.r, teinte.g, teinte.b, 0.35))
	draw_circle(Vector2.ZERO, 9.0, Color(0.13, 0.10, 0.16))
	draw_circle(Vector2.ZERO, 6.5, teinte)
	draw_circle(Vector2.ZERO, 3.0, teinte.lightened(0.5))

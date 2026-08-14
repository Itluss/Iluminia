class_name FX
extends Node3D
## Effets « game feel » en 3D : éclats d'étoiles (particules), textes
## flottants (Label3D à contour), anneaux d'onde de choc, traînées de dash
## et secousse de caméra. Chaque effet se détruit tout seul.

var camera: Camera3D
var _trauma := 0.0


func _process(delta: float) -> void:
	if camera != null:
		_trauma = maxf(_trauma - delta * 2.2, 0.0)
		var force := _trauma * _trauma * 0.5
		camera.h_offset = randf_range(-1.0, 1.0) * force
		camera.v_offset = randf_range(-1.0, 1.0) * force


## Secousse d'écran légère (0.2) à forte (1.0).
func secousse(intensite: float) -> void:
	_trauma = minf(_trauma + intensite, 1.0)


## Position 3D d'un point logique du plan (x, z), à hauteur `h`.
static func en_3d(p: Vector2, h := 1.0) -> Vector3:
	return Vector3(p.x, h, p.y)


func texte_flottant(pos: Vector2, texte: String, teinte: Color) -> void:
	var l := Label3D.new()
	l.text = texte
	l.font_size = 72
	l.outline_size = 22
	l.modulate = teinte
	l.outline_modulate = Materiaux.COULEUR_CONTOUR
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.position = en_3d(pos, 1.6)
	add_child(l)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y + 1.4, 0.9)
	tw.tween_property(l, "modulate:a", 0.0, 0.9).set_ease(Tween.EASE_IN)
	tw.tween_property(l, "outline_modulate:a", 0.0, 0.9).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(l.queue_free)


## Éclat d'étoiles : particules émissives qui retombent.
func eclat_etoiles(pos: Vector2, teinte: Color, nombre := 8) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = nombre
	p.lifetime = 0.6
	p.direction = Vector3.UP
	p.spread = 75.0
	p.initial_velocity_min = 3.0
	p.initial_velocity_max = 6.5
	p.gravity = Vector3(0.0, -9.0, 0.0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	var forme := SphereMesh.new()
	forme.radius = 0.09
	forme.height = 0.18
	forme.radial_segments = 6
	forme.rings = 3
	forme.material = Materiaux.emissif(teinte, 2.2)
	p.mesh = forme
	p.position = en_3d(pos, 0.7)
	add_child(p)
	p.emitting = true
	get_tree().create_timer(1.4).timeout.connect(p.queue_free)


## Onde circulaire au sol (compétences, dépôts).
func anneau(pos: Vector2, rayon_max: float, teinte: Color) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = Materiaux.tore(1.0, 0.08)
	var mat := Materiaux.verre(teinte, 0.8, 2.0)
	mi.material_override = mat
	mi.position = en_3d(pos, 0.12)
	mi.scale = Vector3(0.3, 1.0, 0.3)
	add_child(mi)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(mi, "scale", Vector3(rayon_max, 1.0, rayon_max), 0.35) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.35)
	tw.chain().tween_callback(mi.queue_free)


## Cône de l'Onde de choc : demi-anneau qui s'étend + particules dirigées.
func cone(pos: Vector2, dir: Vector2, portee: float, teinte := Color(1.0, 0.95, 0.8)) -> void:
	anneau(pos, portee, teinte)
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 14
	p.lifetime = 0.35
	p.direction = Vector3(dir.x, 0.25, dir.y)
	p.spread = 32.0
	p.initial_velocity_min = portee * 2.2
	p.initial_velocity_max = portee * 3.2
	p.gravity = Vector3.ZERO
	var forme := SphereMesh.new()
	forme.radius = 0.07
	forme.height = 0.14
	forme.radial_segments = 6
	forme.rings = 3
	forme.material = Materiaux.emissif(teinte, 2.0)
	p.mesh = forme
	p.position = en_3d(pos, 0.8)
	add_child(p)
	p.emitting = true
	get_tree().create_timer(0.9).timeout.connect(p.queue_free)


## Petit nuage de poussière sous les pas (game feel de course).
func poussiere(pos: Vector2) -> void:
	var mi := MeshInstance3D.new()
	var forme := SphereMesh.new()
	forme.radius = 0.1
	forme.height = 0.2
	forme.radial_segments = 6
	forme.rings = 3
	mi.mesh = forme
	var mat := Materiaux.verre(Color(0.95, 0.95, 1.0), 0.4, 0.4)
	mi.material_override = mat
	mi.position = en_3d(pos + Vector2(randf_range(-0.15, 0.15), randf_range(-0.15, 0.15)), 0.08)
	add_child(mi)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(mi, "scale", Vector3.ONE * 2.2, 0.4)
	tw.tween_property(mi, "position:y", 0.35, 0.4)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.4)
	tw.chain().tween_callback(mi.queue_free)


## Rond de traînée du dash : petite sphère émissive qui s'estompe.
func traine(pos: Vector2, teinte: Color) -> void:
	var mi := MeshInstance3D.new()
	var forme := SphereMesh.new()
	forme.radius = 0.22
	forme.height = 0.44
	forme.radial_segments = 8
	forme.rings = 4
	mi.mesh = forme
	var mat := Materiaux.verre(teinte, 0.5, 1.6)
	mi.material_override = mat
	mi.position = en_3d(pos, 0.5)
	add_child(mi)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(mi, "scale", Vector3.ONE * 0.1, 0.3)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.3)
	tw.chain().tween_callback(mi.queue_free)

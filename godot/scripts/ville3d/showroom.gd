extends Node3D
## SHOWROOM DEV — l'outil de VALIDATION ARTISTIQUE d'Illuminia.
##
## Affiche un asset seul, sur fond neutre, avec l'éclairage réel du jeu,
## sur un plateau tournant. C'est ici qu'un asset candidat se juge avant
## d'entrer dans la ville : silhouette, proportions, matières, échelle.
##
## Crochets : ILUMINIA_ASSET (chemin du .glb), ILUMINIA_ANGLE (degrés).

func _ready() -> void:
	var chemin := OS.get_environment("ILUMINIA_ASSET")
	if chemin == "":
		chemin = "res://assets/artkit/genere/maison_aventuriers.glb"

	# Fond neutre : ni ciel, ni décor — rien qui flatte l'asset.
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.6, 0.68)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.7, 0.9)
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var soleil := DirectionalLight3D.new()
	soleil.rotation_degrees = Vector3(-45.0, -35.0, 0.0)
	soleil.light_color = Color(1.0, 0.95, 0.85)
	soleil.light_energy = 1.1
	soleil.shadow_enabled = true
	soleil.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	soleil.directional_shadow_max_distance = 20.0
	add_child(soleil)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25.0, 150.0, 0.0)
	fill.light_color = Color(0.65, 0.78, 1.0)
	fill.light_energy = 0.4
	add_child(fill)

	# Plateau : une simple dalle grise, repère d'échelle neutre.
	var plateau := MeshInstance3D.new()
	var disque := CylinderMesh.new()
	disque.top_radius = 3.0
	disque.bottom_radius = 3.0
	disque.height = 0.06
	plateau.mesh = disque
	var mp := StandardMaterial3D.new()
	mp.albedo_color = Color(0.72, 0.74, 0.78)
	plateau.mesh.material = mp
	plateau.position.y = -0.03
	add_child(plateau)

	# Repères d'échelle : une case du jeu = 1 unité (bâtonnets d'un mètre).
	for i in 3:
		var jalon := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.04, 1.0, 0.04)
		jalon.mesh = b
		var mj := StandardMaterial3D.new()
		mj.albedo_color = Color(0.95, 0.35, 0.3) if i % 2 == 0 else Color(0.95, 0.9, 0.85)
		jalon.mesh.material = mj
		jalon.position = Vector3(-1.5, i * 1.0 + 0.5, -1.5)
		add_child(jalon)

	var asset: Node3D = (load(chemin) as PackedScene).instantiate()
	asset.rotation_degrees.y = float(OS.get_environment("ILUMINIA_ANGLE"))
	add_child(asset)

	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 5.2
	add_child(cam)
	cam.position = Vector3(4.0, 3.4, 4.0)
	cam.look_at(Vector3(0.0, 1.3, 0.0))
	cam.current = true

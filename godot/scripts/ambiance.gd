class_name Ambiance
extends RefCounted
## Lumière et atmosphère partagées (jeu + menu) : ciel bonbon dégradé,
## soleil chaud avec ombres douces, lumière d'appoint froide, glow pour les
## éléments émissifs (colonnes de lumière, cristaux, orbes).


static func installer(parent: Node3D) -> void:
	# Ciel dégradé bleu → rose pâle à l'horizon.
	var ciel := ProceduralSkyMaterial.new()
	ciel.sky_top_color = Color(0.45, 0.68, 0.95)
	ciel.sky_horizon_color = Color(0.95, 0.82, 0.86)
	ciel.ground_bottom_color = Color(0.35, 0.55, 0.4)
	ciel.ground_horizon_color = Color(0.85, 0.8, 0.75)
	var sky := Sky.new()
	sky.sky_material = ciel

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.70, 0.75, 0.90)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	# Glow : fait briller zones, cristaux et effets (supporté par le rendu
	# Compatibility depuis Godot 4.3 ; sans effet ailleurs, jamais bloquant).
	# Seuil haut : seuls les émissifs brillent, jamais le sol éclairé.
	env.glow_enabled = true
	env.glow_intensity = 0.25
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.3

	var monde_env := WorldEnvironment.new()
	monde_env.environment = env
	parent.add_child(monde_env)

	# Soleil chaud avec ombres douces.
	var soleil := DirectionalLight3D.new()
	soleil.rotation_degrees = Vector3(-52.0, -32.0, 0.0)
	soleil.light_color = Color(1.0, 0.96, 0.88)
	soleil.light_energy = 0.95
	soleil.shadow_enabled = true
	soleil.directional_shadow_max_distance = 70.0
	parent.add_child(soleil)

	# Appoint froid opposé, sans ombre : débouche les zones sombres.
	var appoint := DirectionalLight3D.new()
	appoint.rotation_degrees = Vector3(-35.0, 140.0, 0.0)
	appoint.light_color = Color(0.7, 0.8, 1.0)
	appoint.light_energy = 0.25
	parent.add_child(appoint)

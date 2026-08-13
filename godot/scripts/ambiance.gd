class_name Ambiance
extends RefCounted
## L'atmosphère d'Iluminia : la NUIT LUMINEUSE (identite.gd).
## Ciel bleu marine dégradé vers un horizon violet, clair de lune froid
## avec ombres douces, appoint chaud discret, et un glow marqué : dans la
## nuit, tout ce qui est émissif (crêtes des Lumins, dragon, zones,
## cristaux, arbres-lanternes) brille vraiment.


static func installer(parent: Node3D) -> void:
	# Ciel de nuit : marine profond → horizon violet.
	var ciel := ProceduralSkyMaterial.new()
	ciel.sky_top_color = Identite.NUIT
	ciel.sky_horizon_color = Color(0.29, 0.21, 0.52)
	ciel.ground_bottom_color = Color(0.04, 0.05, 0.12)
	ciel.ground_horizon_color = Color(0.22, 0.16, 0.4)
	var sky := Sky.new()
	sky.sky_material = ciel

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.33, 0.38, 0.62)
	env.ambient_light_energy = 0.8
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	# La nuit fait vivre le glow : seuls les émissifs s'illuminent.
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.0

	var monde_env := WorldEnvironment.new()
	monde_env.environment = env
	parent.add_child(monde_env)

	# Clair de lune : froid, ombres douces.
	var lune := DirectionalLight3D.new()
	lune.rotation_degrees = Vector3(-52.0, -32.0, 0.0)
	lune.light_color = Color(0.78, 0.85, 1.0)
	lune.light_energy = 0.85
	lune.shadow_enabled = true
	lune.directional_shadow_max_distance = 70.0
	parent.add_child(lune)

	# Appoint chaud discret côté opposé (débouche les silhouettes).
	var appoint := DirectionalLight3D.new()
	appoint.rotation_degrees = Vector3(-35.0, 140.0, 0.0)
	appoint.light_color = Color(1.0, 0.8, 0.55)
	appoint.light_energy = 0.2
	parent.add_child(appoint)

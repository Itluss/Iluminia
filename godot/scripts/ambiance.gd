class_name Ambiance
extends RefCounted
## L'atmosphère d'Iluminia : la NUIT LUMINEUSE (identite.gd).
## Ciel bleu marine dégradé vers un horizon violet, clair de lune froid
## avec ombres douces, appoint chaud discret, et un glow marqué : dans la
## nuit, tout ce qui est émissif (crêtes des Lumins, dragon, zones,
## cristaux, arbres-lanternes) brille vraiment.


## Trois ambiances d'arène (variété des maps, façon Brawl Stars) : le thème
## est tiré au sort à chaque match. `pelouse`/`anneaux` teintent le sol.
const THEMES := {
	"Nuit lumineuse": {
		"ciel_haut": Identite.NUIT, "horizon": Color(0.29, 0.21, 0.52),
		"pelouse": Identite.PELOUSE_NUIT, "anneaux": Identite.PELOUSE_ANNEAU,
		"lisiere": Identite.CYAN,
	},
	"Crépuscule doré": {
		"ciel_haut": Color(0.10, 0.12, 0.30), "horizon": Color(0.85, 0.45, 0.25),
		"pelouse": Color(0.24, 0.32, 0.28), "anneaux": Color(0.30, 0.40, 0.32),
		"lisiere": Identite.OR,
	},
	"Aurore magenta": {
		"ciel_haut": Color(0.14, 0.08, 0.28), "horizon": Color(0.75, 0.25, 0.55),
		"pelouse": Color(0.20, 0.26, 0.38), "anneaux": Color(0.26, 0.33, 0.46),
		"lisiere": Identite.MAGENTA,
	},
}


static func installer(parent: Node3D, theme := {}) -> void:
	if theme.is_empty():
		theme = THEMES["Nuit lumineuse"]
	# Ciel : profond en haut → horizon coloré selon le thème.
	var ciel := ProceduralSkyMaterial.new()
	ciel.sky_top_color = theme.ciel_haut
	ciel.sky_horizon_color = theme.horizon
	ciel.ground_bottom_color = Color(0.04, 0.05, 0.12)
	ciel.ground_horizon_color = theme.horizon.darkened(0.3)
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

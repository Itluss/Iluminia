class_name Univers
extends RefCounted
## LA BIBLE GRAPHIQUE D'ILLUMINIA — source UNIQUE de l'univers visuel de
## la ville : palette, règles, éclairage. En changer une valeur, c'est
## changer l'univers partout, d'un seul geste.
##
## DIRECTION « JOUR ENCHANTÉ » : un monde chaleureux et lumineux — verts
## vivants, pierre claire, grand ciel bleu royal — traversé par la magie
## de la connaissance (cyan, or, violet) qui circule dans l'architecture.
## La barre : une capture doit sembler sortir d'un jeu mobile premium
## terminé, tout en restant immédiatement reconnaissable comme Illuminia.
##
## LES 7 RÈGLES (toute matière future les respecte) :
##  1. GROSSES FORMES d'abord — une silhouette doit se lire en noir pur.
##  2. 2-3 VALEURS par matière (base, ombre, accent) : jamais de dégradé
##     bruité, jamais de texture photo, jamais d'usure réaliste.
##  3. SATURATION pleine sur les ACCENTS (or, cyan, violet), retenue sur
##     les SURFACES — pour que les accents gagnent.
##  4. L'ÉMISSIF EST RESERVÉ à la magie de la connaissance : portails,
##     fenêtres d'étude, lanternes, cristaux. Si ça brille, ça a un SENS.
##  5. LUMIÈRE DORÉE, OMBRES BLEUES : le soleil est chaud, l'ombre est
##     colorée — jamais de blanc brûlé, jamais de gris sale.
##  6. LE MONDE EST SCULPTÉ : biseaux, retraits, strates, surplombs.
##     Une boîte brute est un placeholder, jamais un asset final.
##  7. LE VIDE EST UNE PROMESSE : props rares et espacés — le terrain
##     donne envie d'être rempli, jamais l'impression d'être plein.

## ------------------------------------------------------------- CHEMINS
const TERRAIN_ILE := "res://assets/artkit/terrain/terrain_ile.glb"


## --------------------------------------------------------- AMBIANCE 3D
## Le rig lumineux de la ville — soleil doré + fill bleu ciel + ambiance
## colorée + brume de profondeur. Construit ici pour que l'éclairage
## soit une donnée de la bible, pas un réglage dispersé.
static func installer_ambiance(parent: Node3D) -> void:
	var ciel_mat := ProceduralSkyMaterial.new()
	ciel_mat.sky_top_color = Color(0.16, 0.36, 0.86)
	ciel_mat.sky_horizon_color = Color(0.72, 0.86, 1.0)
	ciel_mat.sky_curve = 0.18
	ciel_mat.ground_bottom_color = Color(0.46, 0.62, 0.85)
	ciel_mat.ground_horizon_color = Color(0.72, 0.86, 1.0)
	var ciel := Sky.new()
	ciel.sky_material = ciel_mat

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = ciel
	# Ombres BLEUES : l'ambiance vient du ciel, pas d'un gris neutre.
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.72, 0.95)
	env.ambient_light_energy = 0.62
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 6.0
	# Le glow sert les émissifs magiques, discret sur le reste.
	env.glow_enabled = true
	env.glow_intensity = 0.32
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.05
	# Brume de profondeur : l'horizon respire (jamais un fond plat).
	env.fog_enabled = true
	env.fog_light_color = Color(0.75, 0.86, 1.0)
	env.fog_density = 0.004
	env.fog_sky_affect = 0.0
	# Saturation légèrement poussée : le rendu « jus » d'un jeu fini.
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.12
	env.adjustment_contrast = 1.03
	var monde := WorldEnvironment.new()
	monde.environment = env
	parent.add_child(monde)

	# SOLEIL DORÉ : la lumière principale, chaude, ombres douces.
	var soleil := DirectionalLight3D.new()
	soleil.rotation_degrees = Vector3(-48.0, -28.0, 0.0)
	soleil.light_color = Color(1.0, 0.93, 0.78)
	soleil.light_energy = 1.05
	soleil.shadow_enabled = true
	# Une seule cascade orthogonale : toute la précision de la shadow map
	# pour notre petite scène — c'est ELLE qui supprime l'acné en rayures.
	soleil.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	soleil.directional_shadow_max_distance = 40.0
	soleil.shadow_blur = 1.8
	soleil.shadow_bias = 0.06
	soleil.shadow_normal_bias = 2.2
	parent.add_child(soleil)

	# FILL bleu ciel opposé : débouche les ombres en couleur.
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-30.0, 148.0, 0.0)
	fill.light_color = Color(0.6, 0.74, 1.0)
	fill.light_energy = 0.38
	fill.shadow_enabled = false
	parent.add_child(fill)

	# Contre chaud rasant : sépare les silhouettes du fond.
	var contre := DirectionalLight3D.new()
	contre.rotation_degrees = Vector3(-16.0, 62.0, 0.0)
	contre.light_color = Color(1.0, 0.82, 0.6)
	contre.light_energy = 0.22
	contre.shadow_enabled = false
	parent.add_child(contre)


## Harmonise les matériaux d'une scène .glb importée avec le rendu toon
## du jeu (copies locales — jamais la ressource partagée).
static func harmoniser_gltf(racine: Node) -> void:
	for enfant in racine.find_children("*", "MeshInstance3D", true, false):
		var mi := enfant as MeshInstance3D
		if mi.mesh == null:
			continue
		for s in mi.mesh.get_surface_count():
			var m := mi.get_active_material(s)
			if m is StandardMaterial3D:
				var copie: StandardMaterial3D = m.duplicate()
				copie.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
				copie.specular_mode = BaseMaterial3D.SPECULAR_TOON
				mi.set_surface_override_material(s, copie)

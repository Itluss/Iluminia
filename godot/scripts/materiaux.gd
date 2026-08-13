class_name Materiaux
extends RefCounted
## Fabrique de matériaux « toon » : rendu bandé (diffuse/specular toon),
## contours peints par coque inversée (grow + cull front), émissifs pour
## les colonnes de lumière et cristaux — l'équivalent Godot du style validé
## sur le spike Three.js (MeshToonMaterial + inverted hull, palette bonbon).

const COULEUR_CONTOUR := Color(0.13, 0.09, 0.17)


static func toon(couleur: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = couleur
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode = BaseMaterial3D.SPECULAR_TOON
	m.roughness = 0.9
	m.metallic = 0.0
	return m


static func contour(epaisseur := 0.05) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = COULEUR_CONTOUR
	m.cull_mode = BaseMaterial3D.CULL_FRONT
	m.grow = true
	m.grow_amount = epaisseur
	return m


static func emissif(couleur: Color, energie := 1.8) -> StandardMaterial3D:
	var m := toon(couleur)
	m.emission_enabled = true
	m.emission = couleur
	m.emission_energy_multiplier = energie
	return m


## Matériau translucide lumineux (colonnes de lumière des zones, bulles).
static func verre(couleur: Color, alpha := 0.3, energie := 1.2) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(couleur.r, couleur.g, couleur.b, alpha)
	m.emission_enabled = true
	m.emission = couleur
	m.emission_energy_multiplier = energie
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.no_depth_test = false
	return m


## Ajoute une MeshInstance3D à `parent`, avec sa coque de contour peinte.
static func mesh(parent: Node3D, forme: Mesh, mat: Material, pos: Vector3,
		echelle := Vector3.ONE, avec_contour := true, epaisseur_contour := 0.05) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = forme
	mi.material_override = mat
	mi.position = pos
	mi.scale = echelle
	parent.add_child(mi)
	if avec_contour:
		var coque := MeshInstance3D.new()
		coque.mesh = forme
		coque.material_override = contour(epaisseur_contour)
		coque.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.add_child(coque)
	return mi


## Sphère basse résolution partagée (perfs mobiles).
static func sphere(rayon: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = rayon
	s.height = rayon * 2.0
	s.radial_segments = 24
	s.rings = 12
	return s


static func cone(rayon: float, hauteur: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = 0.0
	c.bottom_radius = rayon
	c.height = hauteur
	c.radial_segments = 16
	return c


static func cylindre(rayon: float, hauteur: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = rayon
	c.bottom_radius = rayon
	c.height = hauteur
	c.radial_segments = 24
	return c


## Anneau de rayon `rayon` et de demi-épaisseur `epaisseur`.
## (TorusMesh : inner_radius = rayon du trou, outer_radius = rayon extérieur.)
static func tore(rayon: float, epaisseur: float) -> TorusMesh:
	var t := TorusMesh.new()
	t.inner_radius = maxf(rayon - epaisseur, 0.01)
	t.outer_radius = rayon + epaisseur
	t.rings = 32
	t.ring_segments = 12
	return t

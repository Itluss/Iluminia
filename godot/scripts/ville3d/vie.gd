class_name Vie
extends Node
## LE MONDE VIVANT D'ILLUMINIA — le système commun de micro-animations.
##
## Un asset de l'art kit expose des NŒUDS NOMMÉS ; ce système les
## reconnaît et leur donne vie, sans que l'asset embarque le moindre
## script. Ajouter un bâtiment animé = nommer son nœud, rien de plus.
##
##   Portail / FenetresMagie / GemmeCyan → respiration lumineuse lente
##   Lanternes                           → vacillement chaud de flamme
##   Fanion                              → oscillation au vent
##   Ailes                               → rotation continue (moulin)
##   Engrenage                           → rotation saccadée (atelier)
##   Feuillage                           → balancement de vent (arbres)
##   Fumee                               → source de fumée stylisée
##
## RÈGLE : l'architecture ne bouge JAMAIS. Seuls bougent la lumière, le
## tissu, les mécanismes et le vivant — le bâti reste solide.

const RESPIRE := ["Portail", "FenetresMagie", "GemmeCyan", "Cristal"]
const FLAMME := ["Lanternes", "Braises"]


## Donne vie à tous les nœuds animables d'un modèle instancié.
static func animer(racine: Node3D) -> void:
	for nom in RESPIRE:
		for n in _tous(racine, nom):
			_respirer(n, 1.5 + float(nom.length() % 4) * 0.12, 0.3)
	for nom in FLAMME:
		for n in _tous(racine, nom):
			_respirer(n, 5.2, 0.5, 0.06)
	for n in _tous(racine, "Fanion"):
		_osciller(n, 0.11, 1.9)
	for n in _tous(racine, "Ailes"):
		_tourner(n, Vector3(0, 0, 1), 9.0)
	for n in _tous(racine, "Engrenage"):
		_tourner(n, Vector3(0, 0, 1), 4.5)
	for n in _tous(racine, "Feuillage"):
		_osciller(n, 0.045, 2.6, true)
	for n in _tous(racine, "Fumee"):
		_fumer(n)


static func _tous(racine: Node3D, nom: String) -> Array:
	var sortie: Array = []
	if racine.name.begins_with(nom):
		sortie.append(racine)
	for enfant in racine.find_children(nom + "*", "", true, false):
		sortie.append(enfant)
	return sortie


## RESPIRATION : l'émission monte et descend lentement — jamais de
## clignotement, jamais de disco. La magie « vit », elle ne clignote pas.
static func _respirer(noeud: Node, periode: float, amplitude: float,
		bruit := 0.0) -> void:
	var mi := noeud as MeshInstance3D
	if mi == null or mi.mesh == null:
		return
	for s in mi.mesh.get_surface_count():
		var m := mi.get_active_material(s)
		if not (m is StandardMaterial3D):
			continue
		var mat: StandardMaterial3D = m.duplicate()
		mat.emission_enabled = true
		mi.set_surface_override_material(s, mat)
		var base := mat.emission_energy_multiplier
		var pulse := Pulsation.new()
		pulse.materiau = mat
		pulse.base = maxf(base, 0.6)
		pulse.amplitude = amplitude
		pulse.vitesse = TAU / maxf(periode, 0.1)
		pulse.bruit = bruit
		pulse.phase = float(noeud.get_instance_id() % 100) * 0.06
		mi.add_child(pulse)


## OSCILLATION : un léger va-et-vient (tissu au vent, feuillage).
static func _osciller(noeud: Node3D, amplitude: float, periode: float,
		aussi_echelle := false) -> void:
	var osc := Oscillation.new()
	osc.cible = noeud
	osc.amplitude = amplitude
	osc.vitesse = TAU / maxf(periode, 0.1)
	osc.phase = float(noeud.get_instance_id() % 100) * 0.13
	osc.echelle = aussi_echelle
	noeud.add_child(osc)


static func _tourner(noeud: Node3D, axe: Vector3, periode: float) -> void:
	var rot := Rotation.new()
	rot.cible = noeud
	rot.axe = axe
	rot.vitesse = TAU / maxf(periode, 0.1)
	noeud.add_child(rot)


## FUMÉE STYLISÉE : des bouffées rondes qui montent, grossissent et
## s'effacent — un signe de vie visible de loin, très peu coûteux.
static func _fumer(ancre: Node3D) -> void:
	var f := Fumee.new()
	ancre.add_child(f)


# ─────────────────────────────────────────────── moteurs d'animation
class Pulsation extends Node:
	var materiau: StandardMaterial3D
	var base := 1.0
	var amplitude := 0.3
	var vitesse := 2.0
	var bruit := 0.0
	var phase := 0.0
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		var v := base + amplitude * (0.5 + 0.5 * sin(_t * vitesse + phase))
		if bruit > 0.0:
			v += bruit * sin(_t * 13.7 + phase * 3.0) * sin(_t * 7.3)
		materiau.emission_energy_multiplier = maxf(v, 0.0)


class Oscillation extends Node:
	var cible: Node3D
	var amplitude := 0.1
	var vitesse := 3.0
	var phase := 0.0
	var echelle := false
	var _t := 0.0
	var _base_rot := 0.0
	var _base_pos := Vector3.ZERO
	var _prete := false

	func _process(delta: float) -> void:
		if not _prete:
			_base_rot = cible.rotation.z
			_base_pos = cible.position
			_prete = true
		_t += delta
		var s := sin(_t * vitesse + phase)
		cible.rotation.z = _base_rot + amplitude * s
		if echelle:
			cible.position = _base_pos + Vector3(amplitude * 0.6 * s, 0.0,
				amplitude * 0.4 * sin(_t * vitesse * 0.7 + phase))


class Rotation extends Node:
	var cible: Node3D
	var axe := Vector3(0, 0, 1)
	var vitesse := 1.0

	func _process(delta: float) -> void:
		cible.rotate(axe.normalized(), vitesse * delta)


class Fumee extends Node3D:
	var _t := 0.0
	var _bouffees: Array = []
	const CADENCE := 0.85

	func _ready() -> void:
		_t = randf() * CADENCE

	func _process(delta: float) -> void:
		_t += delta
		if _t >= CADENCE:
			_t -= CADENCE
			_lacher()
		for b in _bouffees.duplicate():
			var noeud: MeshInstance3D = b.noeud
			if not is_instance_valid(noeud):
				_bouffees.erase(b)
				continue
			b.age += delta
			var k: float = b.age / 2.6
			if k >= 1.0:
				noeud.queue_free()
				_bouffees.erase(b)
				continue
			noeud.position = b.depart + Vector3(sin(k * 3.0 + b.decal) * 0.16,
				k * 1.05, cos(k * 2.2 + b.decal) * 0.1)
			noeud.scale = Vector3.ONE * (0.35 + k * 1.5)
			var mat: StandardMaterial3D = noeud.material_override
			mat.albedo_color.a = (1.0 - k) * 0.42

	func _lacher() -> void:
		var mi := MeshInstance3D.new()
		var sph := SphereMesh.new()
		sph.radius = 0.13
		sph.height = 0.26
		sph.radial_segments = 8
		sph.rings = 5
		mi.mesh = sph
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.96, 0.95, 0.98, 0.42)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		_bouffees.append({"noeud": mi, "age": 0.0, "depart": Vector3.ZERO,
			"decal": randf() * TAU})

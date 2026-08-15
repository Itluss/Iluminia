class_name VueVille
extends Node3D
## VUE 3D DE LA VILLE — couche de RENDU pure (fondation 3D du Prompt 6).
##
## RÈGLE ABSOLUE : cette vue reçoit un état métier déjà calculé et
## l'AFFICHE. Interdit ici : production, économie, besoins, récompenses,
## maîtrise — aucun Node3D n'est source de vérité métier. L'orchestration
## (ville.gd) appelle `reconstruire(...)` avec les données ; les
## conventions d'échelle et la traduction vivent dans AdaptateurRendu ;
## la géométrie des bâtiments vient de FabriqueBatiments.
##
## Contenu : ambiance/lumière stylisée, terrain de départ, grille de
## construction (invisible en mode normal), caméra 3/4 isométrique
## stable, bâtiments, fantôme de placement.

var _camera: Camera3D
var _cible_camera := Vector3.ZERO
var _noeuds_batiments: Array = []
var _noeud_fantome: Node3D
var _grille: Node3D


func _ready() -> void:
	Ambiance.installer(self, Ambiance.THEME_JOUR)
	_construire_terrain()
	_construire_grille()
	# CAMÉRA : orthographique 3/4 iso légère — cadrage stable et lisible
	# en mobile paysage, panoramique borné, aucune rotation libre.
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = float(AdaptateurRendu.CAMERA.taille_ortho)
	add_child(_camera)
	_placer_camera()
	_camera.current = true


func _placer_camera() -> void:
	_camera.position = _cible_camera + Vector3(AdaptateurRendu.CAMERA.decalage)
	_camera.look_at(_cible_camera)


## Panoramique au doigt, borné au terrain (caméra toujours stable).
func panoramique(relatif: Vector2) -> void:
	var d := relatif * 0.02
	var borne := float(AdaptateurRendu.CAMERA.borne_pan)
	_cible_camera += Vector3(-d.x - d.y, 0.0, d.x - d.y) * 0.7
	_cible_camera.x = clampf(_cible_camera.x, -borne, borne)
	_cible_camera.z = clampf(_cible_camera.z, -borne, borne)
	_placer_camera()


## Tap écran → case logique (rayon caméra → plan du sol).
func case_sous(pos_ecran: Vector2) -> Vector2i:
	var origine := _camera.project_ray_origin(pos_ecran)
	var direction := _camera.project_ray_normal(pos_ecran)
	if absf(direction.y) < 0.001:
		return Vector2i(-1, -1)
	var t := -origine.y / direction.y
	return AdaptateurRendu.case_depuis_sol(origine + direction * t)


## Reconstruit les bâtiments depuis l'état métier fourni (jamais lu ici).
func reconstruire(ville_posee: Array) -> void:
	for n in _noeuds_batiments:
		n.queue_free()
	_noeuds_batiments = []
	for inst in AdaptateurRendu.instructions(ville_posee):
		var noeud := Node3D.new()
		noeud.position = inst.position
		noeud.rotation.y = float(inst.rotation_y)
		add_child(noeud)
		FabriqueBatiments.construire(noeud, str(inst.type), int(inst.niveau))
		_noeuds_batiments.append(noeud)


func montrer_grille(visible_grille: bool) -> void:
	_grille.visible = visible_grille


## Fantôme de placement (vert = valide, rouge = invalide).
func afficher_fantome(type: String, fantome: Dictionary) -> void:
	retirer_fantome()
	_noeud_fantome = Node3D.new()
	add_child(_noeud_fantome)
	var taille := int(Cite.BATIMENTS.get(type, {}).get("taille", 2))
	_noeud_fantome.position = AdaptateurRendu.position_monde(
		int(fantome.x), int(fantome.y), taille)
	_noeud_fantome.rotation.y = AdaptateurRendu.rotation_monde(int(fantome.rot))
	var teinte := Color(0.25, 0.95, 0.5) if bool(fantome.valide) else Color(0.98, 0.25, 0.25)
	# Emprise au sol bien lisible + volume translucide + poteaux d'angle.
	var emprise := BoxMesh.new()
	emprise.size = Vector3(taille, 0.1, taille)
	Materiaux.mesh(_noeud_fantome, emprise, Materiaux.emissif(teinte, 0.7),
		Vector3(0.0, 0.06, 0.0), Vector3.ONE, false)
	var volume := BoxMesh.new()
	volume.size = Vector3(taille * 0.8, 1.0, taille * 0.8)
	Materiaux.mesh(_noeud_fantome, volume, Materiaux.verre(teinte, 0.3, 1.2),
		Vector3(0.0, 0.62, 0.0), Vector3.ONE, false)
	for cx: float in [-1.0, 1.0]:
		for cz: float in [-1.0, 1.0]:
			Materiaux.mesh(_noeud_fantome, Materiaux.cylindre(0.05, 1.3),
				Materiaux.emissif(teinte, 1.6),
				Vector3(cx * taille / 2.0, 0.65, cz * taille / 2.0), Vector3.ONE, false)


func retirer_fantome() -> void:
	if _noeud_fantome != null:
		_noeud_fantome.queue_free()
		_noeud_fantome = null


## Le terrain de départ : une PROMESSE — parcelle lisible, herbe douce à
## nuances, bordure de terre et roche, micro-détails très rares. L'espace
## vide domine : « je pars de peu, ma ville va grandir ».
func _construire_terrain() -> void:
	var demi := Cite.TAILLE_GRILLE / 2.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260815
	# Une seule nappe d'herbe (aucune couture de tuiles = aucune grille
	# perceptible) puis de GRANDES taches organiques plus claires/foncées.
	var sol := BoxMesh.new()
	sol.size = Vector3(Cite.TAILLE_GRILLE, 0.3, Cite.TAILLE_GRILLE)
	Materiaux.mesh(self, sol, Materiaux.toon(Color(0.36, 0.66, 0.37)),
		Vector3(0.0, -0.15, 0.0), Vector3.ONE, false)
	for i in 9:
		var variation := rng.randf_range(-0.03, 0.035)
		var teinte := Color(0.36 + variation, 0.66 + variation, 0.37 + variation)
		var tache := Vector2(rng.randf_range(-demi + 1.6, demi - 1.6),
			rng.randf_range(-demi + 1.6, demi - 1.6))
		Materiaux.mesh(self, Materiaux.sphere(1.0), Materiaux.toon(teinte),
			Vector3(tache.x, -0.235, tache.y),
			Vector3(rng.randf_range(1.6, 3.2), 0.25, rng.randf_range(1.3, 2.6)), false)
	# Bordure : couche de terre puis roche, avec pierres saillantes.
	var terre := BoxMesh.new()
	terre.size = Vector3(Cite.TAILLE_GRILLE + 0.4, 1.0, Cite.TAILLE_GRILLE + 0.4)
	Materiaux.mesh(self, terre, Materiaux.toon(Color(0.48, 0.34, 0.24)),
		Vector3(0.0, -0.8, 0.0), Vector3.ONE, false)
	var roche := BoxMesh.new()
	roche.size = Vector3(Cite.TAILLE_GRILLE + 0.1, 1.2, Cite.TAILLE_GRILLE + 0.1)
	Materiaux.mesh(self, roche, Materiaux.toon(Color(0.42, 0.4, 0.44)),
		Vector3(0.0, -1.85, 0.0), Vector3.ONE, false)
	for i in 14:
		var cote := i % 4
		var le_long := rng.randf_range(-demi + 0.5, demi - 0.5)
		var p: Vector3 = [Vector3(le_long, 0, demi + 0.18), Vector3(le_long, 0, -demi - 0.18),
			Vector3(demi + 0.18, 0, le_long), Vector3(-demi - 0.18, 0, le_long)][cote]
		Materiaux.mesh(self, Materiaux.sphere(rng.randf_range(0.16, 0.3)),
			Materiaux.toon(Color(0.5, 0.47, 0.5)),
			p + Vector3(0.0, rng.randf_range(-1.4, -0.4), 0.0), Vector3(1.0, 0.8, 1.0), false)
	# Micro-détails du sol (non interactifs, très discrets).
	for i in 7:
		var p := Vector2(rng.randf_range(-demi + 1.0, demi - 1.0), rng.randf_range(-demi + 1.0, demi - 1.0))
		Materiaux.mesh(self, Materiaux.sphere(0.045),
			Materiaux.toon([Color(0.95, 0.75, 0.3), Color(0.9, 0.5, 0.7), Color(0.95, 0.95, 0.9)][i % 3]),
			Vector3(p.x, 0.05, p.y), Vector3.ONE, false)
	for i in 4:
		var p := Vector2(rng.randf_range(-demi + 1.0, demi - 1.0), rng.randf_range(-demi + 1.0, demi - 1.0))
		Materiaux.mesh(self, Materiaux.sphere(rng.randf_range(0.1, 0.18)),
			Materiaux.toon(Color(0.55, 0.53, 0.56)), Vector3(p.x, 0.04, p.y), Vector3(1.0, 0.6, 1.0), false)
	# Amorce de chemin devant la maison (3 dalles).
	for i in 3:
		var dalle := BoxMesh.new()
		dalle.size = Vector3(0.5, 0.05, 0.42)
		Materiaux.mesh(self, dalle, Materiaux.toon(Color(0.72, 0.68, 0.6)),
			Vector3(1.0 - demi + 4.4 + i * 0.6, 0.03, 1.0 - demi + 7.6), Vector3.ONE, false)
	# Nuages doux au loin (le beau ciel de la maquette).
	for i in 5:
		var nuage := Node3D.new()
		var ang := TAU * i / 5.0 + 0.5
		nuage.position = Vector3(cos(ang) * 18.0, rng.randf_range(4.0, 8.0), sin(ang) * 18.0)
		add_child(nuage)
		for b in 3:
			Materiaux.mesh(nuage, Materiaux.sphere(rng.randf_range(0.9, 1.5)),
				Materiaux.toon(Color(0.98, 0.99, 1.0)),
				Vector3(b * 1.2 - 1.2, rng.randf_range(-0.2, 0.2), 0.0), Vector3(1.0, 0.6, 0.85), false)


## Grille de construction — INVISIBLE en mode normal.
func _construire_grille() -> void:
	_grille = Node3D.new()
	_grille.visible = false
	add_child(_grille)
	var demi := Cite.TAILLE_GRILLE / 2.0
	for i in Cite.TAILLE_GRILLE + 1:
		for aligne in 2:
			var ligne := BoxMesh.new()
			ligne.size = Vector3(Cite.TAILLE_GRILLE, 0.01, 0.03) if aligne == 0 \
				else Vector3(0.03, 0.01, Cite.TAILLE_GRILLE)
			var pos := Vector3(0.0, 0.06, i - demi) if aligne == 0 else Vector3(i - demi, 0.06, 0.0)
			Materiaux.mesh(_grille, ligne, Materiaux.verre(Color.WHITE, 0.16, 0.3), pos, Vector3.ONE, false)

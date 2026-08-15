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
var _surbrillance: Node3D
var _indice_surligne := -2


func _ready() -> void:
	# L'UNIVERS D'ILLUMINIA : jour enchanté (bible : univers.gd).
	Univers.installer_ambiance(self)
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
		noeud.set_meta("taille", int(inst.taille))
		add_child(noeud)
		FabriqueBatiments.construire(noeud, str(inst.type), int(inst.niveau))
		_noeuds_batiments.append(noeud)
	_indice_surligne = -2   # la surbrillance suit un nœud recréé


## SÉLECTION : anneau lumineux doux sous le bâtiment — feedback
## immédiat, ni scale brutal, ni popup. Idempotent (appelable à chaque
## frame) ; indice < 0 = aucune sélection.
func surligner(indice: int) -> void:
	if indice == _indice_surligne:
		return
	_indice_surligne = indice
	if _surbrillance != null:
		_surbrillance.queue_free()
		_surbrillance = null
	if indice < 0 or indice >= _noeuds_batiments.size():
		return
	var noeud: Node3D = _noeuds_batiments[indice]
	var taille := int(noeud.get_meta("taille", 2))
	var anneau := TorusMesh.new()
	anneau.inner_radius = taille * 0.62
	anneau.outer_radius = taille * 0.7
	_surbrillance = Materiaux.mesh(noeud, anneau,
		Materiaux.emissif(Color(0.35, 0.85, 1.0), 1.3),
		Vector3(0.0, 0.05, 0.0), Vector3(1.0, 0.35, 1.0), false)


## APPARITION (première construction) : 0,5 s — léger overshoot de
## scale + éclat de lumière qui s'éteint. Récompense immédiate, zéro
## effet lourd.
func animer_apparition(indice: int) -> void:
	if indice < 0 or indice >= _noeuds_batiments.size():
		return
	var noeud: Node3D = _noeuds_batiments[indice]
	noeud.scale = Vector3.ONE * 0.9
	var tw := create_tween()
	tw.tween_property(noeud, "scale", Vector3.ONE * 1.06, 0.28) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(noeud, "scale", Vector3.ONE, 0.22) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	var lum := OmniLight3D.new()
	lum.light_color = Color(0.55, 0.9, 1.0)
	lum.light_energy = 2.6
	lum.omni_range = 6.0
	lum.position = Vector3(0.0, 1.6, 0.0)
	noeud.add_child(lum)
	var tw2 := create_tween()
	tw2.tween_property(lum, "light_energy", 0.0, 0.55)
	tw2.tween_callback(lum.queue_free)


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


## Le terrain de départ : l'ÎLE-CLAIRIÈRE sculptée de l'art kit —
## plateau organique, strates de terre et de falaise, chemin de sable
## qui invite, taches d'herbe. La zone constructible reste plate (y = 0)
## et l'espace vide domine : « ma ville va grandir ici ».
func _construire_terrain() -> void:
	var ile: Node3D = (load(Univers.TERRAIN_ILE) as PackedScene).instantiate()
	Univers.harmoniser_gltf(ile)
	add_child(ile)


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

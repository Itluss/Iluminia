class_name Ville
extends Node3D
## MA VILLE — la matérialisation du progrès (vertical slice v1).
##
## Vue 3D inclinée « stratégique » : on contemple, on construit, on
## organise — pas de personnage à déplacer. La ville vit sur la GRILLE
## INVISIBLE de cite.gd ; v1 : le catalogue est réel (paliers de
## connaissance + or) et CONSTRUIRE pose le bâtiment sur une case libre.
## Le placement libre (choisir/déplacer/tourner) viendra sur ce modèle.
##
## DA : fantasy médiévale chaleureuse au départ — le merveilleux
## (cristaux, magie) grandira avec la ville.

var _camera: Camera3D
var _cible_camera := Vector3(0.0, 0.0, 0.0)
var _noeuds_batiments: Array = []
var surface: SurfaceVille
var _t := 0.0


func _ready() -> void:
	Ambiance.installer(self, Ambiance.THEME_JOUR)
	var demi := Cite.TAILLE_GRILLE / 2.0
	# Plateau d'herbe en damier doux (les cases de la grille, subtiles).
	for gx in Cite.TAILLE_GRILLE:
		for gy in Cite.TAILLE_GRILLE:
			var teinte := Color(0.34, 0.64, 0.36) if (gx + gy) % 2 == 0 else Color(0.32, 0.6, 0.34)
			var tuile := BoxMesh.new()
			tuile.size = Vector3(1.0, 0.3, 1.0)
			Materiaux.mesh(self, tuile, Materiaux.toon(teinte),
				Vector3(gx - demi + 0.5, -0.15, gy - demi + 0.5), Vector3.ONE, false)
	# Socle de terre sous le plateau.
	var socle := BoxMesh.new()
	socle.size = Vector3(Cite.TAILLE_GRILLE + 0.6, 1.6, Cite.TAILLE_GRILLE + 0.6)
	Materiaux.mesh(self, socle, Materiaux.toon(Color(0.42, 0.3, 0.22)),
		Vector3(0.0, -1.1, 0.0), Vector3.ONE, false)
	# Arbres du pourtour (chaleur médiévale).
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260814
	for i in 10:
		var bord: Vector2 = [Vector2(rng.randf_range(-demi + 0.8, demi - 0.8), -demi + 0.7),
			Vector2(rng.randf_range(-demi + 0.8, demi - 0.8), demi - 0.7),
			Vector2(-demi + 0.7, rng.randf_range(-demi + 0.8, demi - 0.8)),
			Vector2(demi - 0.7, rng.randf_range(-demi + 0.8, demi - 0.8))][i % 4]
		var arbre := Node3D.new()
		arbre.position = Vector3(bord.x, 0.0, bord.y)
		add_child(arbre)
		var taille := rng.randf_range(0.7, 1.1)
		Materiaux.mesh(arbre, Materiaux.cylindre(0.13 * taille, 0.9 * taille),
			Materiaux.toon(Color(0.45, 0.32, 0.2)), Vector3(0.0, 0.45 * taille, 0.0))
		Materiaux.mesh(arbre, Materiaux.sphere(0.62 * taille), Materiaux.toon(Color(0.25, 0.5, 0.27)),
			Vector3(0.0, 1.25 * taille, 0.0), Vector3(1.0, 0.9, 1.0))
	_reconstruire_batiments()

	# Caméra inclinée stratégique, déplaçable au doigt.
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = 12.0
	add_child(_camera)
	_camera.position = _cible_camera + Vector3(9.0, 11.0, 9.0)
	_camera.look_at(_cible_camera)
	_camera.current = true

	var couche := CanvasLayer.new()
	add_child(couche)
	surface = SurfaceVille.new()
	surface.ville = self
	surface.set_anchors_preset(Control.PRESET_FULL_RECT)
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	couche.add_child(surface)


## (Re)construit les bâtiments 3D depuis le modèle Profil.ville.
func _reconstruire_batiments() -> void:
	for n in _noeuds_batiments:
		n.queue_free()
	_noeuds_batiments = []
	var demi := Cite.TAILLE_GRILLE / 2.0
	for b in Profil.ville:
		var noeud := Node3D.new()
		noeud.position = Vector3(float(b.x) - demi + 1.0, 0.0, float(b.y) - demi + 1.0)
		noeud.rotation.y = float(b.get("rot", 0)) * PI / 2.0
		add_child(noeud)
		_construire_batiment(noeud, str(b.type))
		_noeuds_batiments.append(noeud)
	# Emplacements de chantier libres (cercles pointillés dorés).
	for p in _emplacements_libres():
		var anneau := Materiaux.mesh(self, Materiaux.tore(0.7, 0.04),
			Materiaux.emissif(Identite.OR, 0.9),
			Vector3(float(p.x) - demi + 1.0, 0.05, float(p.y) - demi + 1.0), Vector3.ONE, false)
		_noeuds_batiments.append(anneau)


## Cases de chantier proposées (v1 : anneau autour du centre).
func _emplacements_libres() -> Array:
	var occupees := {}
	for b in Profil.ville:
		occupees[Vector2i(int(b.x), int(b.y))] = true
	var libres: Array = []
	for p in [Vector2i(3, 5), Vector2i(7, 3), Vector2i(8, 7), Vector2i(4, 8), Vector2i(7, 9)]:
		if not occupees.has(p):
			libres.append(p)
	return libres


## Bâtiments 3D procéduraux — fantasy médiévale chaleureuse.
func _construire_batiment(noeud: Node3D, type: String) -> void:
	match type:
		"maison":
			var murs := BoxMesh.new()
			murs.size = Vector3(1.5, 1.0, 1.3)
			Materiaux.mesh(noeud, murs, Materiaux.toon(Identite.CREME), Vector3(0.0, 0.5, 0.0))
			var toit := PrismMesh.new()
			toit.size = Vector3(1.7, 0.8, 1.5)
			Materiaux.mesh(noeud, toit, Materiaux.toon(Color(0.75, 0.34, 0.26)), Vector3(0.0, 1.4, 0.0))
			var porte := BoxMesh.new()
			porte.size = Vector3(0.34, 0.55, 0.06)
			Materiaux.mesh(noeud, porte, Materiaux.toon(Color(0.45, 0.3, 0.18)), Vector3(0.0, 0.28, 0.66))
			Materiaux.mesh(noeud, Materiaux.cylindre(0.09, 0.5), Materiaux.toon(Color(0.6, 0.6, 0.64)),
				Vector3(0.55, 1.85, -0.3)) # cheminée
		"potager":
			for r in 3:
				var rangee := BoxMesh.new()
				rangee.size = Vector3(1.5, 0.14, 0.3)
				Materiaux.mesh(noeud, rangee, Materiaux.toon(Color(0.4, 0.27, 0.18)),
					Vector3(0.0, 0.07, -0.5 + r * 0.5))
				for l in 3:
					Materiaux.mesh(noeud, Materiaux.sphere(0.1), Materiaux.toon(Identite.VERT),
						Vector3(-0.5 + l * 0.5, 0.2, -0.5 + r * 0.5), Vector3.ONE, false)
		"atelier":
			var murs := BoxMesh.new()
			murs.size = Vector3(1.5, 0.9, 1.2)
			Materiaux.mesh(noeud, murs, Materiaux.toon(Color(0.62, 0.46, 0.3)), Vector3(0.0, 0.45, 0.0))
			var toit := PrismMesh.new()
			toit.size = Vector3(1.7, 0.6, 1.4)
			Materiaux.mesh(noeud, toit, Materiaux.toon(Color(0.4, 0.28, 0.2)), Vector3(0.0, 1.2, 0.0))
			Materiaux.mesh(noeud, Materiaux.cylindre(0.16, 0.7), Materiaux.toon(Color(0.5, 0.36, 0.24)),
				Vector3(0.75, 0.35, 0.5)) # billot
		"forge":
			var murs := BoxMesh.new()
			murs.size = Vector3(1.6, 1.0, 1.3)
			Materiaux.mesh(noeud, murs, Materiaux.toon(Color(0.52, 0.52, 0.58)), Vector3(0.0, 0.5, 0.0))
			var toit := PrismMesh.new()
			toit.size = Vector3(1.8, 0.7, 1.5)
			Materiaux.mesh(noeud, toit, Materiaux.toon(Color(0.28, 0.28, 0.34)), Vector3(0.0, 1.35, 0.0))
			Materiaux.mesh(noeud, Materiaux.cylindre(0.12, 0.8), Materiaux.toon(Color(0.35, 0.35, 0.4)),
				Vector3(0.55, 2.0, -0.3))
			Materiaux.mesh(noeud, Materiaux.sphere(0.14), Materiaux.emissif(Identite.ORANGE, 1.8),
				Vector3(0.0, 0.6, 0.68), Vector3.ONE, false) # foyer
		_:
			var bloc := BoxMesh.new()
			bloc.size = Vector3(1.4, 1.0, 1.4)
			Materiaux.mesh(noeud, bloc, Materiaux.toon(Identite.PANNEAU_CLAIR), Vector3(0.0, 0.5, 0.0))


## CONSTRUIRE : la connaissance ouvre le droit, l'or paie le chantier.
func construire(type: String) -> bool:
	if not Cite.constructible(type, Profil.connaissance_xp, Profil.pieces):
		return false
	var libres := _emplacements_libres()
	if libres.is_empty():
		return false
	var b: Dictionary = Cite.BATIMENTS[type]
	Profil.pieces -= int(b["or"])
	Profil.ville.append({"type": type, "x": int(libres[0].x), "y": int(libres[0].y), "rot": 0})
	Profil.sauver()
	_reconstruire_batiments()
	return true


func _process(delta: float) -> void:
	_t += delta
	surface.queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		var action := surface.action_sous(event.position)
		if action != "":
			_executer(action)
	elif event is InputEventScreenDrag:
		# Déplacement de la caméra au doigt (contempler sa ville).
		var d: Vector2 = event.relative * 0.02
		_cible_camera += Vector3(-d.x - d.y, 0.0, d.x - d.y) * 0.7
		_cible_camera.x = clampf(_cible_camera.x, -5.0, 5.0)
		_cible_camera.z = clampf(_cible_camera.z, -5.0, 5.0)
		_camera.position = _cible_camera + Vector3(9.0, 11.0, 9.0)


func _executer(action: String) -> void:
	var morceaux := action.split(":")
	match morceaux[0]:
		"retour":
			Audio.jouer("clic")
			get_tree().change_scene_to_file.call_deferred("res://scenes/accueil.tscn")
		"construire":
			if construire(morceaux[1]):
				Audio.jouer("victoire")
				surface.toast("%s construit(e) ! Ta ville grandit." % str(Cite.BATIMENTS[morceaux[1]].titre))
			else:
				Audio.jouer("denied")


## Interface de la ville : économie, catalogue, retour à l'arbre.
class SurfaceVille extends Control:
	var ville: Ville = null
	var _actions: Array = []
	var _toast := ""
	var _toast_temps := 0.0

	func action_sous(pos: Vector2) -> String:
		for a in _actions:
			var rect: Rect2 = a.rect
			if rect.has_point(pos):
				return str(a.action)
		return ""

	func toast(texte: String) -> void:
		_toast = texte
		_toast_temps = 3.0

	func _draw() -> void:
		_actions = []
		_toast_temps = maxf(_toast_temps - get_process_delta_time(), 0.0)
		var palier := Cite.palier(Profil.connaissance_xp)
		# En-tête : retour, nom du palier, économie.
		UI.bouton(self, Rect2(10.0, 10.0, 66.0, 50.0), Identite.BLEU, "ville_retour", false, Identite.RAYON_SM)
		UI.texte(self, Vector2(43.0, 42.0), "←", 22, Identite.TEXTE, true)
		_actions.append({"rect": Rect2(10.0, 10.0, 66.0, 50.0), "action": "retour"})
		UI.banniere(self, Vector2(250.0, 32.0), 320.0,
			"MA VILLE — %s" % str(Cite.PALIERS[palier].nom).to_upper(), 15)
		UI.capsule(self, Rect2(440.0, 14.0, 120.0, 40.0), Identite.OR, str(Profil.pieces), "piece", false)
		var res: Dictionary = Profil.ressources
		UI.texte(self, Vector2(572.0, 40.0),
			"🪵 %d  🪨 %d  🌾 %d" % [int(res.bois), int(res.pierre), int(res.nourriture)],
			13, Identite.TEXTE_ATTENUE)
		# CATALOGUE (droite) : la connaissance ouvre, l'or paie.
		var rect := Rect2(size.x - 262.0, 78.0, 252.0, size.y - 90.0)
		UI.panneau(self, rect)
		UI.texte(self, rect.position + Vector2(16.0, 26.0), "CATALOGUE", 15, Identite.OR)
		var y := rect.position.y + 40.0
		for type in Cite.BATIMENTS:
			var b: Dictionary = Cite.BATIMENTS[type]
			var construit := false
			for pose in Profil.ville:
				if str(pose.type) == type:
					construit = true
			var accessible: bool = palier >= int(b.palier)
			var ligne := Rect2(rect.position.x + 10.0, y, rect.size.x - 20.0, 40.0)
			self.draw_style_box(UI.style("cat_%s_%s" % [type, str(accessible)],
				Identite.NUIT if accessible else Color(0.08, 0.1, 0.2),
				Identite.VERT_SOMBRE if construit else (Identite.CONTOUR if accessible else Color(0.2, 0.22, 0.3)),
				Identite.RAYON_SM, 2, 0), ligne)
			UI.texte(self, ligne.position + Vector2(10.0, 18.0), str(b.titre), 13,
				Identite.TEXTE if accessible else Identite.TEXTE_ATTENUE)
			if construit:
				UI.texte(self, ligne.position + Vector2(10.0, 34.0), "✓ construit", 10, Identite.VERT)
			elif not accessible:
				UI.image(self, "icon-lock", Rect2(ligne.end - Vector2(30.0, 34.0), Vector2(18.0, 18.0)))
				UI.texte(self, ligne.position + Vector2(10.0, 34.0),
					"Palier %d (connaissance)" % int(b.palier), 10, Identite.ORANGE)
			else:
				UI.texte(self, ligne.position + Vector2(10.0, 34.0), "%d or" % int(b["or"]), 10, Identite.OR)
				var peut: bool = Cite.constructible(type, Profil.connaissance_xp, Profil.pieces)
				var bouton := Rect2(ligne.end.x - 96.0, ligne.position.y + 4.0, 88.0, 32.0)
				UI.bouton(self, bouton, Identite.VERT if peut else Color(0.3, 0.32, 0.42),
					"construire_%s" % type, false, Identite.RAYON_SM)
				UI.texte(self, bouton.get_center() + Vector2(0.0, 5.0), "BÂTIR", 12, Identite.TEXTE, true, 4)
				if peut:
					_actions.append({"rect": bouton, "action": "construire:%s" % type})
			y += 46.0
		# Le rappel du moteur : apprendre = le droit de construire.
		UI.texte(self, Vector2((size.x - 262.0) / 2.0, size.y - 20.0),
			"La CONNAISSANCE débloque le catalogue — l'or ne suffit jamais.", 12, Identite.CREME, true, 4)
		if _toast_temps > 0.0:
			UI.banniere(self, Vector2((size.x - 262.0) / 2.0, size.y - 60.0), 420.0, _toast, 15)

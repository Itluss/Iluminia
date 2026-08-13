class_name Menu
extends Node3D
## Le LOBBY d'Iluminia et ses sous-écrans, fidèles à la planche
## style-guide-fantasypop : accueil (logo, niveau/XP, indicateur d'étoiles,
## gros JOUER doré, boutons bleus PERSONNAGES / POUVOIRS / CADEAUX, boutons
## carrés son et aide), écran Personnages (choix du Lumin + garde-robe de
## couleurs), écran Pouvoirs (kit équipé), fenêtre Cadeaux (coffre
## quotidien), fenêtre Aide. Diorama 3D animé derrière tout.

enum Ecran { ACCUEIL, PERSONNAGES, POUVOIRS, CADEAUX, AIDE }

const NOMS := ["Max", "Zep", "Nova", "Ficelle"]

var ecran := Ecran.ACCUEIL
var recompense := {}             ## dernier cadeau ouvert (affichage)
var _dragon_pivot: Node3D
var _dragon: Personnage3D
var _persos := {}                ## nom → Personnage3D du diorama
var _t := 0.0
var _lancement := false
var surface: SurfaceMenu


func _ready() -> void:
	Jeu.declarer_actions_clavier()
	Ambiance.installer(self)

	# — Île de nuit du diorama —
	Materiaux.mesh(self, Materiaux.cylindre(9.0, 0.3), Materiaux.toon(Identite.PELOUSE_NUIT),
		Vector3(0.0, -0.15, 0.0), Vector3.ONE, false)
	Materiaux.mesh(self, Materiaux.tore(9.1, 0.12), Materiaux.emissif(Identite.LUEUR_LISIERE, 1.4),
		Vector3(0.0, 0.05, 0.0), Vector3.ONE, false)
	var falaise := CylinderMesh.new()
	falaise.top_radius = 9.4
	falaise.bottom_radius = 1.6
	falaise.height = 8.0
	falaise.radial_segments = 24
	Materiaux.mesh(self, falaise, Materiaux.toon(Identite.ROCHE), Vector3(0.0, -4.3, 0.0), Vector3.ONE, false)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 20:
		var p := Vector2.from_angle(rng.randf_range(0.0, TAU)) * rng.randf_range(2.5, 8.4)
		var teinte: Color = [Identite.OR, Identite.CYAN, Identite.MAGENTA][rng.randi() % 3]
		Materiaux.mesh(self, Materiaux.sphere(0.1), Materiaux.emissif(teinte, 1.3),
			Vector3(p.x, 0.12, p.y), Vector3.ONE, false)
	for i in 6:
		var ang := TAU * i / 6.0 + 0.3
		var p := Vector2.from_angle(ang) * 8.6
		var cristal := Materiaux.mesh(self, Materiaux.cone(0.22, rng.randf_range(0.7, 1.2)),
			Materiaux.emissif(Identite.CYAN if i % 2 == 0 else Identite.VIOLET, 1.3),
			Vector3(p.x, 0.3, p.y))
		cristal.rotation_degrees = Vector3(rng.randf_range(-12.0, 12.0), 0.0, rng.randf_range(-12.0, 12.0))
	var lucioles := CPUParticles3D.new()
	lucioles.amount = 24
	lucioles.lifetime = 7.0
	lucioles.preprocess = 7.0
	lucioles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	lucioles.emission_box_extents = Vector3(8.0, 1.5, 8.0)
	lucioles.direction = Vector3.UP
	lucioles.spread = 180.0
	lucioles.initial_velocity_min = 0.1
	lucioles.initial_velocity_max = 0.5
	lucioles.gravity = Vector3.ZERO
	var etincelle := SphereMesh.new()
	etincelle.radius = 0.05
	etincelle.height = 0.1
	etincelle.radial_segments = 6
	etincelle.rings = 3
	etincelle.material = Materiaux.emissif(Identite.CREME, 1.8)
	lucioles.mesh = etincelle
	lucioles.position = Vector3(0.0, 1.5, 0.0)
	add_child(lucioles)
	lucioles.emitting = true

	_reconstruire_persos()

	_dragon_pivot = Node3D.new()
	add_child(_dragon_pivot)
	_dragon = Personnage3D.new()
	_dragon.genre = "dragon"
	_dragon.couleur = Color(0.45, 0.82, 0.55)
	_dragon.position = Vector3(3.0, 2.6, 0.0)
	_dragon.regarder(Vector2(0.0, 1.0))
	_dragon_pivot.add_child(_dragon)

	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 10.5
	camera.position = Vector3(10.0, 11.0, 10.0)
	add_child(camera)
	camera.look_at(Vector3(0.0, 1.4, 0.0))
	camera.current = true

	var couche := CanvasLayer.new()
	add_child(couche)
	surface = SurfaceMenu.new()
	surface.menu = self
	surface.set_anchors_preset(Control.PRESET_FULL_RECT)
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	couche.add_child(surface)

	# Crochet de dev : ILUMINIA_ECRAN=personnages|pouvoirs|cadeaux|aide
	# ouvre directement un sous-écran (captures automatisées).
	match OS.get_environment("ILUMINIA_ECRAN"):
		"personnages":
			ecran = Ecran.PERSONNAGES
		"pouvoirs":
			ecran = Ecran.POUVOIRS
		"cadeaux":
			ecran = Ecran.CADEAUX
		"aide":
			ecran = Ecran.AIDE


## (Re)crée les quatre Lumins du diorama avec leurs variantes actuelles.
func _reconstruire_persos() -> void:
	for nom in _persos:
		_persos[nom].queue_free()
	_persos = {}
	var perpendiculaire := Vector3(-1.0, 0.0, 1.0).normalized()
	var vers_camera := Vector3(1.0, 0.0, 1.0).normalized()
	for i in NOMS.size():
		var nom: String = NOMS[i]
		var perso := Personnage3D.new()
		perso.genre = "chasseur"
		perso.etiquette = nom
		perso.couleur = Profil.couleur_de(nom)
		perso.utiliser_fiche_couleur = false
		perso.position = perpendiculaire * (i - 1.5) * 2.6 - vers_camera * 1.6
		add_child(perso)
		perso.regarder(Vector2(1.0, 1.0).normalized())
		_persos[nom] = perso


func _process(delta: float) -> void:
	_t += delta
	_dragon_pivot.rotation.y += delta * 0.5
	_dragon.position.y = 2.6 + sin(_t * 2.0) * 0.3
	_dragon.en_marche = true
	for nom in _persos:
		var perso: Personnage3D = _persos[nom]
		perso.en_marche = fmod(_t + float(NOMS.find(nom)) * 1.7, 5.0) < 1.2
		# L'anneau doré sert d'indicateur de sélection dans le lobby.
		perso.montrer_anneau(nom == Profil.personnage)
	surface.queue_redraw()


func _input(event: InputEvent) -> void:
	if _lancement:
		return
	if event is InputEventScreenTouch and event.pressed:
		var action := surface.action_sous(event.position)
		if action != "":
			_executer(action)
	elif event is InputEventKey and event.pressed and not event.echo:
		if ecran == Ecran.ACCUEIL and (event.physical_keycode == KEY_ENTER or event.physical_keycode == KEY_SPACE):
			_executer("jouer")
		elif event.physical_keycode == KEY_ESCAPE:
			_executer("retour")


func _executer(action: String) -> void:
	match action:
		"jouer":
			_jouer()
		"retour":
			Audio.jouer("clic")
			ecran = Ecran.ACCUEIL
			recompense = {}
		"personnages":
			Audio.jouer("clic")
			ecran = Ecran.PERSONNAGES
		"pouvoirs":
			Audio.jouer("clic")
			ecran = Ecran.POUVOIRS
		"cadeaux":
			Audio.jouer("clic")
			ecran = Ecran.CADEAUX
		"aide":
			Audio.jouer("clic")
			ecran = Ecran.AIDE
		"son":
			Profil.basculer_son()
			Audio.jouer("clic")
		"ouvrir_cadeau":
			if Profil.cadeau_disponible():
				recompense = Profil.ouvrir_cadeau()
				_reconstruire_persos()
				Audio.jouer("victoire")
		_:
			# Sélections : "perso:Nom" ou "variante:Nom:i".
			var morceaux := action.split(":")
			if morceaux[0] == "perso":
				Profil.choisir_personnage(morceaux[1])
				Audio.jouer("clic")
			elif morceaux[0] == "variante":
				if Profil.choisir_variante(morceaux[1], int(morceaux[2])):
					Audio.jouer("ramasser")
					_reconstruire_persos()
				else:
					Audio.jouer("denied")


func _jouer() -> void:
	_lancement = true
	Audio.jouer("clic")
	Audio.jouer("depart")
	get_tree().change_scene_to_file.call_deferred("res://scenes/jeu.tscn")


## Toute l'interface du lobby. Chaque _draw() reconstruit la liste des
## boutons touchables (`_actions`) : dessin et zones de toucher ne peuvent
## pas diverger.
class SurfaceMenu extends Control:
	var menu: Menu = null
	var _actions: Array = []   ## {rect, action}

	func action_sous(pos: Vector2) -> String:
		for a in _actions:
			var rect: Rect2 = a.rect
			if rect.has_point(pos):
				return str(a.action)
		return ""

	func _bouton_action(rect: Rect2, action: String, fond: Color, txt: String, taille := 20, rayon := Identite.RAYON_MD) -> void:
		UI.bouton(self, rect, fond, "menu_%s_%s" % [action, fond.to_html(false)], false, rayon)
		UI.texte(self, rect.get_center() + Vector2(0.0, taille * 0.36), txt, taille, Identite.TEXTE, true)
		_actions.append({"rect": rect, "action": action})

	func _draw() -> void:
		_actions = []
		match menu.ecran:
			Menu.Ecran.ACCUEIL:
				_dessiner_accueil()
			Menu.Ecran.PERSONNAGES:
				_entete_sous_ecran("PERSONNAGES")
				_dessiner_personnages()
			Menu.Ecran.POUVOIRS:
				_entete_sous_ecran("POUVOIRS")
				_dessiner_pouvoirs()
			Menu.Ecran.CADEAUX:
				_entete_sous_ecran("CADEAUX")
				_dessiner_cadeaux()
			Menu.Ecran.AIDE:
				_entete_sous_ecran("COMMENT JOUER")
				_dessiner_aide()

	# ---------------------------------------------------------- accueil

	## Bandeau du haut : niveau/XP à gauche (planche « progression »),
	## étoiles à droite, son et aide en boutons carrés.
	func _entete_commun() -> void:
		# Badge de niveau + barre d'XP violette.
		UI.panneau(self, Rect2(10.0, 10.0, 230.0, 56.0))
		UI.pastille(self, Vector2(40.0, 38.0), 20.0, Identite.VIOLET, str(Profil.niveau), 18)
		UI.texte(self, Vector2(70.0, 30.0), "Niveau %d" % Profil.niveau, 14, Identite.TEXTE_ATTENUE)
		UI.barre(self, Rect2(70.0, 38.0, 156.0, 16.0), Profil.xp / Profil.xp_requise(), Identite.VIOLET)
		# Indicateur d'étoiles (pastilles-indicateurs de la planche).
		UI.indicateur(self, Rect2(size.x - 296.0, 16.0, 130.0, 40.0), Identite.OR, str(Profil.etoiles))
		# Boutons carrés secondaires : son, aide.
		_bouton_action(Rect2(size.x - 152.0, 12.0, 62.0, 48.0), "son", Identite.BLEU,
			"♪" if Profil.son_actif else "✕", 20, Identite.RAYON_SM)
		_bouton_action(Rect2(size.x - 78.0, 12.0, 62.0, 48.0), "aide", Identite.BLEU, "?", 20, Identite.RAYON_SM)

	func _dessiner_accueil() -> void:
		_entete_commun()
		var t := Time.get_ticks_msec() / 1000.0
		var centre_x := size.x / 2.0
		var ballant := sin(t * 1.6) * 4.0
		# Logo : étoile + ailes + titre or + sous-titre magenta.
		var haut := size.y * 0.18 + ballant
		for cote: float in [-1.0, 1.0]:
			_aile(Vector2(centre_x + cote * 34.0, haut - 58.0), cote)
		UI.etoile(self, Vector2(centre_x, haut - 62.0), 22.0, Identite.OR)
		UI.texte(self, Vector2(centre_x, haut), "ILUMINIA", 84, Identite.OR, true, 14)
		UI.texte(self, Vector2(centre_x, haut + 38.0), "La chasse au dragon", 26, Identite.MAGENTA, true)
		# Gros JOUER doré pulsé.
		var pulse := 1.0 + 0.045 * sin(t * 4.5)
		var bl := 300.0 * pulse
		var bh := 84.0 * pulse
		var jouer := Rect2(Vector2(centre_x - bl / 2.0, size.y * 0.66 - bh / 2.0), Vector2(bl, bh))
		UI.bouton(self, jouer, Identite.OR, "jouer", false, Identite.RAYON_LG + 4)
		UI.texte(self, Vector2(centre_x, jouer.get_center().y + 12.0), "JOUER !", 36, Identite.TEXTE, true, 10)
		_actions.append({"rect": jouer, "action": "jouer"})
		# Boutons principaux bleus (planche) : Personnages / Pouvoirs / Cadeaux.
		var largeur := 224.0
		var y := size.y * 0.82
		_bouton_action(Rect2(centre_x - largeur * 1.5 - 24.0, y, largeur, 58.0), "personnages", Identite.BLEU, "PERSONNAGES", 19)
		_bouton_action(Rect2(centre_x - largeur / 2.0, y, largeur, 58.0), "pouvoirs", Identite.BLEU, "POUVOIRS", 19)
		var rect_cadeaux := Rect2(centre_x + largeur / 2.0 + 24.0, y, largeur, 58.0)
		_bouton_action(rect_cadeaux, "cadeaux", Identite.BLEU, "CADEAUX", 19)
		# Badge « NEW » quand le coffre quotidien est prêt (badges de la planche).
		if Profil.cadeau_disponible():
			var badge := Rect2(rect_cadeaux.end.x - 34.0, rect_cadeaux.position.y - 14.0, 52.0, 26.0)
			self.draw_style_box(UI.style("badge", Identite.ROUGE, Identite.CONTOUR, 8, 2, 2), badge)
			UI.texte(self, badge.get_center() + Vector2(0.0, 5.0), "NEW", 13, Identite.TEXTE, true, 4)
		UI.texte(self, Vector2(centre_x, size.y - 12.0),
			"Réponds • Attrape le dragon • Vole-le à tes amis !", 14, Color(1.0, 1.0, 1.0, 0.7), true, 5)

	## Petite aile bleue du logo (triangle étagé).
	func _aile(pos: Vector2, cote: float) -> void:
		for i in 3:
			var l := 18.0 - i * 5.0
			draw_colored_polygon(PackedVector2Array([
				pos + Vector2(cote * (10.0 + i * 12.0), -4.0 + i * 5.0),
				pos + Vector2(cote * (10.0 + i * 12.0 + l), 2.0 + i * 5.0),
				pos + Vector2(cote * (10.0 + i * 12.0), 8.0 + i * 5.0),
			]), Identite.BLEU if i % 2 == 0 else Identite.CYAN)

	# ---------------------------------------------------------- sous-écrans

	## Bandeau des sous-écrans : bouton retour + bannière de titre.
	func _entete_sous_ecran(titre: String) -> void:
		_entete_commun()
		_bouton_action(Rect2(10.0, 80.0, 62.0, 48.0), "retour", Identite.BLEU, "←", 22, Identite.RAYON_SM)
		UI.banniere(self, Vector2(size.x / 2.0, 96.0), 300.0, titre, 22)

	## Choix du Lumin + garde-robe de couleurs (une carte par personnage).
	func _dessiner_personnages() -> void:
		var largeur := minf((size.x - 80.0) / 4.0 - 12.0, 240.0)
		var total := largeur * 4.0 + 36.0
		var x0 := (size.x - total) / 2.0
		for i in Menu.NOMS.size():
			var nom: String = Menu.NOMS[i]
			var fiche: Dictionary = Personnage3D.FICHES[nom]
			var rect := Rect2(x0 + i * (largeur + 12.0), size.y - 218.0, largeur, 196.0)
			var choisi: bool = nom == Profil.personnage
			self.draw_style_box(UI.style("carte_%s" % str(choisi),
				Identite.PANNEAU_CLAIR if choisi else Identite.PANNEAU, Identite.OR if choisi else Identite.CONTOUR,
				Identite.RAYON_MD, Identite.BORD_FORT if choisi else Identite.BORD, 4), rect)
			UI.pastille(self, rect.position + Vector2(largeur / 2.0, 30.0), 17.0,
				Profil.couleur_de(nom), "", 13)
			UI.texte(self, rect.position + Vector2(largeur / 2.0, 68.0), nom, 20,
				Identite.OR if choisi else Identite.TEXTE, true)
			UI.texte(self, rect.position + Vector2(largeur / 2.0, 90.0),
				str(fiche.crete).capitalize(), 13, Identite.TEXTE_ATTENUE, true, 4)
			_actions.append({"rect": rect, "action": "perso:%s" % nom})
			# Garde-robe : pastilles de variantes (cadenas si verrouillée).
			var palette: Array = fiche.variantes
			for v in palette.size():
				var centre := rect.position + Vector2(largeur / 2.0 + (v - 1.5) * 34.0, 122.0)
				var debloquee: bool = Profil.debloquees[nom].has(v)
				var teinte: Color = palette[v]
				draw_circle(centre, 15.0, Identite.CONTOUR)
				draw_circle(centre, 12.0, teinte if debloquee else Color(0.3, 0.32, 0.42))
				if int(Profil.variantes.get(nom, 0)) == v:
					draw_arc(centre, 16.0, 0.0, TAU, 24, Color.WHITE, 3.0)
				if not debloquee:
					UI.texte(self, centre + Vector2(0.0, 5.0), "✱", 13, Identite.TEXTE_ATTENUE, true, 3)
				_actions.append({"rect": Rect2(centre - Vector2(16.0, 16.0), Vector2(32.0, 32.0)),
					"action": "variante:%s:%d" % [nom, v]})
			if choisi:
				UI.texte(self, rect.position + Vector2(largeur / 2.0, rect.size.y - 14.0), "ÉQUIPÉ",
					13, Identite.OR, true, 4)
		UI.texte(self, Vector2(size.x / 2.0, size.y - 232.0),
			"Touche une carte pour choisir ton Lumin — les couleurs ✱ s'ouvrent avec les cadeaux !",
			14, Identite.TEXTE_ATTENUE, true, 4)

	## Le kit de pouvoirs équipé (slots de la planche, avec deux slots « + »).
	func _dessiner_pouvoirs() -> void:
		var infos: Array = [
			["onde", "Onde de choc", Identite.ORANGE, "Repousse (10 dégâts) et VOLE le dragon au porteur. Recharge 4 s."],
			["dash", "Dash", Identite.BLEU, "Fonce sur 6 m en un éclair. Recharge 5 s."],
			["bouclier", "Bouclier", Identite.VIOLET, "Bulle 2 s : dégâts, poussées et vols glissent. Recharge 7 s."],
		]
		var largeur := minf(size.x - 120.0, 680.0)
		var x0 := (size.x - largeur) / 2.0
		for i in infos.size():
			var ligne: Array = infos[i]
			var rect := Rect2(x0, 152.0 + i * 96.0, largeur, 84.0)
			UI.panneau(self, rect)
			var slot := Rect2(rect.position + Vector2(12.0, 10.0), Vector2(64.0, 64.0))
			UI.bouton(self, slot, ligne[2], "slot_%s" % str(ligne[0]), false, Identite.RAYON_MD)
			UI.icone_pouvoir(self, slot.get_center(), 30.0, str(ligne[0]))
			UI.texte(self, rect.position + Vector2(92.0, 34.0), str(ligne[1]), 20, Identite.OR)
			UI.texte(self, rect.position + Vector2(92.0, 62.0), str(ligne[3]), 14, Identite.TEXTE_ATTENUE)
		# Slots « + » désactivés : d'autres pouvoirs arriveront (planche).
		for i in 2:
			var slot := Rect2(x0 + i * 76.0, 152.0 + 3.0 * 96.0, 64.0, 64.0)
			self.draw_style_box(UI.style("slot_vide", Color(0.16, 0.18, 0.3), Identite.CONTOUR,
				Identite.RAYON_MD, Identite.BORD, 0), slot)
			UI.texte(self, slot.get_center() + Vector2(0.0, 8.0), "+", 26, Identite.TEXTE_ATTENUE, true, 4)
		UI.texte(self, Vector2(x0 + 176.0, 152.0 + 3.0 * 96.0 + 40.0), "De nouveaux pouvoirs arrivent bientôt…",
			14, Identite.TEXTE_ATTENUE)

	## Fenêtre récompense de la planche : coffre quotidien.
	func _dessiner_cadeaux() -> void:
		var largeur := minf(size.x - 200.0, 460.0)
		var rect := Rect2((size.x - largeur) / 2.0, 160.0, largeur, 300.0)
		var croix := UI.fenetre(self, rect, "Cadeau quotidien")
		_actions.append({"rect": croix, "action": "retour"})
		var r: Dictionary = menu.recompense
		if not r.is_empty():
			# Récompense révélée.
			UI.coffre(self, rect.get_center() + Vector2(0.0, -30.0), 90.0, true)
			var texte_gain := "+%d ⭐" % int(r.etoiles)
			if str(r.type) == "variante":
				texte_gain = "Nouvelle couleur pour %s ! (+%d ⭐)" % [str(r.nom), int(r.etoiles)]
			UI.texte(self, Vector2(rect.get_center().x, rect.end.y - 74.0), texte_gain, 18, Identite.OR, true)
			_bouton_action(Rect2(rect.get_center().x - 110.0, rect.end.y - 56.0, 220.0, 44.0),
				"personnages", Identite.VERT, "VOIR MA GARDE-ROBE", 15, Identite.RAYON_SM)
		elif Profil.cadeau_disponible():
			UI.coffre(self, rect.get_center() + Vector2(0.0, -30.0), 90.0, false)
			_bouton_action(Rect2(rect.get_center().x - 110.0, rect.end.y - 64.0, 220.0, 50.0),
				"ouvrir_cadeau", Identite.OR, "RÉCUPÉRER !", 20, Identite.RAYON_SM)
		else:
			UI.coffre(self, rect.get_center() + Vector2(0.0, -30.0), 90.0, false)
			UI.texte(self, Vector2(rect.get_center().x, rect.end.y - 64.0),
				"Coffre déjà ouvert — reviens demain !", 16, Identite.TEXTE_ATTENUE, true)
		UI.texte(self, Vector2(rect.get_center().x, rect.end.y + 26.0),
			"Chaque jour : une nouvelle couleur de Lumin ou des étoiles.", 14, Identite.TEXTE_ATTENUE, true, 4)

	## Fenêtre d'aide : la boucle du jeu en clair.
	func _dessiner_aide() -> void:
		var largeur := minf(size.x - 140.0, 620.0)
		var rect := Rect2((size.x - largeur) / 2.0, 150.0, largeur, 330.0)
		var croix := UI.fenetre(self, rect, "Comment jouer")
		_actions.append({"rect": croix, "action": "retour"})
		var lignes: Array = [
			"1. Lis la question de maths et choisis ta réponse (6 s).",
			"2. Attrape le bébé dragon — il s'enfuit quand on approche !",
			"3. Porte-le dans la zone de TA réponse : bonne zone = +100.",
			"4. Vole le dragon aux autres avec l'Onde de choc !",
			"5. Mauvaise zone : dragon lâché, gelé 2 s, réponse barrée.",
			"",
			"Mobile : joystick au pouce (gauche) + boutons de pouvoirs.",
			"Clavier : ZQSD/flèches, E/R/Espace, réponses 1-4.",
		]
		for i in lignes.size():
			UI.texte(self, rect.position + Vector2(30.0, 56.0 + i * 30.0), str(lignes[i]), 15, Identite.TEXTE)

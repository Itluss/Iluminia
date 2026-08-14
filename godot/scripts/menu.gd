class_name Menu
extends Node3D
## Le LOBBY d'Iluminia et ses sous-écrans — le tour du propriétaire :
## trophées et LIGUE à défendre, PIÈCES à dépenser, ŒUFS à faire éclore au
## SANCTUAIRE (collection des 6 dragons, compagnon de partie), BOUTIQUE
## (cadeau du jour, œufs), PERSONNAGES (héros, niveaux, garde-robe), AIDE.
## Diorama 3D animé derrière tout ; le dragon qui vole = ton compagnon.

enum Ecran { ACCUEIL, PERSONNAGES, SANCTUAIRE, BOUTIQUE, AIDE }

const NOMS := ["Max", "Zep", "Nova", "Ficelle"]

var ecran := Ecran.ACCUEIL
var perso_focus := 0             ## héros affiché sur l'écran Personnages
var recompense := {}             ## dernier cadeau du jour ouvert
var recompense_oeuf := {}        ## dernière éclosion (fenêtre de révélation)
var _dragon_pivot: Node3D
var _dragon: Personnage3D
var _persos := {}
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
	_reconstruire_dragon()

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

	# Crochet de dev : ILUMINIA_ECRAN=personnages|sanctuaire|boutique|aide.
	match OS.get_environment("ILUMINIA_ECRAN"):
		"personnages":
			ecran = Ecran.PERSONNAGES
		"sanctuaire":
			ecran = Ecran.SANCTUAIRE
		"boutique":
			ecran = Ecran.BOUTIQUE
		"aide":
			ecran = Ecran.AIDE


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


## Le dragon du diorama = ton compagnon (sa couleur d'espèce).
func _reconstruire_dragon() -> void:
	if _dragon != null:
		_dragon.queue_free()
	_dragon = Personnage3D.new()
	_dragon.genre = "dragon"
	var espece: Dictionary = Personnage3D.ESPECES.get(Profil.compagnon, {"couleur": Color(0.45, 0.82, 0.55)})
	_dragon.couleur = espece.couleur
	_dragon.position = Vector3(3.0, 2.6, 0.0)
	_dragon.regarder(Vector2(0.0, 1.0))
	_dragon_pivot.add_child(_dragon)


func _process(delta: float) -> void:
	_t += delta
	_dragon_pivot.rotation.y += delta * 0.5
	_dragon.position.y = 2.6 + sin(_t * 2.0) * 0.3
	_dragon.en_marche = true
	var perpendiculaire := Vector3(-1.0, 0.0, 1.0).normalized()
	var vers_camera := Vector3(1.0, 0.0, 1.0).normalized()
	for nom in _persos:
		var perso: Personnage3D = _persos[nom]
		var i := NOMS.find(nom)
		perso.en_marche = fmod(_t + float(i) * 1.7, 5.0) < 1.2
		perso.montrer_anneau(nom == Profil.personnage)
		var cible: Vector3
		var echelle := 1.0
		if ecran == Ecran.PERSONNAGES:
			if i == perso_focus:
				cible = vers_camera * 2.4
				echelle = 1.6
			else:
				var rang := i if i < perso_focus else i - 1
				cible = perpendiculaire * (rang - 1.0) * 2.4 - vers_camera * 2.6
				echelle = 0.85
		else:
			cible = perpendiculaire * (i - 1.5) * 2.6 - vers_camera * 1.6
		perso.position = perso.position.lerp(cible, minf(delta * 7.0, 1.0))
		perso.scale = perso.scale.lerp(Vector3.ONE * echelle, minf(delta * 7.0, 1.0))
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
			recompense_oeuf = {}
		"personnages":
			Audio.jouer("clic")
			perso_focus = maxi(NOMS.find(Profil.personnage), 0)
			ecran = Ecran.PERSONNAGES
		"sanctuaire":
			Audio.jouer("clic")
			ecran = Ecran.SANCTUAIRE
		"boutique":
			Audio.jouer("clic")
			ecran = Ecran.BOUTIQUE
		"aide":
			Audio.jouer("clic")
			ecran = Ecran.AIDE
		"son":
			Profil.basculer_son()
			Audio.jouer("clic")
		"focus_gauche":
			Audio.jouer("clic")
			perso_focus = posmod(perso_focus - 1, NOMS.size())
		"focus_droite":
			Audio.jouer("clic")
			perso_focus = posmod(perso_focus + 1, NOMS.size())
		"equiper":
			Profil.choisir_personnage(NOMS[perso_focus])
			Audio.jouer("victoire")
		"ouvrir_cadeau":
			if Profil.cadeau_disponible():
				recompense = Profil.ouvrir_cadeau()
				Audio.jouer("victoire")
		"acheter_oeuf":
			if Profil.depenser(Profil.PRIX_OEUF):
				Profil.ajouter_oeuf()
				Audio.jouer("ramasser")
			else:
				Audio.jouer("denied")
		"eclore":
			if Profil.oeufs > 0:
				recompense_oeuf = Profil.eclore()
				_reconstruire_dragon()
				Audio.jouer("victoire")
		"fermer_oeuf":
			Audio.jouer("clic")
			recompense_oeuf = {}
		_:
			var morceaux := action.split(":")
			if morceaux[0] == "variante":
				_choisir_ou_acheter_variante(morceaux[1], int(morceaux[2]))
			elif morceaux[0] == "compagnon":
				if Profil.choisir_compagnon(morceaux[1]):
					Audio.jouer("ramasser")
					_reconstruire_dragon()


## Variante accessible → équipée ; verrouillée → achat direct en pièces.
func _choisir_ou_acheter_variante(nom: String, indice: int) -> void:
	if Profil.choisir_variante(nom, indice):
		Audio.jouer("clic")
		_reconstruire_persos()
	elif Profil.acheter_variante(nom, indice):
		Profil.choisir_variante(nom, indice)
		Audio.jouer("victoire")
		_reconstruire_persos()
	else:
		Audio.jouer("denied")


func _jouer() -> void:
	_lancement = true
	Audio.jouer("clic")
	Audio.jouer("depart")
	get_tree().change_scene_to_file.call_deferred("res://scenes/jeu.tscn")


## Toute l'interface du lobby ; chaque _draw() reconstruit `_actions`.
class SurfaceMenu extends Control:
	var menu: Menu = null
	var _actions: Array = []

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
			Menu.Ecran.SANCTUAIRE:
				_entete_sous_ecran("SANCTUAIRE DES DRAGONS")
				_dessiner_sanctuaire()
			Menu.Ecran.BOUTIQUE:
				_entete_sous_ecran("BOUTIQUE")
				_dessiner_boutique()
			Menu.Ecran.AIDE:
				_entete_sous_ecran("COMMENT JOUER")
				_dessiner_aide()

	# ---------------------------------------------------------- entêtes

	## Bandeau du haut : ligue + trophées, pièces, niveau/XP, son, aide.
	func _entete_commun() -> void:
		var ligue: Dictionary = Profil.ligue()
		# Ligue + trophées (l'insigne à défendre).
		UI.indicateur(self, Rect2(10.0, 12.0, 150.0, 46.0), ligue.couleur, str(Profil.trophees))
		UI.texte(self, Vector2(85.0, 74.0), str(ligue.nom), 13, ligue.couleur, true, 4)
		# Pièces d'or.
		UI.indicateur(self, Rect2(172.0, 12.0, 130.0, 46.0), Identite.OR, str(Profil.pieces), "piece")
		# Niveau de compte.
		UI.pastille(self, Vector2(336.0, 35.0), 21.0, Identite.VIOLET, str(Profil.niveau), 18)
		# Boutons carrés : son, aide.
		_bouton_action(Rect2(size.x - 158.0, 10.0, 66.0, 54.0), "son", Identite.BLEU,
			"♪" if Profil.son_actif else "✕", 22, Identite.RAYON_SM)
		_bouton_action(Rect2(size.x - 80.0, 10.0, 66.0, 54.0), "aide", Identite.BLEU, "?", 22, Identite.RAYON_SM)

	func _entete_sous_ecran(titre: String) -> void:
		_entete_commun()
		_bouton_action(Rect2(10.0, 84.0, 70.0, 52.0), "retour", Identite.BLEU, "←", 24, Identite.RAYON_SM)
		UI.banniere(self, Vector2(size.x / 2.0, 96.0), 340.0, titre, 21)

	# ---------------------------------------------------------- accueil

	func _dessiner_accueil() -> void:
		_entete_commun()
		var t := Time.get_ticks_msec() / 1000.0
		var centre_x := size.x / 2.0
		var ballant := sin(t * 1.6) * 4.0
		var haut := size.y * 0.2 + ballant
		for cote: float in [-1.0, 1.0]:
			_aile(Vector2(centre_x + cote * 34.0, haut - 58.0), cote)
		UI.etoile(self, Vector2(centre_x, haut - 62.0), 22.0, Identite.OR)
		UI.texte(self, Vector2(centre_x, haut), "ILUMINIA", 76, Identite.OR, true, 13)
		UI.texte(self, Vector2(centre_x, haut + 36.0), "La chasse au dragon", 24, Identite.MAGENTA, true)
		# Gros JOUER doré pulsé.
		var pulse := 1.0 + 0.045 * sin(t * 4.5)
		var bl := 330.0 * pulse
		var bh := 92.0 * pulse
		var jouer := Rect2(Vector2(centre_x - bl / 2.0, size.y * 0.6 - bh / 2.0), Vector2(bl, bh))
		UI.bouton(self, jouer, Identite.OR, "jouer", false, Identite.RAYON_LG + 4)
		UI.texte(self, Vector2(centre_x, jouer.get_center().y + 13.0), "JOUER !", 40, Identite.TEXTE, true, 11)
		_actions.append({"rect": jouer, "action": "jouer"})
		# Boutons principaux : Personnages / Sanctuaire / Boutique.
		var largeur := 252.0
		var y := size.y * 0.78
		_bouton_action(Rect2(centre_x - largeur * 1.5 - 20.0, y, largeur, 70.0), "personnages", Identite.BLEU, "PERSONNAGES", 20)
		var rect_sanctuaire := Rect2(centre_x - largeur / 2.0, y, largeur, 70.0)
		_bouton_action(rect_sanctuaire, "sanctuaire", Identite.VIOLET, "SANCTUAIRE", 20)
		var rect_boutique := Rect2(centre_x + largeur / 2.0 + 20.0, y, largeur, 70.0)
		_bouton_action(rect_boutique, "boutique", Identite.BLEU, "BOUTIQUE", 20)
		# Badges : œufs à éclore, cadeau du jour prêt.
		if Profil.oeufs > 0:
			var badge := Rect2(rect_sanctuaire.end.x - 34.0, rect_sanctuaire.position.y - 16.0, 52.0, 30.0)
			self.draw_style_box(UI.style("badge_oeuf", Identite.OR, Identite.CONTOUR, 8, 2, 2), badge)
			UI.texte(self, badge.get_center() + Vector2(0.0, 6.0), "%d🥚" % Profil.oeufs, 14, Identite.CONTOUR, true, 0)
		if Profil.cadeau_disponible():
			var badge := Rect2(rect_boutique.end.x - 38.0, rect_boutique.position.y - 16.0, 60.0, 30.0)
			self.draw_style_box(UI.style("badge", Identite.ROUGE, Identite.CONTOUR, 8, 2, 2), badge)
			UI.texte(self, badge.get_center() + Vector2(0.0, 6.0), "NEW", 15, Identite.TEXTE, true, 4)

	func _aile(pos: Vector2, cote: float) -> void:
		for i in 3:
			var l := 18.0 - i * 5.0
			draw_colored_polygon(PackedVector2Array([
				pos + Vector2(cote * (10.0 + i * 12.0), -4.0 + i * 5.0),
				pos + Vector2(cote * (10.0 + i * 12.0 + l), 2.0 + i * 5.0),
				pos + Vector2(cote * (10.0 + i * 12.0), 8.0 + i * 5.0),
			]), Identite.BLEU if i % 2 == 0 else Identite.CYAN)

	# ---------------------------------------------------------- personnages

	func _dessiner_personnages() -> void:
		var nom: String = Menu.NOMS[menu.perso_focus]
		var fiche: Dictionary = Personnage3D.FICHES[nom]
		var choisi: bool = nom == Profil.personnage
		_bouton_action(Rect2(24.0, size.y / 2.0 - 45.0, 76.0, 90.0), "focus_gauche", Identite.BLEU, "‹", 40, Identite.RAYON_MD)
		_bouton_action(Rect2(size.x - 100.0, size.y / 2.0 - 45.0, 76.0, 90.0), "focus_droite", Identite.BLEU, "›", 40, Identite.RAYON_MD)
		var largeur := minf(size.x - 220.0, 620.0)
		var rect := Rect2((size.x - largeur) / 2.0, size.y - 186.0, largeur, 172.0)
		UI.panneau(self, rect)
		var niveau_h := Profil.niveau_heros(nom)
		UI.texte(self, rect.position + Vector2(24.0, 38.0), nom, 30, Identite.OR if choisi else Identite.TEXTE)
		UI.texte(self, rect.position + Vector2(24.0, 62.0), "Crête-lumière : %s" % str(fiche.crete), 14, Identite.TEXTE_ATTENUE)
		UI.pastille(self, rect.position + Vector2(largeur - 200.0, 40.0), 22.0, Identite.VIOLET, str(niveau_h), 20)
		UI.texte(self, rect.position + Vector2(largeur - 168.0, 30.0), "Niveau du héros", 14, Identite.TEXTE_ATTENUE)
		UI.barre(self, Rect2(rect.position + Vector2(largeur - 168.0, 38.0), Vector2(144.0, 18.0)),
			Profil.progres_heros(nom), Identite.VIOLET)
		# Garde-robe : paliers de niveau OU achat direct en pièces.
		var palette: Array = fiche.variantes
		for v in palette.size():
			var centre := rect.position + Vector2(52.0 + v * 74.0, 108.0)
			var accessible := Profil.variante_accessible(nom, v)
			var teinte: Color = palette[v]
			draw_circle(centre, 26.0, Identite.CONTOUR)
			draw_circle(centre, 22.0, teinte if accessible else Color(0.3, 0.32, 0.42))
			if accessible:
				draw_circle(centre + Vector2(0.0, -8.0), 11.0, Color(1.0, 1.0, 1.0, 0.22))
			if int(Profil.variantes.get(nom, 0)) == v:
				draw_arc(centre, 29.0, 0.0, TAU, 32, Color.WHITE, 4.0)
			if not accessible:
				UI.texte(self, centre + Vector2(0.0, 5.0), "Niv %d" % Profil.PALIERS_VARIANTES[v], 12, Identite.TEXTE, true, 4)
				UI.texte(self, centre + Vector2(0.0, 42.0), "%d P" % Profil.PRIX_VARIANTE, 12, Identite.OR, true, 4)
			_actions.append({"rect": Rect2(centre - Vector2(30.0, 30.0), Vector2(60.0, 60.0)),
				"action": "variante:%s:%d" % [nom, v]})
		UI.texte(self, rect.position + Vector2(24.0, 160.0),
			"Joue avec %s pour monter son niveau — ou achète ses couleurs en pièces !" % nom, 13, Identite.TEXTE_ATTENUE)
		if choisi:
			var badge := Rect2(rect.end.x - 186.0, rect.end.y - 70.0, 162.0, 50.0)
			self.draw_style_box(UI.style("equipe", Identite.VERT_SOMBRE, Identite.CONTOUR, Identite.RAYON_MD, Identite.BORD, 3), badge)
			UI.texte(self, badge.get_center() + Vector2(0.0, 7.0), "✓ ÉQUIPÉ", 19, Identite.TEXTE, true)
		else:
			_bouton_action(Rect2(rect.end.x - 206.0, rect.end.y - 74.0, 182.0, 54.0),
				"equiper", Identite.OR, "JOUER AVEC LUI", 16, Identite.RAYON_MD)

	# ---------------------------------------------------------- sanctuaire

	## La collection des 6 dragons : le BUT long terme. Chaque carte montre
	## l'espèce (ou « ??? »), sa rareté, et permet d'en faire son compagnon.
	func _dessiner_sanctuaire() -> void:
		# Bouton d'éclosion quand des œufs attendent.
		if Profil.oeufs > 0 and menu.recompense_oeuf.is_empty():
			var pulse := 1.0 + 0.04 * sin(Time.get_ticks_msec() / 200.0)
			var bl := 300.0 * pulse
			_bouton_action(Rect2(size.x / 2.0 - bl / 2.0, 122.0, bl, 54.0), "eclore",
				Identite.OR, "ÉCLORE UN ŒUF ! (%d)" % Profil.oeufs, 19, Identite.RAYON_LG)
		elif menu.recompense_oeuf.is_empty():
			UI.texte(self, Vector2(size.x / 2.0, 150.0),
				"Gagne des matchs pour remporter des œufs de dragon !", 15, Identite.TEXTE_ATTENUE, true)
		# Grille de la collection, par rareté croissante.
		var especes: Array = Personnage3D.ESPECES.keys()
		especes.sort_custom(func(a, b):
			return int(Personnage3D.ESPECES[a].rarete) < int(Personnage3D.ESPECES[b].rarete))
		var largeur := 226.0
		var x0 := (size.x - largeur * 3.0 - 32.0) / 2.0
		for i in especes.size():
			var espece: String = especes[i]
			var infos: Dictionary = Personnage3D.ESPECES[espece]
			var possede: bool = Profil.dragons.has(espece)
			var rect := Rect2(x0 + (i % 3) * (largeur + 16.0), 188.0 + (i / 3) * 140.0, largeur, 128.0)
			self.draw_style_box(UI.style("dragon_%s" % str(possede),
				Identite.PANNEAU_CLAIR if possede else Color(0.1, 0.12, 0.22),
				Identite.CONTOUR, Identite.RAYON_MD, Identite.BORD, 3), rect)
			var teinte: Color = infos.couleur
			draw_circle(rect.position + Vector2(36.0, 40.0), 24.0, Identite.CONTOUR)
			draw_circle(rect.position + Vector2(36.0, 40.0), 20.0, teinte if possede else Color(0.25, 0.27, 0.38))
			UI.texte(self, rect.position + Vector2(70.0, 34.0), espece if possede else "???", 19,
				teinte.lightened(0.2) if possede else Identite.TEXTE_ATTENUE)
			UI.texte(self, rect.position + Vector2(70.0, 56.0),
				Personnage3D.NOMS_RARETES[int(infos.rarete)], 13, Identite.TEXTE_ATTENUE)
			if possede:
				UI.texte(self, rect.position + Vector2(70.0, 76.0), "×%d" % int(Profil.dragons[espece]), 13, Identite.TEXTE)
				if Profil.compagnon == espece:
					UI.texte(self, rect.position + Vector2(largeur / 2.0, 112.0), "✓ COMPAGNON", 14, Identite.OR, true, 4)
				else:
					_bouton_action(Rect2(rect.position + Vector2(30.0, 88.0), Vector2(largeur - 60.0, 34.0)),
						"compagnon:%s" % espece, Identite.VIOLET, "COMPAGNON", 13, Identite.RAYON_SM)
		# Fenêtre d'éclosion.
		var r: Dictionary = menu.recompense_oeuf
		if not r.is_empty():
			var infos: Dictionary = Personnage3D.ESPECES[r.espece]
			var fen := Rect2(size.x / 2.0 - 220.0, 130.0, 440.0, 270.0)
			var croix := UI.fenetre(self, fen, "Un œuf éclot…")
			_actions.append({"rect": croix, "action": "fermer_oeuf"})
			var teinte: Color = infos.couleur
			draw_circle(fen.get_center() + Vector2(0.0, -34.0), 40.0, Identite.CONTOUR)
			draw_circle(fen.get_center() + Vector2(0.0, -34.0), 34.0, teinte)
			UI.texte(self, fen.get_center() + Vector2(0.0, 32.0), str(r.espece), 26, teinte.lightened(0.2), true)
			UI.texte(self, fen.get_center() + Vector2(0.0, 56.0),
				Personnage3D.NOMS_RARETES[int(infos.rarete)], 15, Identite.TEXTE_ATTENUE, true)
			if bool(r.nouveau):
				UI.texte(self, fen.get_center() + Vector2(0.0, 82.0), "NOUVEAU DRAGON !", 18, Identite.OR, true)
			else:
				UI.texte(self, fen.get_center() + Vector2(0.0, 82.0), "Doublon : +%d pièces" % int(r.pieces_bonus), 16, Identite.OR, true)

	# ---------------------------------------------------------- boutique

	func _dessiner_boutique() -> void:
		var largeur := 320.0
		var y := 150.0
		# Carte 1 : cadeau du jour (gratuit).
		var carte1 := Rect2(size.x / 2.0 - largeur - 16.0, y, largeur, 260.0)
		UI.panneau(self, carte1)
		UI.texte(self, Vector2(carte1.get_center().x, y + 34.0), "Cadeau du jour", 19, Identite.TEXTE, true)
		UI.coffre(self, carte1.get_center() + Vector2(0.0, -8.0), 74.0, not menu.recompense.is_empty())
		var r: Dictionary = menu.recompense
		if not r.is_empty():
			var texte_gain := "+80 pièces !" if str(r.type) == "pieces" else "UN ŒUF DE DRAGON !"
			UI.texte(self, Vector2(carte1.get_center().x, carte1.end.y - 44.0), texte_gain, 16, Identite.OR, true)
		elif Profil.cadeau_disponible():
			_bouton_action(Rect2(carte1.get_center().x - 100.0, carte1.end.y - 66.0, 200.0, 48.0),
				"ouvrir_cadeau", Identite.OR, "RÉCUPÉRER !", 18, Identite.RAYON_SM)
		else:
			UI.texte(self, Vector2(carte1.get_center().x, carte1.end.y - 44.0), "Reviens demain !", 15, Identite.TEXTE_ATTENUE, true)
		# Carte 2 : œuf de dragon contre des pièces.
		var carte2 := Rect2(size.x / 2.0 + 16.0, y, largeur, 260.0)
		UI.panneau(self, carte2)
		UI.texte(self, Vector2(carte2.get_center().x, y + 34.0), "Œuf de dragon", 19, Identite.TEXTE, true)
		draw_circle(carte2.get_center() + Vector2(0.0, -8.0), 42.0, Identite.CONTOUR)
		draw_circle(carte2.get_center() + Vector2(0.0, -8.0), 36.0, Identite.CREME)
		draw_circle(carte2.get_center() + Vector2(-10.0, -20.0), 8.0, Color(1.0, 1.0, 1.0, 0.5))
		_bouton_action(Rect2(carte2.get_center().x - 110.0, carte2.end.y - 66.0, 220.0, 48.0),
			"acheter_oeuf", Identite.VERT if Profil.pieces >= Profil.PRIX_OEUF else Color(0.3, 0.32, 0.42),
			"ACHETER — %d P" % Profil.PRIX_OEUF, 16, Identite.RAYON_SM)
		UI.texte(self, Vector2(size.x / 2.0, 448.0),
			"Les couleurs des Lumins s'achètent sur l'écran PERSONNAGES (%d pièces)." % Profil.PRIX_VARIANTE,
			14, Identite.TEXTE_ATTENUE, true, 4)

	# ---------------------------------------------------------- aide

	func _dessiner_aide() -> void:
		var largeur := minf(size.x - 120.0, 640.0)
		var rect := Rect2((size.x - largeur) / 2.0, 132.0, largeur, 330.0)
		var croix := UI.fenetre(self, rect, "Comment jouer")
		_actions.append({"rect": croix, "action": "retour"})
		var lignes: Array = [
			"1. Choisis ta réponse de maths, puis ATTRAPE le bébé dragon.",
			"2. Porte-le dans la zone de TA réponse et TIENS 1,5 s : +100 !",
			"3. Vole le dragon aux autres avec l'Onde de choc (bouton orange).",
			"4. Suis la flèche-boussole : or = dragon libre, rouge = volé.",
			"",
			"1er du match : un ŒUF DE DRAGON à faire éclore au Sanctuaire.",
			"Trophées → monte de ligue. Pièces → boutique et couleurs.",
			"Ton dragon compagnon vole à tes côtés en partie !",
		]
		for i in lignes.size():
			UI.texte(self, rect.position + Vector2(30.0, 52.0 + i * 30.0), str(lignes[i]), 15, Identite.TEXTE)

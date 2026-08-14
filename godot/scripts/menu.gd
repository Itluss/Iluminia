class_name Menu
extends Node3D
## Le LOBBY d'Iluminia et ses sous-écrans — le tour du propriétaire :
## trophées et LIGUE à défendre, PIÈCES à dépenser, ŒUFS à faire éclore au
## SANCTUAIRE (collection des 6 dragons, compagnon de partie), BOUTIQUE
## (cadeau du jour, œufs), PERSONNAGES (héros, niveaux, garde-robe), AIDE.
## Diorama 3D animé derrière tout ; le dragon qui vole = ton compagnon.

enum Ecran { ACCUEIL, PERSONNAGES, SANCTUAIRE, BOUTIQUE, ROUTE, QUETES, AIDE }

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
	# Le lobby vit en PLEIN JOUR (planche Home : ciel bleu, monde coloré).
	Ambiance.installer(self, Ambiance.THEME_JOUR)

	# — Île ensoleillée du diorama —
	Materiaux.mesh(self, Materiaux.cylindre(9.0, 0.3), Materiaux.toon(Ambiance.THEME_JOUR.pelouse),
		Vector3(0.0, -0.15, 0.0), Vector3.ONE, false)
	Materiaux.mesh(self, Materiaux.tore(9.1, 0.12), Materiaux.emissif(Identite.OR, 0.8),
		Vector3(0.0, 0.05, 0.0), Vector3.ONE, false)
	# PIÉDESTAL DE PIERRE de la planche, sous les héros.
	var vers_cam := Vector3(1.0, 0.0, 1.0).normalized()
	var socle := Vector3.ZERO - vers_cam * 1.6
	Materiaux.mesh(self, Materiaux.cylindre(5.4, 0.5), Materiaux.toon(Color(0.72, 0.46, 0.53)),
		socle + Vector3(0.0, 0.12, 0.0), Vector3.ONE, false)
	Materiaux.mesh(self, Materiaux.cylindre(5.0, 0.14), Materiaux.toon(Color(0.82, 0.66, 0.66)),
		socle + Vector3(0.0, 0.42, 0.0), Vector3.ONE, false)
	Materiaux.mesh(self, Materiaux.tore(5.1, 0.09), Materiaux.toon(Color(0.58, 0.36, 0.44)),
		socle + Vector3(0.0, 0.44, 0.0), Vector3.ONE, false)
	# Nuages joufflus qui flottent au loin.
	var rng_nuages := RandomNumberGenerator.new()
	rng_nuages.seed = 42
	for i in 6:
		var nuage := Node3D.new()
		var ang := TAU * i / 6.0 + rng_nuages.randf_range(-0.4, 0.4)
		nuage.position = Vector3(cos(ang) * rng_nuages.randf_range(14.0, 22.0),
			rng_nuages.randf_range(4.0, 9.0), sin(ang) * rng_nuages.randf_range(14.0, 22.0))
		add_child(nuage)
		for b in 3:
			Materiaux.mesh(nuage, Materiaux.sphere(rng_nuages.randf_range(0.9, 1.6)),
				Materiaux.toon(Color(0.98, 0.99, 1.0)),
				Vector3(b * 1.3 - 1.3, rng_nuages.randf_range(-0.2, 0.3), 0.0),
				Vector3(1.0, 0.62, 0.85), false)
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

	# Crochet de dev : ILUMINIA_ECRAN=personnages|sanctuaire|boutique|route|quetes|aide.
	match OS.get_environment("ILUMINIA_ECRAN"):
		"personnages":
			ecran = Ecran.PERSONNAGES
		"sanctuaire":
			ecran = Ecran.SANCTUAIRE
		"boutique":
			ecran = Ecran.BOUTIQUE
		"route":
			ecran = Ecran.ROUTE
		"quetes":
			ecran = Ecran.QUETES
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
		perso.position = perpendiculaire * (i - 1.5) * 2.6 - vers_camera * 1.6 + Vector3(0.0, 0.49, 0.0)
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
	var perpendiculaire := Vector3(-1.0, 0.0, 1.0).normalized()
	var vers_camera := Vector3(1.0, 0.0, 1.0).normalized()
	var socle := -vers_camera * 1.6
	# Le compagnon dragon volette à côté du héros, comme le chien de la
	# planche Home (plus d'orbite : il reste près du piédestal).
	_dragon_pivot.rotation.y = 0.0
	var cible_dragon := socle + perpendiculaire * -2.0 + vers_camera * 0.7
	cible_dragon.y = 1.05 + sin(_t * 2.0) * 0.2
	_dragon.position = _dragon.position.lerp(cible_dragon, minf(delta * 4.0, 1.0))
	_dragon.regarder(Vector2(1.0, 1.0).normalized())
	_dragon.en_marche = true
	for nom in _persos:
		var perso: Personnage3D = _persos[nom]
		var i := NOMS.find(nom)
		perso.en_marche = fmod(_t + float(i) * 1.7, 5.0) < 1.2
		perso.montrer_anneau(ecran == Ecran.PERSONNAGES and nom == Profil.personnage)
		perso.montrer_nom(ecran == Ecran.PERSONNAGES)
		var cible: Vector3
		var echelle := 1.0
		var visible_ecran := true
		if ecran == Ecran.PERSONNAGES:
			if i == perso_focus:
				# Centré dans la bande libre entre les cartes et la fiche.
				cible = vers_camera * 2.4 + perpendiculaire * 1.0
				echelle = 1.6
			else:
				var rang := i if i < perso_focus else i - 1
				cible = perpendiculaire * (rang - 1.0) * 2.4 - vers_camera * 2.6
				echelle = 0.85
		else:
			# Accueil (planche Home) : SEUL le héros équipé, en grand, sur
			# le piédestal avec son compagnon.
			cible = socle + perpendiculaire * 0.4 + vers_camera * 0.5
			echelle = 2.2
			visible_ecran = nom == Profil.personnage
		perso.visible = visible_ecran
		cible.y = 0.49 # les héros du lobby se tiennent sur le piédestal
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
		"route":
			Audio.jouer("clic")
			ecran = Ecran.ROUTE
		"quetes":
			Audio.jouer("clic")
			ecran = Ecran.QUETES
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
			if Profil.heros_est_debloque(NOMS[perso_focus]):
				Profil.choisir_personnage(NOMS[perso_focus])
				Audio.jouer("victoire")
			else:
				Audio.jouer("denied")
		"ameliorer":
			if Profil.ameliorer_puissance(NOMS[perso_focus]):
				Audio.jouer("victoire")
			else:
				Audio.jouer("denied")
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
			if morceaux[0] == "focus":
				Audio.jouer("clic")
				perso_focus = clampi(int(morceaux[1]), 0, NOMS.size() - 1)
			elif morceaux[0] == "variante":
				_choisir_ou_acheter_variante(morceaux[1], int(morceaux[2]))
			elif morceaux[0] == "compagnon":
				if Profil.choisir_compagnon(morceaux[1]):
					Audio.jouer("ramasser")
					_reconstruire_dragon()
			elif morceaux[0] == "reclamer_route":
				var gain: Dictionary = Profil.reclamer_route(int(morceaux[1]))
				if gain.is_empty():
					Audio.jouer("denied")
				else:
					Audio.jouer("victoire")
					_reconstruire_persos()
					_reconstruire_dragon()
			elif morceaux[0] == "reclamer_quete":
				if Profil.reclamer_quete(int(morceaux[1])) > 0:
					Audio.jouer("victoire")
				else:
					Audio.jouer("denied")


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
				# En-tête compact : la colonne de cartes occupe la gauche.
				_entete_commun()
				_bouton_action(Rect2(266.0, 12.0, 60.0, 50.0), "retour", Identite.BLEU, "←", 22, Identite.RAYON_SM)
				_dessiner_personnages()
			Menu.Ecran.SANCTUAIRE:
				_entete_sous_ecran("SANCTUAIRE DES DRAGONS")
				_dessiner_sanctuaire()
			Menu.Ecran.BOUTIQUE:
				_entete_sous_ecran("BOUTIQUE")
				_dessiner_boutique()
			Menu.Ecran.ROUTE:
				_entete_sous_ecran("ROUTE DES TROPHÉES")
				_dessiner_route()
			Menu.Ecran.QUETES:
				_entete_sous_ecran("QUÊTES DU JOUR")
				_dessiner_quetes()
			Menu.Ecran.AIDE:
				_entete_sous_ecran("COMMENT JOUER")
				_dessiner_aide()

	# ---------------------------------------------------------- entêtes

	## Bandeau de la planche : CARTE PROFIL à gauche (avatar, nom, niveau
	## de compte + XP), CAPSULES de ressources (trophées → Route, pièces →
	## Boutique), boutons son / aide à droite.
	func _entete_commun() -> void:
		var ligue: Dictionary = Profil.ligue()
		# Carte profil (avatar aux couleurs du héros équipé → Personnages).
		var profil := Rect2(10.0, 10.0, 248.0, 64.0)
		UI.panneau(self, profil)
		var teinte_heros: Color = Profil.couleur_de(Profil.personnage)
		draw_circle(profil.position + Vector2(32.0, 32.0), 24.0, Identite.CONTOUR)
		draw_circle(profil.position + Vector2(32.0, 32.0), 20.0, teinte_heros)
		draw_circle(profil.position + Vector2(32.0, 24.0), 10.0, Color(1.0, 1.0, 1.0, 0.25))
		UI.texte(self, profil.position + Vector2(32.0, 40.0), Profil.personnage.left(1), 20, Identite.TEXTE, true, 4)
		UI.texte(self, profil.position + Vector2(64.0, 26.0), Profil.personnage, 16, Identite.TEXTE)
		UI.capsule_niveau(self, Rect2(profil.position + Vector2(64.0, 32.0), Vector2(170.0, 26.0)),
			Profil.niveau, Profil.progres_niveau())
		_actions.append({"rect": profil, "action": "personnages"})
		# Capsule trophées (couleur de ligue) → Route des Trophées.
		var rect_trophees := Rect2(size.x - 478.0, 14.0, 146.0, 44.0)
		UI.capsule(self, rect_trophees, ligue.couleur, str(Profil.trophees), "etoile")
		UI.texte(self, Vector2(rect_trophees.get_center().x, 74.0), str(ligue.nom), 12, ligue.couleur, true, 4)
		_actions.append({"rect": rect_trophees, "action": "route"})
		var en_attente := Profil.recompenses_en_attente()
		if en_attente > 0:
			UI.badge_notif(self, rect_trophees.position + Vector2(rect_trophees.size.x - 6.0, 2.0), str(en_attente))
		# Capsule pièces → Boutique.
		var rect_pieces := Rect2(size.x - 320.0, 14.0, 146.0, 44.0)
		UI.capsule(self, rect_pieces, Identite.OR, str(Profil.pieces), "piece")
		_actions.append({"rect": rect_pieces, "action": "boutique"})
		# Boutons carrés : son, aide.
		_bouton_action(Rect2(size.x - 158.0, 10.0, 66.0, 54.0), "son", Identite.BLEU,
			"♪" if Profil.son_actif else "✕", 22, Identite.RAYON_SM)
		_bouton_action(Rect2(size.x - 80.0, 10.0, 66.0, 54.0), "aide", Identite.BLEU, "?", 22, Identite.RAYON_SM)

	func _entete_sous_ecran(titre: String) -> void:
		_entete_commun()
		_bouton_action(Rect2(10.0, 84.0, 70.0, 52.0), "retour", Identite.BLEU, "←", 24, Identite.RAYON_SM)
		UI.banniere(self, Vector2(size.x / 2.0, 96.0), 340.0, titre, 21)

	# ---------------------------------------------------------- accueil

	## Accueil de la planche : carte profil + capsules en haut, NAVIGATION
	## à icônes et badges à gauche, CARTES ÉVÉNEMENT à droite, DÉFI DU JOUR
	## en bas à gauche, héros au centre (diorama), énorme JOUER ▶ en bas à
	## droite.
	func _dessiner_accueil() -> void:
		_entete_commun()
		var t := Time.get_ticks_msec() / 1000.0
		var centre_x := size.x / 2.0
		# Logo compact, calé sous l'en-tête pour laisser la scène au héros.
		UI.etoile(self, Vector2(centre_x, 84.0 + sin(t * 1.6) * 2.0), 12.0, Identite.OR)
		UI.texte(self, Vector2(centre_x, 118.0 + sin(t * 1.6) * 2.0), "ILUMINIA", 34, Identite.OR, true, 9)
		UI.texte(self, Vector2(centre_x, 136.0 + sin(t * 1.6) * 2.0), "La chasse au dragon", 14, Identite.MAGENTA, true, 5)
		# NAVIGATION gauche (planche : icône + libellé + badge).
		var nav: Array = [
			["personnages", "PERSONNAGES", Identite.BLEU],
			["sanctuaire", "SANCTUAIRE", Identite.VIOLET],
			["boutique", "BOUTIQUE", Identite.BLEU],
			["route", "RÉCOMPENSES", Identite.VIOLET],
		]
		for i in nav.size():
			var b: Array = nav[i]
			var rect := Rect2(16.0, 96.0 + i * 70.0, 226.0, 60.0)
			UI.bouton(self, rect, b[2], "nav_%s" % str(b[0]), false, Identite.RAYON_MD)
			UI.icone_menu(self, rect.position + Vector2(30.0, 27.0), 17.0, str(b[0]))
			UI.texte(self, rect.position + Vector2(56.0, 34.0), str(b[1]), 16, Identite.TEXTE)
			_actions.append({"rect": rect, "action": str(b[0])})
			if str(b[0]) == "sanctuaire" and Profil.oeufs > 0:
				UI.badge_notif(self, rect.position + Vector2(rect.size.x - 4.0, 2.0), str(Profil.oeufs))
			if str(b[0]) == "boutique" and Profil.cadeau_disponible():
				UI.badge_notif(self, rect.position + Vector2(rect.size.x - 4.0, 2.0), "!")
			if str(b[0]) == "route" and Profil.recompenses_en_attente() > 0:
				UI.badge_notif(self, rect.position + Vector2(rect.size.x - 4.0, 2.0), str(Profil.recompenses_en_attente()))
		# CARTES ÉVÉNEMENT à droite (planche : coffre gratuit, événements).
		var y_carte := 96.0
		if Profil.cadeau_disponible():
			y_carte = _carte_evenement(y_carte, "boutique", Identite.OR, "COFFRE GRATUIT", "Prêt !")
		if Profil.oeufs > 0:
			y_carte = _carte_evenement(y_carte, "sanctuaire", Identite.VIOLET, "ŒUF DE DRAGON", "Prêt à éclore !")
		var a_reclamer := Profil.quetes_a_reclamer()
		y_carte = _carte_evenement(y_carte, "quetes", Identite.BLEU, "QUÊTES DU JOUR",
			"%d à réclamer !" % a_reclamer if a_reclamer > 0 else "3 défis quotidiens")
		if a_reclamer > 0:
			UI.badge_notif(self, Vector2(size.x - 20.0, y_carte - 66.0), str(a_reclamer))
		# DÉFI DU JOUR en bas à gauche (planche) : la 1re quête en cours.
		_carte_defi_du_jour()
		# L'énorme JOUER ▶ (planche : biseau, triangle, pulsation).
		var pulse := 1.0 + 0.045 * sin(t * 4.5)
		var bl := 300.0 * pulse
		var bh := 96.0 * pulse
		var jouer := Rect2(Vector2(size.x - 16.0 - bl, size.y - 120.0 - (bh - 96.0) / 2.0), Vector2(bl, bh))
		UI.bouton(self, jouer, Identite.OR, "jouer", false, Identite.RAYON_LG + 4)
		UI.triangle_jouer(self, Vector2(jouer.position.x + 56.0, jouer.get_center().y - 3.0), 26.0, Identite.TEXTE)
		UI.texte(self, Vector2(jouer.get_center().x + 26.0, jouer.get_center().y + 10.0), "JOUER", 38, Identite.TEXTE, true, 11)
		_actions.append({"rect": jouer, "action": "jouer"})
		# Le héros équipé, nommé sous la scène centrale.
		UI.texte(self, Vector2(centre_x, size.y - 20.0),
			"%s — Puissance %d" % [Profil.personnage, Profil.puissance_de(Profil.personnage)],
			16, Identite.TEXTE, true, 5)

	## Carte événement de la colonne droite ; retourne l'y suivant.
	func _carte_evenement(y: float, action: String, teinte: Color, titre: String, detail: String) -> float:
		var rect := Rect2(size.x - 266.0, y, 250.0, 62.0)
		self.draw_style_box(UI.style("evenement_%s" % action, Identite.PANNEAU, teinte,
			Identite.RAYON_MD, Identite.BORD, 3), rect)
		self.draw_style_box(UI.style("evenement_bande_%s" % teinte.to_html(false), teinte.darkened(0.15),
			Color(0, 0, 0, 0), Identite.RAYON_SM, 0, 0),
			Rect2(rect.position + Vector2(4.0, 4.0), Vector2(rect.size.x - 8.0, 24.0)))
		UI.texte(self, rect.position + Vector2(12.0, 22.0), titre, 14, Identite.TEXTE, false, 4)
		UI.texte(self, rect.position + Vector2(12.0, 50.0), detail, 14, Identite.OR if action == "boutique" else Identite.TEXTE_ATTENUE)
		_actions.append({"rect": rect, "action": action})
		return y + 72.0

	## DÉFI DU JOUR (planche) : première quête non réclamée + progression.
	func _carte_defi_du_jour() -> void:
		var quete := {}
		var indice := -1
		for i in Profil.quetes.size():
			var q: Dictionary = Profil.quetes[i]
			if not bool(q.reclamee):
				quete = q
				indice = i
				break
		if indice == -1:
			return
		var rect := Rect2(16.0, size.y - 116.0, 296.0, 96.0)
		UI.panneau(self, rect)
		var fini: bool = int(quete.progres) >= int(quete.cible)
		# Pastille gemme + titre.
		UI.hexagone(self, rect.position + Vector2(26.0, 24.0), 13.0, Identite.CYAN, "", 12)
		UI.texte(self, rect.position + Vector2(46.0, 28.0), "DÉFI DU JOUR", 14, Identite.CYAN)
		UI.texte(self, rect.position + Vector2(rect.size.x - 14.0 - 60.0, 28.0),
			"%d / %d" % [int(quete.progres), int(quete.cible)], 14, Identite.TEXTE_ATTENUE)
		UI.texte(self, rect.position + Vector2(16.0, 52.0), str(quete.texte), 13, Identite.TEXTE)
		UI.barre(self, Rect2(rect.position + Vector2(16.0, 62.0), Vector2(rect.size.x - 110.0, 20.0)),
			float(quete.progres) / float(quete.cible), Identite.VERT if fini else Identite.BLEU)
		UI.texte(self, Vector2(rect.end.x - 46.0, rect.position.y + 78.0), "+%d P" % int(quete.pieces), 14, Identite.OR, true, 4)
		_actions.append({"rect": rect, "action": "quetes"})

	# ---------------------------------------------------------- personnages

	## Écran de la planche : COLONNE DE CARTES de héros à gauche (rareté,
	## niveau, verrous, ✓ équipé), héros 3D au centre, FICHE DÉTAIL à
	## droite (rôle, description, stats réelles, compétences, tenues,
	## AMÉLIORER / ÉQUIPER).
	func _dessiner_personnages() -> void:
		# — Colonne de sélection (cartes de la planche) —
		for i in Menu.NOMS.size():
			_carte_heros(i)
		# — Fiche détail du héros au focus —
		var nom: String = Menu.NOMS[menu.perso_focus]
		var fiche: Dictionary = Personnage3D.FICHES[nom]
		var choisi: bool = nom == Profil.personnage
		var debloque: bool = Profil.heros_est_debloque(nom)
		var rect := Rect2(size.x - 336.0, 84.0, 326.0, size.y - 96.0)
		UI.panneau(self, rect)
		var x := rect.position.x + 16.0
		UI.texte(self, Vector2(x, rect.position.y + 34.0), nom, 28, Identite.OR if choisi else Identite.TEXTE)
		UI.badge_rarete(self, Vector2(rect.end.x - 74.0, rect.position.y + 26.0), str(fiche.rarete), 12)
		UI.texte(self, Vector2(x, rect.position.y + 52.0), "RÔLE : %s" % str(fiche.role).to_upper(), 13, Identite.CYAN)
		UI.texte(self, Vector2(x, rect.position.y + 70.0), str(fiche.descr), 12, Identite.TEXTE_ATTENUE)
		# Stats RÉELLES (barres segmentées de la planche).
		var stats: Dictionary = fiche.stats
		var bonus := Profil.bonus_puissance(nom)
		var lignes_stats: Array = [
			["VITESSE", float(stats.vitesse) * bonus / 1.15, "×%.2f" % (float(stats.vitesse) * bonus), Identite.BLEU],
			["ÉNERGIE", float(stats.energie) / 120.0, str(int(stats.energie)), Identite.VERT],
			["PORTÉE", (3.2 + float(stats.portee)) / 4.0, "%.1f u" % (3.2 + float(stats.portee)), Identite.ORANGE],
		]
		for s in lignes_stats.size():
			var ligne: Array = lignes_stats[s]
			var y := rect.position.y + 84.0 + s * 26.0
			UI.texte(self, Vector2(x, y + 14.0), str(ligne[0]), 12, Identite.TEXTE_ATTENUE)
			UI.barre_stat(self, Rect2(x + 76.0, y, 160.0, 18.0), float(ligne[1]), ligne[3])
			UI.texte(self, Vector2(x + 244.0, y + 14.0), str(ligne[2]), 12, Identite.TEXTE)
		# COMPÉTENCES (cartes de la planche) : les 3 pouvoirs + le Super.
		var p := Profil.puissance_de(nom)
		UI.texte(self, Vector2(x, rect.position.y + 178.0), "COMPÉTENCES", 13, Identite.TEXTE_ATTENUE)
		var comps: Array = [["onde", Identite.ORANGE], ["dash", Identite.BLEU],
			["bouclier", Identite.VIOLET], ["super", Identite.OR]]
		for ci in comps.size():
			var comp: Array = comps[ci]
			var carte := Rect2(x + ci * 74.0, rect.position.y + 188.0, 64.0, 60.0)
			self.draw_style_box(UI.style("comp_%s" % str(comp[0]), Identite.NUIT, comp[1],
				Identite.RAYON_SM, Identite.BORD, 2), carte)
			if str(comp[0]) == "super":
				UI.etoile(self, carte.get_center() + Vector2(0.0, -6.0), 13.0, Identite.OR)
			else:
				UI.icone_pouvoir(self, carte.get_center() + Vector2(0.0, -6.0), 20.0, str(comp[0]))
			UI.texte(self, Vector2(carte.get_center().x, carte.end.y - 7.0), "Niv. %d" % p, 11, Identite.TEXTE, true, 3)
		UI.texte(self, Vector2(x, rect.position.y + 266.0),
			"SUPER : %s" % str(Chasseur.NOMS_SUPERS.get(nom, "")), 12, Identite.OR)
		# TENUES (vignettes de la planche) : la garde-robe de couleurs.
		UI.texte(self, Vector2(x, rect.position.y + 288.0),
			"TENUES  (déblocage : niveau du héros ou %d pièces)" % Profil.PRIX_VARIANTE, 12, Identite.TEXTE_ATTENUE)
		var palette: Array = fiche.variantes
		for v in palette.size():
			var centre := Vector2(x + 22.0 + v * 60.0, rect.position.y + 316.0)
			var accessible := Profil.variante_accessible(nom, v)
			var teinte: Color = palette[v]
			draw_circle(centre, 22.0, Identite.CONTOUR)
			draw_circle(centre, 18.0, teinte if accessible else Color(0.3, 0.32, 0.42))
			if accessible:
				draw_circle(centre + Vector2(0.0, -6.0), 9.0, Color(1.0, 1.0, 1.0, 0.22))
			if int(Profil.variantes.get(nom, 0)) == v:
				draw_arc(centre, 25.0, 0.0, TAU, 32, Identite.OR, 4.0)
				UI.pastille(self, centre + Vector2(15.0, 13.0), 8.0, Identite.VERT, "✓", 10)
			if not accessible:
				UI.texte(self, centre + Vector2(0.0, 4.0), "Niv %d" % Profil.PALIERS_VARIANTES[v], 10, Identite.TEXTE, true, 3)
			_actions.append({"rect": Rect2(centre - Vector2(26.0, 26.0), Vector2(52.0, 52.0)),
				"action": "variante:%s:%d" % [nom, v]})
		# Pied de fiche : AMÉLIORER (bouton or de la planche) + état.
		var cout := Profil.cout_puissance(nom)
		var y_bas := rect.end.y - 60.0
		if not debloque:
			var badge := Rect2(rect.position.x + 14.0, y_bas, rect.size.x - 28.0, 48.0)
			self.draw_style_box(UI.style("verrou", Color(0.3, 0.32, 0.42), Identite.CONTOUR, Identite.RAYON_MD, Identite.BORD, 3), badge)
			UI.texte(self, badge.get_center() + Vector2(0.0, -3.0), "SE DÉBLOQUE À", 12, Identite.TEXTE_ATTENUE, true, 4)
			UI.texte(self, badge.get_center() + Vector2(0.0, 15.0), "%d TROPHÉES (Route)" % Profil.seuil_du_heros(nom), 14, Identite.OR, true, 4)
		else:
			if cout > 0:
				var r_up := Rect2(rect.position.x + 14.0, y_bas, 178.0, 48.0)
				UI.bouton(self, r_up, Identite.OR if Profil.pieces >= cout else Color(0.3, 0.32, 0.42),
					"ameliorer_%s" % str(Profil.pieces >= cout), false, Identite.RAYON_MD)
				UI.texte(self, r_up.get_center() + Vector2(0.0, -2.0), "⬆ AMÉLIORER", 15, Identite.TEXTE, true, 4)
				UI.texte(self, r_up.get_center() + Vector2(0.0, 15.0), "%d pièces — Puissance %d" % [cout, p + 1], 11, Identite.TEXTE, true, 3)
				_actions.append({"rect": r_up, "action": "ameliorer"})
			if choisi:
				var badge := Rect2(rect.end.x - 122.0, y_bas, 108.0, 48.0)
				self.draw_style_box(UI.style("equipe", Identite.VERT_SOMBRE, Identite.CONTOUR, Identite.RAYON_MD, Identite.BORD, 3), badge)
				UI.texte(self, badge.get_center() + Vector2(0.0, 6.0), "✓ ÉQUIPÉ", 15, Identite.TEXTE, true, 4)
			else:
				_bouton_action(Rect2(rect.end.x - 136.0, y_bas, 122.0, 48.0),
					"equiper", Identite.VERT, "ÉQUIPER", 15, Identite.RAYON_MD)

	## Carte de héros de la colonne de sélection (planche : cadre de
	## rareté, avatar, nom, niveau + XP, verrou, ✓ équipé, focus doré).
	func _carte_heros(i: int) -> void:
		var nom: String = Menu.NOMS[i]
		var fiche: Dictionary = Personnage3D.FICHES[nom]
		var teinte_rarete: Color = Identite.RARETES.get(str(fiche.rarete), Identite.VERT)
		var debloque := Profil.heros_est_debloque(nom)
		var focus: bool = i == menu.perso_focus
		var rect := Rect2(12.0, 84.0 + i * 96.0, 198.0, 88.0)
		self.draw_style_box(UI.style("heros_%s_%s" % [nom, str(focus)],
			Identite.PANNEAU if debloque else Color(0.1, 0.12, 0.22),
			Identite.OR if focus else teinte_rarete, Identite.RAYON_MD,
			Identite.BORD_FORT if focus else Identite.BORD, 3), rect)
		# Avatar rond aux couleurs du héros (gris si verrouillé).
		var centre := rect.position + Vector2(30.0, 44.0)
		var teinte: Color = Profil.couleur_de(nom) if debloque else Color(0.35, 0.37, 0.47)
		draw_circle(centre, 22.0, Identite.CONTOUR)
		draw_circle(centre, 18.0, teinte)
		if debloque:
			draw_circle(centre + Vector2(0.0, -7.0), 9.0, Color(1.0, 1.0, 1.0, 0.25))
			UI.texte(self, centre + Vector2(0.0, 7.0), nom.left(1), 16, Identite.TEXTE, true, 4)
		else:
			# Cadenas dessiné (l'emoji ne rend pas dans la police embarquée).
			draw_arc(centre + Vector2(0.0, -4.0), 6.0, PI, TAU, 12, Identite.CREME, 3.0)
			draw_rect(Rect2(centre + Vector2(-8.0, -4.0), Vector2(16.0, 12.0)), Identite.CREME)
			draw_circle(centre + Vector2(0.0, 2.0), 2.4, Identite.CONTOUR)
		UI.texte(self, rect.position + Vector2(60.0, 30.0), nom, 16,
			Identite.OR if nom == Profil.personnage else Identite.TEXTE)
		if nom == Profil.personnage:
			UI.pastille(self, rect.position + Vector2(rect.size.x - 18.0, 16.0), 9.0, Identite.VERT, "✓", 11)
		if debloque:
			UI.etoile(self, rect.position + Vector2(66.0, 46.0), 7.0, Identite.OR)
			UI.texte(self, rect.position + Vector2(78.0, 51.0), "Niveau %d" % Profil.niveau_heros(nom), 12, Identite.OR)
			UI.barre(self, Rect2(rect.position + Vector2(60.0, 60.0), Vector2(126.0, 14.0)),
				Profil.progres_heros(nom), Identite.BLEU)
		else:
			UI.texte(self, rect.position + Vector2(60.0, 52.0), "%d 🏆 requis" % Profil.seuil_du_heros(nom), 12, Identite.TEXTE_ATTENUE)
		UI.badge_rarete(self, Vector2(rect.position.x + 128.0, rect.position.y + 12.0), str(fiche.rarete), 9)
		_actions.append({"rect": rect, "action": "focus:%d" % i})

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
			UI.badge_rarete(self, rect.position + Vector2(112.0, 52.0),
				Personnage3D.NOMS_RARETES[int(infos.rarete)], 10)
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

	# ---------------------------------------------------------- route des trophées

	## La colonne vertébrale : les prochains paliers et leurs récompenses.
	func _dessiner_route() -> void:
		UI.texte(self, Vector2(size.x / 2.0, 138.0), "%d trophées — gagne des matchs pour avancer !" % Profil.trophees,
			15, Identite.TEXTE_ATTENUE, true)
		# Les 6 paliers autour de la position du joueur (passés réclamés exclus).
		var visibles: Array = []
		for palier in Profil.ROUTE:
			var seuil: int = int(palier.seuil)
			if not Profil.route_reclamee.has(seuil) or visibles.size() < 2:
				visibles.append(palier)
			if visibles.size() >= 6:
				break
		var largeur := minf(size.x - 160.0, 660.0)
		var x0 := (size.x - largeur) / 2.0
		for i in visibles.size():
			var palier: Dictionary = visibles[i]
			var seuil: int = int(palier.seuil)
			var atteint: bool = Profil.trophees >= seuil
			var reclame: bool = Profil.route_reclamee.has(seuil)
			var rect := Rect2(x0, 152.0 + i * 54.0, largeur, 46.0)
			self.draw_style_box(UI.style("route_%s_%s" % [str(atteint), str(reclame)],
				Identite.PANNEAU_CLAIR if atteint and not reclame else Identite.PANNEAU,
				Identite.OR if atteint and not reclame else Identite.CONTOUR,
				Identite.RAYON_SM, Identite.BORD, 2), rect)
			UI.etoile(self, rect.position + Vector2(30.0, 23.0), 13.0,
				Identite.OR if atteint else Color(0.4, 0.42, 0.52))
			UI.texte(self, rect.position + Vector2(52.0, 30.0), str(seuil), 17,
				Identite.TEXTE if atteint else Identite.TEXTE_ATTENUE)
			var description := ""
			match str(palier.type):
				"pieces":
					description = "%d pièces d'or" % int(palier.montant)
				"oeuf":
					description = "Œuf de dragon"
				"heros":
					description = "NOUVEAU HÉROS : %s !" % str(palier.nom)
				"espece":
					description = "Dragon %s garanti" % str(palier.nom)
			UI.texte(self, rect.position + Vector2(120.0, 30.0), description, 16,
				Identite.OR if str(palier.type) == "heros" else Identite.TEXTE)
			if reclame:
				UI.texte(self, Vector2(rect.end.x - 60.0, rect.position.y + 30.0), "✓", 20, Identite.VERT, true)
			elif atteint:
				_bouton_action(Rect2(rect.end.x - 150.0, rect.position.y + 4.0, 138.0, 38.0),
					"reclamer_route:%d" % seuil, Identite.VERT, "RÉCLAMER", 15, Identite.RAYON_SM)
			else:
				UI.texte(self, Vector2(rect.end.x - 76.0, rect.position.y + 30.0),
					"%d 🏆" % seuil, 14, Identite.TEXTE_ATTENUE, true, 4)

	# ---------------------------------------------------------- quêtes du jour

	func _dessiner_quetes() -> void:
		for i in Profil.quetes.size():
			var q: Dictionary = Profil.quetes[i]
			var largeur := minf(size.x - 200.0, 600.0)
			var rect := Rect2((size.x - largeur) / 2.0, 152.0 + i * 96.0, largeur, 84.0)
			UI.panneau(self, rect)
			var fini: bool = int(q.progres) >= int(q.cible)
			var reclamee: bool = bool(q.reclamee)
			UI.texte(self, rect.position + Vector2(20.0, 32.0), str(q.texte), 17,
				Identite.TEXTE if not reclamee else Identite.TEXTE_ATTENUE)
			UI.barre(self, Rect2(rect.position + Vector2(20.0, 46.0), Vector2(largeur - 220.0, 20.0)),
				float(q.progres) / float(q.cible), Identite.VERT if fini else Identite.BLEU)
			UI.texte(self, rect.position + Vector2(largeur - 260.0, 62.0),
				"%d / %d" % [int(q.progres), int(q.cible)], 14, Identite.TEXTE_ATTENUE)
			if reclamee:
				UI.texte(self, Vector2(rect.end.x - 90.0, rect.get_center().y + 7.0), "✓ FAIT", 18, Identite.VERT, true)
			elif fini:
				_bouton_action(Rect2(rect.end.x - 170.0, rect.get_center().y - 22.0, 152.0, 44.0),
					"reclamer_quete:%d" % i, Identite.VERT, "+%d P" % int(q.pieces), 17, Identite.RAYON_SM)
			else:
				UI.texte(self, Vector2(rect.end.x - 90.0, rect.get_center().y + 7.0),
					"+%d P" % int(q.pieces), 16, Identite.OR, true)
		UI.texte(self, Vector2(size.x / 2.0, 152.0 + 3.0 * 96.0 + 16.0),
			"Trois nouvelles quêtes chaque jour !", 14, Identite.TEXTE_ATTENUE, true)

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

class_name Accueil
extends Node3D
## LA HOME D'ILLUMINIA APRÈS LE PIVOT : L'ARBRE DES CONNAISSANCES.
##
## « L'arbre montre le chemin, la ville montre la récompense » : l'écran
## affiche en permanence le niveau de connaissance, l'XP manquante et LE
## PROCHAIN DÉBLOCAGE de la ville — l'enfant comprend en quelques
## secondes « si j'avance ici, je vais obtenir ça ».
##
## Écrans : ARBRE (home), COLLECTION, PROGRESSION (paliers), ESPACE
## PARENT (séparé de l'expérience enfant), choix de CLASSE au premier
## lancement. Navigation : APPRENDRE / MA VILLE / COLLECTION /
## PROGRESSION. Mobile paysage, aucun défilement.

enum Ecran { ARBRE, COLLECTION, PROGRESSION, PARENT }

var ecran := Ecran.ARBRE
var competence_ouverte := ""     ## fiche de compétence affichée
var _t := 0.0
var _heros: Personnage3D
var _compagnon: Personnage3D
var surface: SurfaceAccueil


func _ready() -> void:
	Ambiance.installer(self, Ambiance.THEME_JOUR)
	# Diorama discret : l'île, le héros et son compagnon vivent derrière
	# l'arbre (continuité de la DA, sans voler la vedette).
	Materiaux.mesh(self, Materiaux.cylindre(9.0, 0.3), Materiaux.toon(Ambiance.THEME_JOUR.pelouse),
		Vector3(0.0, -0.15, 0.0), Vector3.ONE, false)
	Materiaux.mesh(self, Materiaux.tore(9.1, 0.12), Materiaux.emissif(Identite.OR, 0.7),
		Vector3(0.0, 0.05, 0.0), Vector3.ONE, false)
	var falaise := CylinderMesh.new()
	falaise.top_radius = 9.4
	falaise.bottom_radius = 1.6
	falaise.height = 8.0
	falaise.radial_segments = 24
	Materiaux.mesh(self, falaise, Materiaux.toon(Identite.ROCHE), Vector3(0.0, -4.3, 0.0), Vector3.ONE, false)
	_heros = Personnage3D.new()
	_heros.genre = "chasseur"
	_heros.etiquette = Profil.personnage
	_heros.couleur = Profil.couleur_de(Profil.personnage)
	_heros.utiliser_fiche_couleur = false
	_heros.puissance = Profil.puissance_de(Profil.personnage)
	_heros.position = Vector3(-3.4, 0.0, 3.4)
	add_child(_heros)
	_heros.regarder(Vector2.ONE.normalized())
	_heros.montrer_nom(false)
	if Personnage3D.ESPECES.has(Profil.compagnon):
		_compagnon = Personnage3D.new()
		_compagnon.genre = "dragon"
		_compagnon.couleur = Personnage3D.ESPECES[Profil.compagnon].couleur
		_compagnon.position = Vector3(-4.8, 1.0, 2.4)
		add_child(_compagnon)

	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 10.5
	camera.position = Vector3(10.0, 11.0, 10.0)
	add_child(camera)
	camera.look_at(Vector3(0.0, 1.4, 0.0))
	camera.current = true

	var couche := CanvasLayer.new()
	add_child(couche)
	surface = SurfaceAccueil.new()
	surface.accueil = self
	surface.set_anchors_preset(Control.PRESET_FULL_RECT)
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	couche.add_child(surface)

	# Crochets de dev (captures) : ILUMINIA_CLASSE saute l'accueil de
	# bienvenue ; ILUMINIA_ECRAN=collection|progression|parent.
	if OS.get_environment("ILUMINIA_CLASSE") != "":
		Profil.classe = OS.get_environment("ILUMINIA_CLASSE")
	match OS.get_environment("ILUMINIA_ECRAN"):
		"collection":
			ecran = Ecran.COLLECTION
		"progression":
			ecran = Ecran.PROGRESSION
		"parent":
			ecran = Ecran.PARENT


func _process(delta: float) -> void:
	_t += delta
	if _heros != null:
		_heros.en_marche = fmod(_t, 6.0) < 1.4
	if _compagnon != null:
		_compagnon.position.y = 1.0 + sin(_t * 2.0) * 0.2
		_compagnon.en_marche = true
	surface.queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		var action := surface.action_sous(event.position)
		if action != "":
			_executer(action)


func _executer(action: String) -> void:
	var morceaux := action.split(":")
	match morceaux[0]:
		"retour":
			Audio.jouer("clic")
			ecran = Ecran.ARBRE
			competence_ouverte = ""
		"collection":
			Audio.jouer("clic")
			ecran = Ecran.COLLECTION
		"progression":
			Audio.jouer("clic")
			ecran = Ecran.PROGRESSION
		"parent":
			Audio.jouer("clic")
			ecran = Ecran.PARENT
		"ville":
			Audio.jouer("clic")
			get_tree().change_scene_to_file.call_deferred("res://scenes/ville.tscn")
		"son":
			Profil.basculer_son()
			Audio.jouer("clic")
		"classe":
			Audio.jouer("victoire")
			Profil.classe = morceaux[1]
			Profil.sauver()
		"competence":
			Audio.jouer("clic")
			competence_ouverte = morceaux[1]
		"fermer_competence":
			Audio.jouer("clic")
			competence_ouverte = ""
		"session":
			# La session pédagogique complète est LE prochain chantier.
			Audio.jouer("denied")


## Toute l'interface ; chaque _draw() reconstruit `_actions`.
class SurfaceAccueil extends Control:
	var accueil: Accueil = null
	var _actions: Array = []

	## Symboles d'état — REPRÉSENTATION visuelle uniquement (le métier vit
	## dans savoir.gd et peut évoluer sans le toucher).
	const COULEURS_ETATS := {
		"verrouillee": Color(0.35, 0.37, 0.47), "decouverte": Color("20cff3"),
		"apprentissage": Color("258cff"), "acquise": Color("53cc55"),
		"maitrisee": Color("ffc928"), "a_consolider": Color("ff9418"),
	}
	const NOMS_ETATS := {
		"verrouillee": "Verrouillée", "decouverte": "À découvrir",
		"apprentissage": "En apprentissage", "acquise": "Acquise",
		"maitrisee": "Maîtrisée", "a_consolider": "À consolider",
	}

	func action_sous(pos: Vector2) -> String:
		for a in _actions:
			var rect: Rect2 = a.rect
			if rect.has_point(pos):
				return str(a.action)
		return ""

	func _bouton_action(rect: Rect2, action: String, fond: Color, txt: String, taille := 18, rayon := Identite.RAYON_MD) -> void:
		UI.bouton(self, rect, fond, "acc_%s" % action, false, rayon)
		UI.texte(self, rect.get_center() + Vector2(0.0, taille * 0.36), txt, taille, Identite.TEXTE, true)
		_actions.append({"rect": rect, "action": action})

	func _draw() -> void:
		_actions = []
		# Voile : l'arbre doit rester parfaitement lisible sur le diorama.
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.09, 0.22, 0.62))
		match accueil.ecran:
			Accueil.Ecran.ARBRE:
				_dessiner_entete()
				_dessiner_arbre()
				_dessiner_navigation()
			Accueil.Ecran.COLLECTION:
				_dessiner_entete()
				_sous_titre("COLLECTION")
				_dessiner_collection()
			Accueil.Ecran.PROGRESSION:
				_dessiner_entete()
				_sous_titre("PROGRESSION & PALIERS")
				_dessiner_progression()
			Accueil.Ecran.PARENT:
				_dessiner_parent()
		if Profil.classe == "":
			_dessiner_choix_classe()

	# ------------------------------------------------------------ entête

	## L'entête raconte POURQUOI apprendre : niveau de connaissance, XP
	## manquante et PROCHAIN DÉBLOCAGE de la ville, toujours visibles.
	func _dessiner_entete() -> void:
		var profil := Rect2(10.0, 10.0, 200.0, 62.0)
		UI.panneau(self, profil)
		draw_circle(profil.position + Vector2(30.0, 31.0), 26.0, Identite.CONTOUR)
		draw_circle(profil.position + Vector2(30.0, 31.0), 23.0, Identite.VIOLET)
		UI.image(self, "avatar-%s" % Profil.personnage.to_lower(),
			Rect2(profil.position + Vector2(9.0, 10.0), Vector2(42.0, 42.0)))
		UI.texte(self, profil.position + Vector2(60.0, 26.0), Profil.personnage, 15, Identite.TEXTE)
		UI.texte(self, profil.position + Vector2(60.0, 48.0),
			Profil.classe if Profil.classe != "" else "…", 13, Identite.CYAN)
		# NIVEAU DE CONNAISSANCE + prochain déblocage (le désir, point 40).
		var palier := Cite.palier(Profil.connaissance_xp)
		var centre := Rect2(size.x / 2.0 - 240.0, 10.0, 480.0, 62.0)
		UI.panneau(self, centre)
		UI.image(self, "xp-star", Rect2(centre.position + Vector2(10.0, 16.0), Vector2(30.0, 30.0)))
		UI.texte(self, centre.position + Vector2(48.0, 26.0),
			"CONNAISSANCE — Palier %d « %s »" % [palier, str(Cite.PALIERS[palier].nom)], 15, Identite.OR)
		var prochain := Cite.prochain_palier(Profil.connaissance_xp)
		if prochain.is_empty():
			UI.texte(self, centre.position + Vector2(48.0, 50.0), "Sommet atteint — Illuminia rayonne !", 13, Identite.CYAN)
		else:
			var xp_palier := int(Cite.PALIERS[int(prochain.indice)].xp)
			var xp_avant := int(Cite.PALIERS[palier].xp)
			UI.barre(self, Rect2(centre.position + Vector2(48.0, 36.0), Vector2(200.0, 18.0)),
				float(Profil.connaissance_xp - xp_avant) / maxf(float(xp_palier - xp_avant), 1.0), Identite.CYAN)
			var recompense := ""
			for d in prochain.debloque:
				var morceaux := str(d).split(":")
				recompense = str(Cite.BATIMENTS.get(morceaux[0], {}).get("titre", morceaux[morceaux.size() - 1]))
				break
			UI.texte(self, centre.position + Vector2(256.0, 50.0),
				"Encore %d XP → %s !" % [int(prochain.xp_manquant), recompense.to_upper()], 12, Identite.OR)
		# Or + bouton parent + son.
		UI.capsule(self, Rect2(size.x - 300.0, 14.0, 130.0, 44.0), Identite.OR, str(Profil.pieces), "piece", false)
		_bouton_action(Rect2(size.x - 158.0, 10.0, 66.0, 54.0), "parent", Identite.VIOLET, "👪", 20, Identite.RAYON_SM)
		_bouton_action(Rect2(size.x - 80.0, 10.0, 66.0, 54.0), "son",
			Identite.BLEU, "♪" if Profil.son_actif else "✕", 20, Identite.RAYON_SM)

	func _sous_titre(titre: String) -> void:
		_bouton_action(Rect2(10.0, 84.0, 66.0, 48.0), "retour", Identite.BLEU, "←", 22, Identite.RAYON_SM)
		UI.banniere(self, Vector2(size.x / 2.0, 100.0), 360.0, titre, 19)

	# ------------------------------------------------------------ arbre

	## L'ARBRE DES CONNAISSANCES : tronc central (matière), quatre
	## branches (domaines), nœuds de compétences reliés. La recommandation
	## pulse ; l'enfant reste LIBRE de choisir toute branche ouverte.
	func _dessiner_arbre() -> void:
		var centre := Vector2(size.x / 2.0, size.y / 2.0 + 14.0)
		var domaines: Dictionary = Savoir.SUJETS.mathematiques.domaines
		var directions := {
			"calcul": Vector2(-1.0, -0.62), "nombres": Vector2(1.0, -0.62),
			"fractions": Vector2(-1.0, 0.72), "geometrie": Vector2(1.0, 0.72),
		}
		var recommande := Savoir.recommandation()
		# Tronc.
		UI.hexagone(self, centre, 34.0, Identite.VIOLET, "", 20)
		UI.image(self, "icon-book", Rect2(centre - Vector2(16.0, 20.0), Vector2(32.0, 32.0)))
		UI.texte(self, centre + Vector2(0.0, 52.0), "MATHÉMATIQUES", 15, Identite.TEXTE, true, 5)
		for cle in domaines:
			var dir: Vector2 = directions.get(cle, Vector2.RIGHT)
			var pos_domaine := centre + dir * Vector2(150.0, 96.0)
			draw_line(centre + dir.normalized() * 40.0, pos_domaine, Identite.PANNEAU_CLAIR, 5.0)
			UI.texte(self, pos_domaine + Vector2(0.0, -30.0), str(domaines[cle].titre).to_upper(),
				13, Identite.CYAN, true, 5)
			var liste: Array = domaines[cle].competences
			var precedent := pos_domaine
			for i in liste.size():
				var comp: Dictionary = liste[i]
				var pos := pos_domaine + Vector2(dir.x * (26.0 + i * 96.0), dir.y * 24.0 * sin(i * 1.4))
				draw_line(precedent, pos, Identite.PANNEAU_CLAIR, 4.0)
				_noeud_competence(pos, comp, str(comp.id) == recommande)
				precedent = pos
		# Recommandation en toutes lettres.
		if recommande != "":
			UI.texte(self, Vector2(size.x / 2.0, size.y - 88.0),
				"Conseillé : %s — mais c'est TOI qui choisis !" % str(Savoir.competence(recommande).titre),
				14, Identite.OR, true, 5)
		# Les autres matières existent déjà dans le modèle (bientôt).
		var matieres_futures := ["Français", "Sciences", "Histoire", "Géographie"]
		for i in matieres_futures.size():
			var p := Vector2(60.0 + i * 34.0, size.y - 96.0)
			draw_circle(p, 13.0, Identite.CONTOUR)
			draw_circle(p, 10.0, Color(0.3, 0.33, 0.47))
			UI.image(self, "icon-lock", Rect2(p - Vector2(7.0, 7.0), Vector2(14.0, 14.0)))
		UI.texte(self, Vector2(60.0, size.y - 70.0), "Bientôt…", 11, Identite.TEXTE_ATTENUE)
		# Fiche de compétence ouverte.
		if accueil.competence_ouverte != "":
			_dessiner_fiche(accueil.competence_ouverte)

	## Un nœud de l'arbre : le symbole d'état est dessiné ICI (couche de
	## représentation), jamais dans le métier.
	func _noeud_competence(pos: Vector2, comp: Dictionary, recommande: bool) -> void:
		var etat := Savoir.etat(str(comp.id))
		var teinte: Color = COULEURS_ETATS.get(etat, Identite.CYAN)
		if recommande:
			var halo := 24.0 + sin(Time.get_ticks_msec() / 180.0) * 4.0
			draw_circle(pos, halo, Color(Identite.OR.r, Identite.OR.g, Identite.OR.b, 0.35))
		draw_circle(pos, 19.0, Identite.CONTOUR)
		draw_circle(pos, 16.0, Identite.PANNEAU)
		match etat:
			"verrouillee":
				UI.image(self, "icon-lock", Rect2(pos - Vector2(9.0, 9.0), Vector2(18.0, 18.0)))
			"decouverte":
				draw_arc(pos, 11.0, 0.0, TAU, 24, teinte, 3.0)
			"apprentissage":
				draw_arc(pos, 11.0, 0.0, TAU, 24, teinte, 3.0)
				draw_circle_arc_poly(pos, 11.0, -PI / 2.0, -PI / 2.0 + TAU * 0.5, teinte)
			"acquise":
				draw_circle(pos, 11.0, teinte)
			"maitrisee":
				UI.etoile(self, pos, 12.0, teinte)
			"a_consolider":
				draw_arc(pos, 11.0, 0.0, TAU, 24, teinte, 4.0)
				UI.texte(self, pos + Vector2(0.0, 5.0), "↻", 14, teinte, true, 3)
		var titre := str(comp.titre)
		UI.texte(self, pos + Vector2(0.0, 36.0), titre, 11,
			Identite.TEXTE if etat != "verrouillee" else Identite.TEXTE_ATTENUE, true, 4)
		_actions.append({"rect": Rect2(pos - Vector2(26.0, 26.0), Vector2(52.0, 52.0)),
			"action": "competence:%s" % str(comp.id)})

	func draw_circle_arc_poly(centre: Vector2, rayon: float, debut: float, fin: float, teinte: Color) -> void:
		var pts := PackedVector2Array([centre])
		for i in 17:
			pts.append(centre + Vector2.from_angle(lerpf(debut, fin, i / 16.0)) * rayon)
		draw_colored_polygon(pts, teinte)

	## La fiche : état, score, prérequis, XP — et le point d'entrée de la
	## future session pédagogique (prochain chantier du pivot).
	func _dessiner_fiche(id: String) -> void:
		var comp := Savoir.competence(id)
		if comp.is_empty():
			return
		var etat := Savoir.etat(id)
		var rect := Rect2(size.x - 320.0, 92.0, 308.0, 264.0)
		var croix := UI.fenetre(self, rect, str(comp.titre))
		_actions.append({"rect": croix, "action": "fermer_competence"})
		var teinte: Color = COULEURS_ETATS.get(etat, Identite.CYAN)
		UI.texte(self, rect.position + Vector2(20.0, 56.0), "État : %s" % str(NOMS_ETATS.get(etat, etat)), 14, teinte)
		UI.barre(self, Rect2(rect.position + Vector2(20.0, 68.0), Vector2(rect.size.x - 40.0, 18.0)),
			Profil.score_competence(id) / 100.0, teinte)
		UI.texte(self, rect.position + Vector2(20.0, 112.0),
			"Récompense : +%d XP de connaissance" % int(comp.xp), 13, Identite.OR)
		UI.texte(self, rect.position + Vector2(20.0, 134.0),
			"Classes : %s" % ", ".join(comp.niveaux), 12, Identite.TEXTE_ATTENUE)
		if etat == "verrouillee":
			var noms_pre: Array = []
			for pre in comp.prerequis:
				noms_pre.append(str(Savoir.competence(str(pre)).titre))
			UI.texte(self, rect.position + Vector2(20.0, 158.0), "D'abord : %s" % ", ".join(noms_pre), 12, Identite.ORANGE)
		else:
			UI.texte(self, rect.position + Vector2(20.0, 158.0),
				"Diagnostic → leçon → entraînement → validation", 12, Identite.TEXTE_ATTENUE)
			_bouton_action(Rect2(rect.position.x + 20.0, rect.end.y - 62.0, rect.size.x - 40.0, 48.0),
				"session", Identite.VERT if etat != "verrouillee" else Color(0.3, 0.32, 0.42),
				"SESSION — prochaine étape !", 15)

	# ------------------------------------------------------------ navigation

	func _dessiner_navigation() -> void:
		var libelles: Array = [["retour", "APPRENDRE", Identite.VERT_SOMBRE],
			["ville", "MA VILLE", Identite.BLEU],
			["collection", "COLLECTION", Identite.VIOLET],
			["progression", "PROGRESSION", Identite.BLEU]]
		var largeur := 196.0
		var x0 := (size.x - (largeur + 10.0) * libelles.size() + 10.0) / 2.0
		for i in libelles.size():
			var l: Array = libelles[i]
			var rect := Rect2(x0 + i * (largeur + 10.0), size.y - 58.0, largeur, 50.0)
			UI.bouton(self, rect, l[2], "nav_%s" % str(l[0]), i == 0, Identite.RAYON_MD)
			UI.texte(self, rect.get_center() + Vector2(0.0, 6.0), str(l[1]), 16, Identite.TEXTE, true)
			if i > 0:
				_actions.append({"rect": rect, "action": str(l[0])})

	# ------------------------------------------------------------ collection

	func _dessiner_collection() -> void:
		UI.texte(self, Vector2(size.x / 2.0, 152.0), "HÉROS — habitants et personnages de leçons", 14, Identite.CYAN, true, 4)
		var palier := Cite.palier(Profil.connaissance_xp)
		var noms: Array = Personnage3D.FICHES.keys()
		for i in noms.size():
			var nom: String = noms[i]
			var debloque := nom == "Max" or _heros_debloque(nom, palier)
			var rect := Rect2(size.x / 2.0 - 340.0 + i * 175.0, 166.0, 160.0, 108.0)
			UI.panneau(self, rect)
			if debloque and UI.image(self, "carte-%s" % nom.to_lower(), Rect2(rect.position + Vector2(8.0, 8.0), Vector2(54.0, 70.0))):
				pass
			else:
				draw_circle(rect.position + Vector2(34.0, 44.0), 22.0, Identite.CONTOUR)
				draw_circle(rect.position + Vector2(34.0, 44.0), 18.0,
					Profil.couleur_de(nom) if debloque else Color(0.32, 0.34, 0.45))
				if not debloque:
					UI.image(self, "icon-lock", Rect2(rect.position + Vector2(22.0, 32.0), Vector2(24.0, 24.0)))
			UI.texte(self, rect.position + Vector2(70.0, 34.0), nom, 15,
				Identite.TEXTE if debloque else Identite.TEXTE_ATTENUE)
			UI.badge_rarete(self, rect.position + Vector2(104.0, 58.0), str(Personnage3D.FICHES[nom].rarete), 9)
			if not debloque:
				UI.texte(self, rect.position + Vector2(70.0, 92.0), "Palier %d" % _palier_du_heros(nom), 11, Identite.ORANGE)
		UI.texte(self, Vector2(size.x / 2.0, 306.0), "ANIMAUX & COMPAGNONS", 14, Identite.CYAN, true, 4)
		var especes: Array = Personnage3D.ESPECES.keys()
		for i in especes.size():
			var espece: String = especes[i]
			var possede: bool = Profil.dragons.has(espece)
			var p := Vector2(size.x / 2.0 - 300.0 + i * 120.0, 350.0)
			draw_circle(p, 26.0, Identite.CONTOUR)
			draw_circle(p, 22.0, Personnage3D.ESPECES[espece].couleur if possede else Color(0.3, 0.33, 0.45))
			UI.texte(self, p + Vector2(0.0, 46.0), espece if possede else "???", 12,
				Identite.TEXTE if possede else Identite.TEXTE_ATTENUE, true, 4)

	func _heros_debloque(nom: String, palier_atteint: int) -> bool:
		for i in mini(palier_atteint + 1, Cite.PALIERS.size()):
			if Cite.PALIERS[i].debloque.has("heros:%s" % nom):
				return true
		return Profil.heros_debloques.has(nom)

	func _palier_du_heros(nom: String) -> int:
		for i in Cite.PALIERS.size():
			if Cite.PALIERS[i].debloque.has("heros:%s" % nom):
				return i
		return 0

	# ------------------------------------------------------------ progression

	func _dessiner_progression() -> void:
		var palier := Cite.palier(Profil.connaissance_xp)
		var largeur := minf(size.x - 160.0, 680.0)
		var x0 := (size.x - largeur) / 2.0
		for i in Cite.PALIERS.size():
			var p: Dictionary = Cite.PALIERS[i]
			var atteint := i <= palier
			var courant := i == palier + 1
			var rect := Rect2(x0, 138.0 + i * 41.0, largeur, 35.0)
			self.draw_style_box(UI.style("palier_%s_%s" % [str(atteint), str(courant)],
				Identite.PANNEAU_CLAIR if courant else Identite.PANNEAU,
				Identite.OR if courant else (Identite.VERT_SOMBRE if atteint else Identite.CONTOUR),
				Identite.RAYON_SM, 2, 1), rect)
			UI.texte(self, rect.position + Vector2(14.0, 24.0),
				"%s%d — %s" % ["✓ " if atteint else "", i, str(p.nom)], 14,
				Identite.VERT if atteint else (Identite.OR if courant else Identite.TEXTE))
			UI.texte(self, rect.position + Vector2(220.0, 24.0), "%d XP" % int(p.xp), 12, Identite.TEXTE_ATTENUE)
			var contenus: Array = []
			for d in p.debloque:
				var m := str(d).split(":")
				contenus.append(str(Cite.BATIMENTS.get(m[0], {}).get("titre", m[m.size() - 1])))
			UI.texte(self, rect.position + Vector2(310.0, 24.0), ", ".join(contenus), 12,
				Identite.TEXTE if courant else Identite.TEXTE_ATTENUE)

	# ------------------------------------------------------------ espace parent

	## L'ESPACE PARENT : « est-ce que mon enfant apprend réellement ? »
	## Maîtrise par domaine, résumé de la semaine, détail par compétence.
	func _dessiner_parent() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.07, 0.18, 0.85))
		_bouton_action(Rect2(10.0, 12.0, 66.0, 48.0), "retour", Identite.BLEU, "←", 22, Identite.RAYON_SM)
		UI.banniere(self, Vector2(size.x / 2.0, 30.0), 340.0, "ESPACE PARENT", 18)
		UI.texte(self, Vector2(size.x / 2.0, 66.0),
			"%s — classe : %s" % [Profil.personnage, Profil.classe if Profil.classe != "" else "non choisie"],
			13, Identite.TEXTE_ATTENUE, true, 4)
		# Maîtrise par domaine.
		var domaines: Dictionary = Savoir.SUJETS.mathematiques.domaines
		var y := 92.0
		UI.texte(self, Vector2(70.0, y), "MATHÉMATIQUES", 15, Identite.CYAN)
		y += 14.0
		for cle in domaines:
			var m := Profil.maitrise_domaine("mathematiques", str(cle))
			UI.texte(self, Vector2(70.0, y + 16.0), str(domaines[cle].titre), 13, Identite.TEXTE)
			UI.barre(self, Rect2(220.0, y + 2.0, 190.0, 18.0), m / 100.0,
				Identite.VERT if m >= 75.0 else Identite.BLEU)
			UI.texte(self, Vector2(420.0, y + 16.0), "%d %% maîtrisé" % int(m), 12, Identite.TEXTE_ATTENUE)
			y += 30.0
		# Résumé de la semaine.
		var s: Dictionary = Profil.stats_semaine
		var resume := Rect2(70.0, y + 8.0, 400.0, 108.0)
		UI.panneau(self, resume)
		UI.texte(self, resume.position + Vector2(16.0, 24.0), "CETTE SEMAINE", 13, Identite.OR)
		UI.texte(self, resume.position + Vector2(16.0, 46.0), "+ %d compétences acquises" % int(s.acquises), 12, Identite.TEXTE)
		UI.texte(self, resume.position + Vector2(16.0, 66.0), "+ %d compétences maîtrisées" % int(s.maitrisees), 12, Identite.TEXTE)
		UI.texte(self, resume.position + Vector2(16.0, 86.0),
			"%d difficulté(s) détectée(s), %d corrigée(s)" % [int(s.difficultes), int(s.corrigees)], 12, Identite.TEXTE)
		UI.texte(self, resume.position + Vector2(230.0, 46.0),
			"%d min d'apprentissage" % int(s.minutes_apprentissage), 12, Identite.TEXTE_ATTENUE)
		# Détail par compétence (colonne droite).
		var xd := size.x - 330.0
		UI.texte(self, Vector2(xd, 92.0), "DÉTAIL DES COMPÉTENCES", 13, Identite.CYAN)
		var yd := 106.0
		for comp in Savoir.competences("mathematiques"):
			var etat := Savoir.etat(str(comp.id))
			if etat == "verrouillee":
				continue
			var teinte: Color = COULEURS_ETATS.get(etat, Identite.CYAN)
			var symbole: String = {"maitrisee": "★", "acquise": "✓", "apprentissage": "◔",
				"decouverte": "○", "a_consolider": "↻"}.get(etat, "·")
			UI.texte(self, Vector2(xd, yd + 16.0), "%s  %s" % [symbole, str(comp.titre)], 12, teinte)
			yd += 24.0
			if yd > size.y - 60.0:
				break
		UI.texte(self, Vector2(size.x / 2.0, size.y - 22.0),
			"La progression semaine par semaine arrive avec les sessions d'apprentissage.",
			11, Identite.TEXTE_ATTENUE, true, 4)

	# ------------------------------------------------------------ classe

	## Premier lancement : l'enfant déclare sa classe (jamais de gros test
	## initial — le diagnostic sera progressif et invisible).
	func _dessiner_choix_classe() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.04, 0.12, 0.85))
		var fen := Rect2(size.x / 2.0 - 280.0, size.y / 2.0 - 130.0, 560.0, 250.0)
		UI.panneau(self, fen)
		UI.banniere(self, Vector2(size.x / 2.0, fen.position.y), 380.0, "BIENVENUE À ILLUMINIA !", 17)
		UI.texte(self, Vector2(size.x / 2.0, fen.position.y + 56.0), "En quelle classe es-tu ?", 18, Identite.TEXTE, true)
		UI.texte(self, Vector2(size.x / 2.0, fen.position.y + 80.0),
			"Illuminia s'adaptera ensuite tout seul à ton niveau.", 12, Identite.TEXTE_ATTENUE, true, 4)
		for i in Savoir.CLASSES.size():
			var rect := Rect2(fen.position.x + 34.0 + (i % 3) * 172.0,
				fen.position.y + 100.0 + (i / 3) * 62.0, 156.0, 52.0)
			_bouton_action(rect, "classe:%s" % Savoir.CLASSES[i],
				Identite.BLEU if i < 3 else Identite.VIOLET, str(Savoir.CLASSES[i]), 18)

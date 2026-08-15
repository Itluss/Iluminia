class_name Ville
extends Node3D
## MA VILLE — reproduction de la maquette « Ma Ville » d'Illuminia.
##
## LE TOUT DÉBUT : le terrain est PRESQUE VIDE, c'est voulu — « le
## terrain vide est une promesse, pas un manque de contenu ». Aucun
## arbre, aucune rivière : chaque élément d'écosystème sera une
## récompense future (Cite.ENVIRONNEMENT). Seule la MAISON DES
## AVENTURIERS trône, grande et fière : la première construction.
##
## Grille logique INVISIBLE (placement libre, collisions, sauvegarde) —
## elle n'apparaît qu'en MODE CONSTRUCTION avec le bâtiment fantôme
## (vert = valide, rouge = invalide), rotation et validation.

enum Mode { NORMAL, CONSTRUCTION }

var mode := Mode.NORMAL
var type_en_construction := ""
var fantome := {"x": 6, "y": 7, "rot": 0, "valide": true}
var selection := -1              ## indice du bâtiment sélectionné dans Profil.ville
var catalogue_ouvert := true

var _camera: Camera3D
var _cible_camera := Vector3.ZERO
var _noeuds_batiments: Array = []
var _noeud_fantome: Node3D
var _grille: Node3D
var surface: SurfaceVille
var _t := 0.0
var _tick_accumule := 0.0
var _sauvegarde_accumulee := 0.0
var rapport_retour := {}         ## OfflineReport significatif (modal BON RETOUR)
var _t_rapport := 0.0            ## temps d'ouverture (count-up des gains)
var blocage := {}                ## CityActionBlocker (l'intention du joueur)
## TRANSACTION DE DÉPLACEMENT : l'original (objet COMPLET, niveau et
## metadata inclus) reste récupérable tant que rien n'est validé —
## ANNULER le restaure à l'identique, VALIDER ne change QUE les
## coordonnées. Aucune transaction économique (déplacer n'est pas
## rembourser puis racheter).
var deplacement := {}            ## {indice, original}
var _alerte_nourriture := false  ## hystérésis de l'alerte nourriture


## CYCLE DE VIE MOBILE : arrière-plan → sauvegarde ; retour au premier
## plan → LE MÊME chemin d'absence que _ready (progression_hors_ligne,
## idempotente par timestamp : une fenêtre déjà consommée vaut zéro).
func _notification(quoi: int) -> void:
	match quoi:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			Profil.sauver()
		NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_WM_WINDOW_FOCUS_IN:
			if surface != null:
				_traiter_absence()
		NOTIFICATION_WM_CLOSE_REQUEST:
			Profil.sauver()


## Le SEUL point de consommation d'une période d'absence (appelé par
## _ready et par le retour au premier plan — jamais deux traitements).
func _traiter_absence() -> void:
	var rapport := Simulation.progression_hors_ligne(int(Time.get_unix_time_from_system()))
	if bool(rapport.get("significatif", false)):
		rapport_retour = rapport
		_t_rapport = 0.0


## L'état lu par le moteur de besoins (dérivé, jamais persisté).
func etat_besoins() -> Dictionary:
	return {"ville": Profil.ville, "population": Profil.population,
		"nourriture": Profil.nourriture, "connaissance_xp": Profil.connaissance_xp,
		"pieces": Profil.pieces}


func besoins_courants() -> Array:
	var besoins := Besoins.evaluer(etat_besoins(),
		{"batiments_decouverts": Profil.batiments_decouverts}, _alerte_nourriture)
	_alerte_nourriture = false
	for b in besoins:
		if str(b.genre) == "FOOD_WARNING" or str(b.genre) == "FOOD_SHORTAGE":
			_alerte_nourriture = true
	return besoins


func _ready() -> void:
	# LA VILLE EST LA HOME. Seul le tout premier lancement passe par le
	# choix de la classe (sur l'écran Apprendre), puis revient ici.
	if Profil.classe == "" and OS.get_environment("ILUMINIA_CLASSE") == "":
		get_tree().change_scene_to_file.call_deferred("res://scenes/accueil.tscn")
		return
	Ambiance.installer(self, Ambiance.THEME_JOUR)
	_construire_terrain()
	_construire_grille()
	_reconstruire_batiments()

	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = 13.0
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

	# Crochets de développement : forcer un état économique (scénarios de
	# test « l'or ne suffit jamais ») ou un état d'écran à capturer.
	if OS.get_environment("ILUMINIA_OR") != "":
		Profil.pieces = int(OS.get_environment("ILUMINIA_OR"))
	if OS.get_environment("ILUMINIA_XP") != "":
		Profil.connaissance_xp = int(OS.get_environment("ILUMINIA_XP"))
	if OS.get_environment("ILUMINIA_POP") != "":
		Profil.population = int(OS.get_environment("ILUMINIA_POP"))
	if OS.get_environment("ILUMINIA_NOURRITURE") != "":
		Profil.nourriture = float(OS.get_environment("ILUMINIA_NOURRITURE"))
	if OS.get_environment("ILUMINIA_SIM_AVANCE") != "":
		# Avance rapide de la simulation (tests du scénario manuel).
		var restant := float(OS.get_environment("ILUMINIA_SIM_AVANCE"))
		while restant > 0.0:
			Simulation.appliquer(minf(restant, 5.0))
			restant -= 5.0

	# PROGRESSION HORS-LIGNE : la ville a continué de vivre pendant
	# l'absence — un seul point de traitement, au lancement de l'écran.
	# (Crochet DEV : ILUMINIA_ABSENCE=secondes force une absence.)
	if OS.get_environment("ILUMINIA_ABSENCE") != "":
		Profil.dernier_tick = int(Time.get_unix_time_from_system()) \
			- int(OS.get_environment("ILUMINIA_ABSENCE"))
	_traiter_absence()

	# RETOUR CONTEXTUEL après une session lancée d'ici : le bâtiment
	# ciblé est retrouvé — jamais « retour ville générique, débrouille-toi ».
	var cible_retour := OS.get_environment("ILUMINIA_CIBLE")
	if cible_retour != "" and Cite.BATIMENTS.has(cible_retour):
		OS.set_environment("ILUMINIA_CIBLE", "")
		catalogue_ouvert = true
		var titre_c := str(Cite.BATIMENTS[cible_retour].titre)
		match Simulation.disponibilite(cible_retour, Profil.connaissance_xp,
				Profil.pieces, Profil.population):
			"DISPONIBLE":
				surface.toast.call_deferred("Tu peux maintenant construire le %s !" % titre_c)
			_:
				# Blocage recalculé (montant à jour, ou le bloqueur suivant
				# dans l'ordre connaissance → population → pièces).
				blocage = Besoins.blocage_achat(cible_retour, etat_besoins())
	match OS.get_environment("ILUMINIA_VILLE"):
		"construction":
			entrer_construction.call_deferred("potager")
		"selection":
			selection = 0
		"achat":
			# Test d'intégration : achat réel du potager (débit atomique).
			entrer_construction.call_deferred("potager")
			valider_construction.call_deferred()
		"blocage_potager":
			_executer.call_deferred("blocage:potager")
		"blocage_atelier":
			_executer.call_deferred("blocage:atelier")
		"decouvrir":
			_executer.call_deferred("reco:DISCOVER_BUILDING:atelier")
		"deplacer":
			# Transaction de déplacement OUVERTE (fantôme sur la maison).
			selection = 0
			_executer.call_deferred("deplacer")
		"deplacer_annule":
			# Ouvre PUIS annule : la maison doit être restaurée à l'identique.
			selection = 0
			_executer.call_deferred("deplacer")
			_executer.call_deferred("annuler")


## Le terrain sobre et beau : herbe douce à nuances, bordure de terre et
## roche détaillée, MICRO-détails seulement (pierres, touffes, fleurs
## minuscules, amorce de chemin) — 85 % du terrain reste libre.
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


func _reconstruire_batiments() -> void:
	for n in _noeuds_batiments:
		n.queue_free()
	_noeuds_batiments = []
	var demi := Cite.TAILLE_GRILLE / 2.0
	for b in Profil.ville:
		var taille := int(Cite.BATIMENTS.get(str(b.type), {}).get("taille", 2))
		var noeud := Node3D.new()
		noeud.position = Vector3(float(b.x) + taille / 2.0 - demi, 0.0, float(b.y) + taille / 2.0 - demi)
		noeud.rotation.y = float(b.get("rot", 0)) * PI / 2.0
		add_child(noeud)
		_construire_batiment(noeud, str(b.type), int(b.get("niveau", 1)))
		_noeuds_batiments.append(noeud)


## LA MAISON DES AVENTURIERS (house_adventurer_placeholder) : bois +
## pierre, toit orange chaud, fenêtres arquées cyan, cheminée, lanterne,
## bannière étoilée bleue — grande, détaillée, le point focal.
## Les niveaux d'évolution ajoutent des volumes (même identité).
func _construire_maison(noeud: Node3D, niveau: int) -> void:
	# Socle de pierre.
	var socle := BoxMesh.new()
	socle.size = Vector3(2.7, 0.5, 2.3)
	Materiaux.mesh(noeud, socle, Materiaux.toon(Color(0.62, 0.6, 0.64)), Vector3(0.0, 0.25, 0.0))
	# Corps à colombages (crème + poutres bois).
	var corps := BoxMesh.new()
	corps.size = Vector3(2.5, 1.3, 2.1)
	Materiaux.mesh(noeud, corps, Materiaux.toon(Color(0.96, 0.9, 0.78)), Vector3(0.0, 1.15, 0.0))
	for cote: float in [-1.0, 1.0]:
		var poutre := BoxMesh.new()
		poutre.size = Vector3(0.1, 1.3, 0.08)
		Materiaux.mesh(noeud, poutre, Materiaux.toon(Color(0.45, 0.3, 0.18)),
			Vector3(cote * 0.9, 1.15, 1.06), Vector3.ONE, false)
	var traverse := BoxMesh.new()
	traverse.size = Vector3(2.5, 0.1, 0.08)
	Materiaux.mesh(noeud, traverse, Materiaux.toon(Color(0.45, 0.3, 0.18)),
		Vector3(0.0, 1.72, 1.06), Vector3.ONE, false)
	# Grand toit orange chaud.
	var toit := PrismMesh.new()
	toit.size = Vector3(3.1, 1.2, 2.7)
	Materiaux.mesh(noeud, toit, Materiaux.toon(Color(0.83, 0.45, 0.22)), Vector3(0.0, 2.4, 0.0))
	# Cheminée de pierre sombre (lisible contre le toit clair).
	Materiaux.mesh(noeud, Materiaux.cylindre(0.14, 0.8), Materiaux.toon(Color(0.4, 0.38, 0.44)),
		Vector3(0.85, 2.9, -0.5))
	# Porte en bois + fenêtres arquées lumineuses.
	var porte := BoxMesh.new()
	porte.size = Vector3(0.5, 0.8, 0.08)
	Materiaux.mesh(noeud, porte, Materiaux.toon(Color(0.5, 0.33, 0.2)), Vector3(0.0, 0.9, 1.08))
	for cote: float in [-1.0, 1.0]:
		Materiaux.mesh(noeud, Materiaux.sphere(0.17), Materiaux.emissif(Identite.CYAN, 0.8),
			Vector3(cote * 0.75, 1.35, 1.08), Vector3(1.0, 1.1, 0.3), false)
	# Lanterne dorée près de la porte.
	Materiaux.mesh(noeud, Materiaux.sphere(0.08), Materiaux.emissif(Identite.OR, 2.0),
		Vector3(0.42, 1.35, 1.12), Vector3.ONE, false)
	# Bannière bleue Illuminia à étoile.
	Materiaux.mesh(noeud, Materiaux.cylindre(0.04, 1.6), Materiaux.toon(Color(0.4, 0.28, 0.18)),
		Vector3(-1.15, 3.2, 0.6))
	var drapeau := BoxMesh.new()
	drapeau.size = Vector3(0.65, 0.42, 0.04)
	Materiaux.mesh(noeud, drapeau, Materiaux.toon(Identite.BLEU), Vector3(-0.78, 3.7, 0.6), Vector3.ONE, false)
	Materiaux.mesh(noeud, Materiaux.sphere(0.07), Materiaux.emissif(Identite.OR, 1.6),
		Vector3(-0.78, 3.7, 0.64), Vector3.ONE, false)
	# Escalier d'entrée.
	for m in 2:
		var marche := BoxMesh.new()
		marche.size = Vector3(0.8, 0.12, 0.3)
		Materiaux.mesh(noeud, marche, Materiaux.toon(Color(0.66, 0.63, 0.66)),
			Vector3(0.0, 0.06 + m * 0.12, 1.35 - m * 0.15), Vector3.ONE, false)
	# ÉVOLUTION : chaque niveau ajoute un volume (même identité).
	if niveau >= 2:
		var annexe := BoxMesh.new()
		annexe.size = Vector3(1.0, 1.0, 1.4)
		Materiaux.mesh(noeud, annexe, Materiaux.toon(Color(0.93, 0.87, 0.75)), Vector3(1.6, 0.9, -0.2))
		var toit_a := PrismMesh.new()
		toit_a.size = Vector3(1.3, 0.6, 1.7)
		Materiaux.mesh(noeud, toit_a, Materiaux.toon(Color(0.8, 0.42, 0.2)), Vector3(1.6, 1.7, -0.2))
	if niveau >= 3:
		var etage := BoxMesh.new()
		etage.size = Vector3(1.6, 0.9, 1.5)
		Materiaux.mesh(noeud, etage, Materiaux.toon(Color(0.96, 0.9, 0.78)), Vector3(-0.3, 2.5, -0.2))
		var toit_e := PrismMesh.new()
		toit_e.size = Vector3(2.0, 0.8, 1.9)
		Materiaux.mesh(noeud, toit_e, Materiaux.toon(Color(0.83, 0.45, 0.22)), Vector3(-0.3, 3.35, -0.2))
	if niveau >= 4:
		Materiaux.mesh(noeud, Materiaux.cylindre(0.4, 2.6), Materiaux.toon(Color(0.9, 0.86, 0.78)),
			Vector3(1.3, 1.3, 0.9))
		Materiaux.mesh(noeud, Materiaux.cone(0.55, 0.9), Materiaux.toon(Identite.BLEU),
			Vector3(1.3, 3.0, 0.9))
	if niveau >= 5:
		for cote: float in [-1.0, 1.0]:
			Materiaux.mesh(noeud, Materiaux.cylindre(0.35, 3.2), Materiaux.toon(Color(0.9, 0.86, 0.78)),
				Vector3(cote * 1.5, 1.6, -0.9))
			Materiaux.mesh(noeud, Materiaux.cone(0.5, 0.9), Materiaux.toon(Identite.VIOLET),
				Vector3(cote * 1.5, 3.65, -0.9))


func _construire_batiment(noeud: Node3D, type: String, niveau := 1) -> void:
	match type:
		"maison":
			# Grande et fière : le point focal du terrain (le débord de
			# toit peut dépasser l'emprise logique, l'ancrage reste au sol).
			noeud.scale = Vector3(1.32, 1.32, 1.32)
			_construire_maison(noeud, niveau)
		"potager":
			for r in 3:
				var rangee := BoxMesh.new()
				rangee.size = Vector3(1.6, 0.14, 0.32)
				Materiaux.mesh(noeud, rangee, Materiaux.toon(Color(0.44, 0.3, 0.2)),
					Vector3(0.0, 0.07, -0.55 + r * 0.55))
				for l in 4:
					Materiaux.mesh(noeud, Materiaux.sphere(0.1), Materiaux.toon(Identite.VERT),
						Vector3(-0.6 + l * 0.4, 0.2, -0.55 + r * 0.55), Vector3.ONE, false)
			var barriere := BoxMesh.new()
			barriere.size = Vector3(1.9, 0.28, 0.05)
			Materiaux.mesh(noeud, barriere, Materiaux.toon(Color(0.6, 0.44, 0.28)),
				Vector3(0.0, 0.2, 0.95), Vector3.ONE, false)
		"atelier":
			var murs := BoxMesh.new()
			murs.size = Vector3(1.6, 1.0, 1.3)
			Materiaux.mesh(noeud, murs, Materiaux.toon(Color(0.68, 0.5, 0.32)), Vector3(0.0, 0.5, 0.0))
			var toit := PrismMesh.new()
			toit.size = Vector3(1.9, 0.7, 1.6)
			Materiaux.mesh(noeud, toit, Materiaux.toon(Color(0.45, 0.32, 0.22)), Vector3(0.0, 1.35, 0.0))
		"forge":
			var murs := BoxMesh.new()
			murs.size = Vector3(1.7, 1.1, 1.4)
			Materiaux.mesh(noeud, murs, Materiaux.toon(Color(0.52, 0.52, 0.58)), Vector3(0.0, 0.55, 0.0))
			var toit := PrismMesh.new()
			toit.size = Vector3(2.0, 0.8, 1.7)
			Materiaux.mesh(noeud, toit, Materiaux.toon(Color(0.3, 0.3, 0.36)), Vector3(0.0, 1.5, 0.0))
			Materiaux.mesh(noeud, Materiaux.sphere(0.16), Materiaux.emissif(Identite.ORANGE, 1.8),
				Vector3(0.0, 0.62, 0.74), Vector3.ONE, false)
		_:
			var bloc := BoxMesh.new()
			bloc.size = Vector3(1.5, 1.0, 1.5)
			Materiaux.mesh(noeud, bloc, Materiaux.toon(Identite.PANNEAU_CLAIR), Vector3(0.0, 0.5, 0.0))


# ------------------------------------------------------- mode construction

func entrer_construction(type: String) -> void:
	mode = Mode.CONSTRUCTION
	type_en_construction = type
	selection = -1
	fantome = {"x": 6, "y": 7, "rot": 0, "valide": false}
	_grille.visible = true
	_valider_fantome()
	_reconstruire_fantome()


func sortir_construction() -> void:
	# Une transaction de déplacement encore ouverte = ANNULATION :
	# l'original est restauré EXACTEMENT (position, rotation, niveau).
	if not deplacement.is_empty():
		Profil.ville.insert(mini(int(deplacement.indice), Profil.ville.size()),
			deplacement.original)
		deplacement = {}
		_reconstruire_batiments()
	mode = Mode.NORMAL
	type_en_construction = ""
	_grille.visible = false
	if _noeud_fantome != null:
		_noeud_fantome.queue_free()
		_noeud_fantome = null


## Cases occupées (helper pur partagé — Cite.cases_occupees).
func _cases_occupees() -> Dictionary:
	return Cite.cases_occupees(Profil.ville)


func _valider_fantome() -> void:
	var taille := int(Cite.BATIMENTS.get(type_en_construction, {}).get("taille", 2))
	var occ := _cases_occupees()
	var valide := true
	for dx in taille:
		for dy in taille:
			var c := Vector2i(int(fantome.x) + dx, int(fantome.y) + dy)
			if c.x < 0 or c.y < 0 or c.x >= Cite.TAILLE_GRILLE or c.y >= Cite.TAILLE_GRILLE or occ.has(c):
				valide = false
	fantome.valide = valide


func _reconstruire_fantome() -> void:
	if _noeud_fantome != null:
		_noeud_fantome.queue_free()
	_noeud_fantome = Node3D.new()
	add_child(_noeud_fantome)
	var taille := int(Cite.BATIMENTS.get(type_en_construction, {}).get("taille", 2))
	var demi := Cite.TAILLE_GRILLE / 2.0
	_noeud_fantome.position = Vector3(float(fantome.x) + taille / 2.0 - demi, 0.0,
		float(fantome.y) + taille / 2.0 - demi)
	_noeud_fantome.rotation.y = int(fantome.rot) * PI / 2.0
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


func valider_construction() -> void:
	if not bool(fantome.valide):
		Audio.jouer("denied")
		surface.toast("Cet emplacement est occupé — choisis une case libre !")
		return
	if not deplacement.is_empty():
		# DÉPLACEMENT VALIDÉ : seules les coordonnées changent (objet
		# complet copié — niveau conservé), zéro économie.
		Profil.ville.append(Cite.batiment_deplace(deplacement.original,
			int(fantome.x), int(fantome.y), int(fantome.rot)))
		deplacement = {}
		Profil.sauver()
		Audio.jouer("victoire")
		sortir_construction()
		_reconstruire_batiments()
		return
	if Simulation.disponibilite(type_en_construction, Profil.connaissance_xp,
			Profil.pieces, Profil.population) != "DISPONIBLE":
		Audio.jouer("denied")
		return
	# TRANSACTION ATOMIQUE : le débit précède la pose et la refuse si le
	# solde ne suffit pas — jamais de bâtiment acheté sans pièces déduites.
	if not Profil.debiter_pieces(int(Cite.BATIMENTS[type_en_construction]["or"]),
			"ACHAT_BATIMENT", type_en_construction):
		Audio.jouer("denied")
		return
	Profil.ville.append({"type": type_en_construction, "x": int(fantome.x), "y": int(fantome.y),
		"rot": int(fantome.rot), "niveau": 1})
	Profil.sauver()
	Audio.jouer("victoire")
	surface.toast("%s construit(e) — ta ville grandit !" % str(Cite.BATIMENTS[type_en_construction].titre))
	sortir_construction()
	_reconstruire_batiments()


## Tap sur le terrain → case de la grille (rayon caméra → plan du sol).
func _case_sous(pos_ecran: Vector2) -> Vector2i:
	var origine := _camera.project_ray_origin(pos_ecran)
	var direction := _camera.project_ray_normal(pos_ecran)
	if absf(direction.y) < 0.001:
		return Vector2i(-1, -1)
	var t := -origine.y / direction.y
	var p := origine + direction * t
	var demi := Cite.TAILLE_GRILLE / 2.0
	return Vector2i(int(floor(p.x + demi)), int(floor(p.z + demi)))


func _process(delta: float) -> void:
	if surface == null:
		return   # redirection du premier lancement en cours
	_t += delta
	if not rapport_retour.is_empty():
		_t_rapport += delta
	# TICK DE SIMULATION : cadence fixe, mais calcul sur le temps
	# RÉELLEMENT écoulé (l'économie reste juste si le rendu ralentit).
	_tick_accumule += delta
	if _tick_accumule >= float(Simulation.EQUILIBRAGE.simulation.tick_s):
		var resultat := Simulation.appliquer(_tick_accumule)
		_tick_accumule = 0.0
		if bool(resultat.habitant_arrive):
			Audio.jouer("victoire")
			surface.toast("Un nouvel habitant a rejoint ta ville !")
	# Persistance ESPACÉE : le tick passif marque l'état sale, l'écriture
	# disque part toutes les ~25 s (les transactions restent immédiates).
	_sauvegarde_accumulee += delta
	if _sauvegarde_accumulee >= 25.0:
		_sauvegarde_accumulee = 0.0
		Profil.sauver_si_sale()
	surface.queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		var action := surface.action_sous(event.position)
		if action != "":
			_executer(action)
			return
		if mode == Mode.CONSTRUCTION:
			# Déplacer le fantôme sur la case touchée (placement LIBRE).
			var taille := int(Cite.BATIMENTS.get(type_en_construction, {}).get("taille", 2))
			var case_v := _case_sous(event.position)
			if case_v.x >= 0:
				fantome.x = clampi(case_v.x - taille / 2, 0, Cite.TAILLE_GRILLE - taille)
				fantome.y = clampi(case_v.y - taille / 2, 0, Cite.TAILLE_GRILLE - taille)
				_valider_fantome()
				_reconstruire_fantome()
		else:
			# Sélection d'un bâtiment (tap sur son emprise).
			var case_v := _case_sous(event.position)
			selection = -1
			for i in Profil.ville.size():
				var b: Dictionary = Profil.ville[i]
				var taille := int(Cite.BATIMENTS.get(str(b.type), {}).get("taille", 2))
				if case_v.x >= int(b.x) and case_v.x < int(b.x) + taille \
						and case_v.y >= int(b.y) and case_v.y < int(b.y) + taille:
					selection = i
					Audio.jouer("clic")
	elif event is InputEventScreenDrag and mode == Mode.NORMAL:
		var d: Vector2 = event.relative * 0.02
		_cible_camera += Vector3(-d.x - d.y, 0.0, d.x - d.y) * 0.7
		_cible_camera.x = clampf(_cible_camera.x, -4.0, 4.0)
		_cible_camera.z = clampf(_cible_camera.z, -4.0, 4.0)
		_camera.position = _cible_camera + Vector3(9.0, 11.0, 9.0)


func _executer(action: String) -> void:
	var morceaux := action.split(":")
	match morceaux[0]:
		"retour", "apprendre":
			# APPRENDRE : l'arbre des connaissances est désormais une
			# section — la ville reste la Home.
			Audio.jouer("clic")
			Profil.sauver_si_sale()
			OS.set_environment("ILUMINIA_ECRAN", "")
			get_tree().change_scene_to_file.call_deferred("res://scenes/accueil.tscn")
		"apprendre_gagner":
			# EARN_COINS : la ville envoie l'enfant apprendre POUR un
			# besoin précis (bâtiment + montant manquant), et la session
			# le ramènera ICI, contexte restauré.
			Audio.jouer("depart")
			var cible := ""
			var montant := 0
			if not blocage.is_empty() and str(blocage.get("type", "")) == "NOT_ENOUGH_COINS":
				cible = str(blocage.batiment)
				montant = int(blocage.manquant)
			else:
				var objectif := Cite.objectif_courant(Profil.connaissance_xp, Profil.pieces, Profil.ville)
				cible = str(objectif.get("batiment", ""))
				montant = maxi(int(Cite.BATIMENTS.get(cible, {}).get("or", 0)) - Profil.pieces, 0)
			blocage = {}
			OS.set_environment("ILUMINIA_INTENTION", Besoins.encoder_intention(
				{"source": "ville", "raison": "gagner_pieces", "batiment": cible, "montant": montant}))
			var reco := Savoir.recommandation()
			if reco != "":
				OS.set_environment("ILUMINIA_COMPETENCE", reco)
			get_tree().change_scene_to_file.call_deferred("res://scenes/session.tscn")
		"apprendre_progresser":
			# GAIN_KNOWLEDGE : le bâtiment reste verrouillé par la
			# connaissance — la session pédagogique fait progresser (la
			# ville ne modifie JAMAIS la maîtrise scolaire directement).
			Audio.jouer("depart")
			var cible_p := str(blocage.get("batiment", ""))
			var palier_requis := int(blocage.get("palier_requis", 0))
			blocage = {}
			OS.set_environment("ILUMINIA_INTENTION", Besoins.encoder_intention(
				{"source": "ville", "raison": "progresser", "batiment": cible_p,
				"palier": palier_requis}))
			var reco_p := Savoir.recommandation()
			if reco_p != "":
				OS.set_environment("ILUMINIA_COMPETENCE", reco_p)
			get_tree().change_scene_to_file.call_deferred("res://scenes/session.tscn")
		"collection", "progression":
			Audio.jouer("clic")
			OS.set_environment("ILUMINIA_ECRAN", morceaux[0])
			get_tree().change_scene_to_file.call_deferred("res://scenes/accueil.tscn")
		"construire":
			Audio.jouer("clic")
			entrer_construction(morceaux[1])
		"catalogue":
			Audio.jouer("clic")
			catalogue_ouvert = not catalogue_ouvert
		"pivoter":
			Audio.jouer("clic")
			fantome.rot = (int(fantome.rot) + 1) % 4
			_reconstruire_fantome()
		"valider":
			valider_construction()
		"annuler":
			Audio.jouer("clic")
			sortir_construction()
		"deplacer":
			# Déplacement = mode construction sur le bâtiment existant,
			# adossé à une TRANSACTION restaurable (jamais de perte).
			if selection >= 0:
				Audio.jouer("clic")
				var b: Dictionary = Profil.ville[selection]
				deplacement = {"indice": selection, "original": b.duplicate(true)}
				Profil.ville.remove_at(selection)
				selection = -1
				_reconstruire_batiments()
				entrer_construction(str(b.type))
				fantome.x = int(b.x)
				fantome.y = int(b.y)
				fantome.rot = int(b.get("rot", 0))
				_valider_fantome()
				_reconstruire_fantome()
		"infos":
			if selection >= 0:
				Audio.jouer("clic")
				var b: Dictionary = Profil.ville[selection]
				surface.toast(str(Cite.BATIMENTS[str(b.type)].descr))
		"ameliorer":
			_ameliorer()
		"fermer_rapport":
			Audio.jouer("depart")
			rapport_retour = {}
		"blocage":
			# Le joueur exprime une INTENTION sur un bâtiment verrouillé :
			# le panneau explique la vraie cause (jamais en permanence).
			Audio.jouer("clic")
			blocage = Besoins.blocage_achat(morceaux[1], etat_besoins())
			selection = -1
		"fermer_blocage":
			Audio.jouer("clic")
			blocage = {}
		"reco":
			# CityActionRecommendation → l'action du monde.
			blocage = {}
			match morceaux[1]:
				"OPEN_BUILDING":
					if Simulation.disponibilite(morceaux[2], Profil.connaissance_xp,
							Profil.pieces, Profil.population) == "DISPONIBLE":
						Audio.jouer("clic")
						entrer_construction(morceaux[2])
					else:
						Audio.jouer("clic")
						blocage = Besoins.blocage_achat(morceaux[2], etat_besoins())
				"UPGRADE_HOUSING":
					Audio.jouer("clic")
					for i in Profil.ville.size():
						if str(Profil.ville[i].type) == "maison":
							selection = i
							break
				"DISCOVER_BUILDING":
					# Découvert : l'opportunité ne se représentera plus.
					Audio.jouer("victoire")
					if not Profil.batiments_decouverts.has(morceaux[2]):
						Profil.batiments_decouverts.append(morceaux[2])
						Profil.sauver()
					catalogue_ouvert = true
					surface.toast("%s t'attend dans le catalogue !" %
						str(Cite.BATIMENTS.get(morceaux[2], {}).get("titre", "")))
		"boutique":
			Audio.jouer("clic")
			surface.toast("La boutique arrive — jamais de raccourci sur la connaissance !")
		"son":
			Profil.basculer_son()
			Audio.jouer("clic")


func _ameliorer() -> void:
	if selection < 0:
		return
	var b: Dictionary = Profil.ville[selection]
	var fiche: Dictionary = Cite.BATIMENTS[str(b.type)]
	var niveau := int(b.get("niveau", 1))
	if niveau >= int(fiche.get("niveau_max", 1)):
		Audio.jouer("denied")
		surface.toast("Niveau maximum atteint !")
		return
	# Coût d'amélioration DATA-DRIVEN (or_amelioration × niveau actuel).
	var cout := int(fiche.get("or_amelioration", 60)) * niveau
	if not Profil.debiter_pieces(cout, "AMELIORATION", str(b.type)):
		Audio.jouer("denied")
		surface.toast("Il te faut %d pièces pour améliorer." % cout)
		return
	b.niveau = niveau + 1
	Profil.sauver()
	Audio.jouer("victoire")
	surface.toast("%s — niveau %d !" % [str(fiche.titre), niveau + 1])
	_reconstruire_batiments()


## L'interface de Ma Ville (maquette) : en-tête connaissance, menu
## gauche, catalogue, actions de sélection, évolution, hibou, nav.
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
		_entete()
		_menu_gauche()
		if ville.catalogue_ouvert and ville.mode == Ville.Mode.NORMAL:
			_catalogue()
		if ville.mode == Ville.Mode.CONSTRUCTION:
			_ui_construction()
		elif ville.selection >= 0:
			_ui_selection()
		else:
			_panneau_objectif()
			_pied()
		if _toast_temps > 0.0:
			UI.banniere(self, Vector2(size.x / 2.0, size.y - 104.0), 480.0, _toast, 15)
		if not ville.rapport_retour.is_empty():
			_modal_retour()

	## BON RETOUR ! — le rapport de la vie de la ville pendant l'absence :
	## un moment gratifiant (curiosité, jamais culpabilisation). Les
	## chiffres montent doucement (count-up), le panneau reste fantasy.
	func _modal_retour() -> void:
		var r: Dictionary = ville.rapport_retour
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.04, 0.12, 0.72))
		var rect := Rect2(size.x / 2.0 - 190.0, size.y / 2.0 - 150.0, 380.0, 300.0)
		UI.panneau(self, rect)
		UI.contour_arrondi(self, rect, Identite.RAYON_MD, Color(Identite.CYAN.r, Identite.CYAN.g,
			Identite.CYAN.b, 0.5), 1.5)
		UI.banniere(self, Vector2(rect.get_center().x, rect.position.y + 22.0), 250.0, "BON RETOUR !", 17)
		UI.texte(self, Vector2(rect.get_center().x, rect.position.y + 52.0),
			"Ta ville a continué de vivre pendant ton absence.", 10, Identite.TEXTE_ATTENUE, true, 1)
		# Les gains, jamais les calculs internes — count-up ~0.9 s.
		var k := clampf(ville._t_rapport / 0.9, 0.0, 1.0)
		var lignes: Array = []
		if absf(float(r.delta_nourriture)) >= 1.0:
			lignes.append(["ble", "%+d nourriture" % int(roundf(float(r.delta_nourriture) * k))])
		if int(r.pieces_produites) > 0:
			lignes.append(["or", "+%d pièces" % int(roundf(float(r.pieces_produites) * k))])
		if int(r.nouveaux_habitants) > 0:
			lignes.append(["habitants", "+%d habitant%s" % [int(roundf(float(r.nouveaux_habitants) * k)),
				"s" if int(r.nouveaux_habitants) > 1 else ""]])
		var y := rect.position.y + 84.0
		for l in lignes:
			var carte := Rect2(rect.get_center().x - 110.0, y, 220.0, 34.0)
			UI.rect_degrade(self, carte, 10.0, Color("14264d"), Color("0c1a3a"))
			match str(l[0]):
				"ble":
					_ble(carte.position + Vector2(22.0, 17.0), 10.0)
				"or":
					if not UI.image(self, "res-coin", Rect2(carte.position + Vector2(12.0, 7.0), Vector2(20.0, 20.0))):
						draw_circle(carte.position + Vector2(22.0, 17.0), 9.0, Identite.OR)
				"habitants":
					_habitants(carte.position + Vector2(22.0, 17.0), 10.0)
			UI.texte(self, carte.position + Vector2(44.0, 22.0), str(l[1]), 14, Identite.TEXTE)
			y += 40.0
		# Faits notables — informatifs, jamais frustrants.
		var notes: Array = []
		if bool(r.atteint_zero):
			notes.append("Ta réserve de nourriture s'est épuisée.")
		if bool(r.atteint_capacite):
			notes.append("Tes logements sont complets — construis-en pour accueillir plus d'habitants.")
		if bool(r.ecrete):
			notes.append("Tes bâtiments ont produit au maximum pendant %d h." %
				int(Simulation.EQUILIBRAGE.hors_ligne.max_heures))
		for n in notes:
			UI.texte(self, Vector2(rect.get_center().x, y + 12.0), str(n), 9, Identite.CYAN, true, 1)
			y += 17.0
		var cta := Rect2(rect.get_center().x - 120.0, rect.end.y - 56.0, 240.0, 44.0)
		UI.bouton(self, cta, Identite.ORANGE, "v_retour_ville", false, Identite.RAYON_MD)
		UI.texte(self, cta.get_center() + Vector2(0.0, 5.0), "RETOURNER DANS MA VILLE", 12,
			Identite.TEXTE, true, 2)
		# La modale capture TOUTES les interactions (une seule action).
		_actions = [{"rect": cta, "action": "fermer_rapport"}]

	# --------------------------------------------------------- entête

	func _entete() -> void:
		var profil := Rect2(8.0, 8.0, 238.0, 66.0)
		UI.panneau(self, profil)
		draw_circle(profil.position + Vector2(33.0, 33.0), 28.0, Identite.CONTOUR)
		draw_circle(profil.position + Vector2(33.0, 33.0), 25.0, Identite.VIOLET)
		UI.image(self, "avatar-%s" % Profil.personnage.to_lower(),
			Rect2(profil.position + Vector2(10.0, 10.0), Vector2(46.0, 46.0)))
		UI.texte(self, profil.position + Vector2(66.0, 24.0), Profil.personnage, 16, Identite.TEXTE)
		UI.texte(self, profil.position + Vector2(66.0, 42.0),
			Profil.classe if Profil.classe != "" else "…", 12, Identite.CYAN)
		UI.pastille(self, profil.position + Vector2(76.0, 54.0), 9.0, Identite.VIOLET, str(Profil.niveau), 10)
		UI.barre(self, Rect2(profil.position + Vector2(90.0, 48.0), Vector2(138.0, 13.0)),
			Profil.progres_niveau(), Identite.BLEU)
		# NIVEAU DE CONNAISSANCE + prochain déblocage : même depuis la
		# ville, « si j'apprends encore, je pourrai obtenir ça ».
		var centre := Rect2(254.0, 8.0, 330.0, 66.0)
		UI.panneau(self, centre)
		var palier := Cite.palier(Profil.connaissance_xp)
		UI.texte(self, Vector2(centre.get_center().x - 20.0, centre.position.y + 18.0),
			"CONNAISSANCE — PALIER %d" % (palier + 1), 11, Identite.TEXTE_ATTENUE, true, 4)
		var prochain := Cite.prochain_palier(Profil.connaissance_xp)
		UI.etoile(self, centre.position + Vector2(22.0, 42.0), 12.0, Identite.VIOLET)
		if not prochain.is_empty():
			var xp_p := int(Cite.PALIERS[int(prochain.indice)].xp)
			var xp_a := int(Cite.PALIERS[palier].xp)
			var frac := float(Profil.connaissance_xp - xp_a) / maxf(float(xp_p - xp_a), 1.0)
			UI.barre(self, Rect2(centre.position + Vector2(40.0, 30.0), Vector2(110.0, 22.0)), frac, Identite.VIOLET)
			UI.texte(self, centre.position + Vector2(95.0, 46.0), "%d %%" % int(frac * 100.0), 13, Identite.TEXTE, true, 4)
			UI.texte(self, centre.position + Vector2(160.0, 36.0), "Encore %d XP" % int(prochain.xp_manquant), 12, Identite.TEXTE)
			UI.texte(self, centre.position + Vector2(160.0, 52.0), "pour débloquer", 10, Identite.TEXTE_ATTENUE)
			var nom_rec := ""
			for d in prochain.debloque:
				var m := str(d).split(":")
				nom_rec = str(Cite.BATIMENTS.get(m[0], {}).get("titre", m[m.size() - 1]))
				break
			_mini_batiment_type(centre.position + Vector2(288.0, 32.0), 20.0, "atelier")
			UI.texte(self, Vector2(centre.position.x + 288.0, centre.position.y + 60.0),
				nom_rec.to_upper().left(14), 9, Identite.OR, true, 3)
		# RESSOURCES DE LA VILLE : pièces, nourriture (+ taux net) et
		# population — lues depuis la simulation, jamais recalculées ici.
		var res := Rect2(592.0, 8.0, 146.0, 66.0)
		UI.panneau(self, res)
		var sim := Simulation.resume()
		if not UI.image(self, "res-coin", Rect2(res.position + Vector2(8.0, 4.0), Vector2(15.0, 15.0))):
			draw_circle(res.position + Vector2(15.0, 11.0), 7.0, Identite.OR)
		UI.texte(self, res.position + Vector2(28.0, 16.0), str(Profil.pieces), 12, Identite.TEXTE)
		_ble(res.position + Vector2(15.0, 32.0), 8.0)
		UI.texte(self, res.position + Vector2(28.0, 37.0), str(int(sim.nourriture)), 12, Identite.TEXTE)
		var taux := float(sim.taux_net)
		UI.texte(self, res.position + Vector2(66.0, 37.0), "%+.1f/min" % taux, 9,
			Identite.VERT if taux >= 0.0 else Identite.ROUGE)
		_habitants(res.position + Vector2(15.0, 53.0), 8.0)
		UI.texte(self, res.position + Vector2(28.0, 58.0), "%d / %d" % [int(sim.population),
			int(sim.capacite)], 12, Identite.TEXTE)
		# PÉNURIE : un petit statut clair, jamais une alerte intrusive.
		if str(sim.statut) == "PENURIE":
			var pill := Rect2(size.x / 2.0 - 92.0, size.y - 84.0, 184.0, 22.0)
			UI.rect_degrade(self, pill, 11.0, Color(0.35, 0.2, 0.05, 0.92), Color(0.25, 0.14, 0.04, 0.92))
			UI.contour_arrondi(self, pill, 11.0, Identite.ORANGE, 1.5)
			UI.texte(self, pill.get_center() + Vector2(0.0, 4.0), "Nourriture insuffisante", 10,
				Identite.ORANGE, true, 1)
		var b1 := Rect2(746.0, 8.0, 52.0, 50.0)
		UI.bouton(self, b1, Identite.PANNEAU_CLAIR, "v_boutique", false, Identite.RAYON_SM)
		UI.coffre(self, b1.get_center() + Vector2(0.0, 2.0), 22.0)
		_actions.append({"rect": b1, "action": "boutique"})
		var b2 := Rect2(804.0, 8.0, 52.0, 50.0)
		UI.bouton(self, b2, Identite.PANNEAU_CLAIR, "v_retour", false, Identite.RAYON_SM)
		UI.texte(self, b2.get_center() + Vector2(0.0, 7.0), "←", 20, Identite.TEXTE, true)
		_actions.append({"rect": b2, "action": "retour"})

	## Épi de blé (nourriture) et habitants — pictos dessinés, pas d'emoji.
	func _ble(p: Vector2, r: float) -> void:
		draw_line(p + Vector2(0.0, r * 0.7), p + Vector2(0.0, -r * 0.3), Color("d8a93c"), 2.0)
		for e in 3:
			var h := -r * 0.15 - e * r * 0.32
			draw_circle(p + Vector2(-r * 0.28, h), r * 0.2, Color("f2c85a"))
			draw_circle(p + Vector2(r * 0.28, h), r * 0.2, Color("f2c85a"))
		draw_circle(p + Vector2(0.0, -r * 0.75), r * 0.22, Color("f2c85a"))

	func _habitants(p: Vector2, r: float) -> void:
		draw_circle(p + Vector2(-r * 0.32, -r * 0.3), r * 0.3, Identite.CYAN)
		draw_circle(p + Vector2(-r * 0.32, r * 0.35), r * 0.42, Identite.CYAN)
		draw_circle(p + Vector2(r * 0.36, -r * 0.15), r * 0.26, Color("8fb8e8"))
		draw_circle(p + Vector2(r * 0.36, r * 0.4), r * 0.36, Color("8fb8e8"))

	## Miniatures de bâtiments (catalogue et aperçus).
	func _mini_batiment_type(p: Vector2, r: float, type: String) -> void:
		match type:
			"maison":
				draw_rect(Rect2(p + Vector2(-r * 0.55, -r * 0.05), Vector2(r * 1.1, r * 0.62)), Color("f4e6c8"))
				draw_colored_polygon(PackedVector2Array([
					p + Vector2(-r * 0.7, -r * 0.05), p + Vector2(0.0, -r * 0.6), p + Vector2(r * 0.7, -r * 0.05)]),
					Color("d4703a"))
				draw_rect(Rect2(p + Vector2(-r * 0.1, r * 0.22), Vector2(r * 0.2, r * 0.35)), Color("6a4630"))
			"potager":
				for l in 3:
					draw_rect(Rect2(p + Vector2(-r * 0.55, -r * 0.35 + l * r * 0.32), Vector2(r * 1.1, r * 0.16)), Color("6a4630"))
					for c in 3:
						draw_circle(p + Vector2(-r * 0.35 + c * r * 0.35, -r * 0.27 + l * r * 0.32), r * 0.1, Identite.VERT)
			"atelier":
				draw_rect(Rect2(p + Vector2(-r * 0.5, -r * 0.05), Vector2(r, r * 0.55)), Color("a87848"))
				draw_colored_polygon(PackedVector2Array([
					p + Vector2(-r * 0.62, -r * 0.05), p + Vector2(0.0, -r * 0.5), p + Vector2(r * 0.62, -r * 0.05)]),
					Color("6a4a32"))
			"forge":
				draw_rect(Rect2(p + Vector2(-r * 0.5, -r * 0.05), Vector2(r, r * 0.55)), Color("8a8a94"))
				draw_colored_polygon(PackedVector2Array([
					p + Vector2(-r * 0.62, -r * 0.05), p + Vector2(0.0, -r * 0.5), p + Vector2(r * 0.62, -r * 0.05)]),
					Color("4a4a54"))
				draw_circle(p + Vector2(0.0, r * 0.25), r * 0.14, Identite.ORANGE)
			"ecurie":
				draw_rect(Rect2(p + Vector2(-r * 0.6, -r * 0.05), Vector2(r * 1.2, r * 0.5)), Color("b08a58"))
				draw_colored_polygon(PackedVector2Array([
					p + Vector2(-r * 0.72, -r * 0.05), p + Vector2(0.0, -r * 0.45), p + Vector2(r * 0.72, -r * 0.05)]),
					Color("7a5a38"))
			"murailles":
				for c in 3:
					draw_rect(Rect2(p + Vector2(-r * 0.6 + c * r * 0.45, -r * 0.3), Vector2(r * 0.32, r * 0.75)), Color("9a9aa4"))
			_:
				draw_rect(Rect2(p + Vector2(-r * 0.5, -r * 0.3), Vector2(r, r * 0.8)), Color("d8d2e8"))
				draw_colored_polygon(PackedVector2Array([
					p + Vector2(-r * 0.6, -r * 0.3), p + Vector2(0.0, -r * 0.7), p + Vector2(r * 0.6, -r * 0.3)]),
					Color("8a55f5"))

	# --------------------------------------------------------- menu gauche

	func _menu_gauche() -> void:
		var entrees: Array = [["vue", "VUE GLOBALE", true, false],
			["chantier", "CONSTRUIRE", true, Cite.constructible("potager", Profil.connaissance_xp, Profil.pieces)],
			["deco", "DÉCORATIONS", false, false], ["obtentions", "OBTENTIONS", false, false]]
		for i in entrees.size():
			var e: Array = entrees[i]
			var rect := Rect2(8.0, 90.0 + i * 56.0, 128.0, 48.0)
			var actif: bool = i == 0
			var dispo: bool = bool(e[2])
			if actif:
				UI.rect_degrade(self, rect.grow(3.0), Identite.RAYON_MD + 3,
					Color(Identite.CYAN.r, Identite.CYAN.g, Identite.CYAN.b, 0.4),
					Color(Identite.CYAN.r, Identite.CYAN.g, Identite.CYAN.b, 0.15))
				UI.bouton(self, rect, Identite.BLEU, "vm_%d" % i, false, Identite.RAYON_MD)
			elif dispo:
				UI.bouton(self, rect, Identite.PANNEAU_CLAIR, "vm_%d" % i, false, Identite.RAYON_MD)
			else:
				# Futur système : présent, désirable, verrouillé avec élégance.
				UI.rect_degrade(self, rect.grow(2.0), Identite.RAYON_MD + 2, Identite.CONTOUR, Identite.CONTOUR)
				UI.rect_degrade(self, rect, Identite.RAYON_MD, Color("1a2c55"), Color("101c3d"))
				UI.image(self, "icon-lock", Rect2(rect.end - Vector2(22.0, 24.0), Vector2(14.0, 14.0)))
			UI.texte(self, rect.position + Vector2(12.0, 29.0), str(e[1]), 10,
				Identite.TEXTE if actif or dispo else Identite.TEXTE_ATTENUE, false, 4)
			if bool(e[3]):
				UI.badge_notif(self, rect.position + Vector2(rect.size.x - 4.0, 4.0), "!")
			if str(e[0]) == "chantier":
				_actions.append({"rect": rect, "action": "catalogue"})

	# --------------------------------------------------------- catalogue

	func _catalogue() -> void:
		var rect := Rect2(size.x - 254.0, 84.0, 246.0, size.y - 148.0)
		UI.panneau(self, rect)
		var x := rect.position.x + 14.0
		UI.texte(self, Vector2(x, rect.position.y + 22.0), "CATALOGUE DE CONSTRUCTION", 12, Identite.TEXTE)
		UI.texte(self, Vector2(x, rect.position.y + 38.0), "La CONNAISSANCE débloque le", 9, Identite.TEXTE_ATTENUE)
		UI.texte(self, Vector2(x, rect.position.y + 50.0), "catalogue — l'or ne suffit jamais.", 9, Identite.TEXTE_ATTENUE)
		var palier := Cite.palier(Profil.connaissance_xp)
		var y := rect.position.y + 58.0
		var visibles: Array = ["maison", "potager", "atelier", "forge", "ecurie", "murailles"]
		# Le pas s'adapte à la hauteur du panneau : les 6 entrées ET le
		# pied « VOIR LES BÂTIMENTS VERROUILLÉS » tiennent toujours dedans.
		var pas: float = (rect.size.y - 82.0) / visibles.size()
		for type in visibles:
			var fiche: Dictionary = Cite.BATIMENTS[type]
			var construit := false
			for pose in Profil.ville:
				if str(pose.type) == type:
					construit = true
			var dispo := Simulation.disponibilite(str(type), Profil.connaissance_xp,
				Profil.pieces, Profil.population)
			var accessible: bool = dispo != "VERROU_CONNAISSANCE" and dispo != "VERROU_POPULATION"
			var ligne := Rect2(x - 4.0, y, rect.size.x - 20.0, pas - 5.0)
			var h := ligne.size.y
			UI.rect_degrade(self, ligne, 10.0,
				Color("14264d") if accessible else Color("0d1734"),
				Color("0c1a3a") if accessible else Color("091126"))
			if construit:
				UI.contour_arrondi(self, ligne, 10.0, Identite.VERT, 2.0)
			_mini_batiment_type(ligne.position + Vector2(24.0, h / 2.0), 14.0, type)
			UI.texte(self, ligne.position + Vector2(46.0, h / 2.0 - 3.0),
				str(fiche.titre).to_upper().left(22), 10,
				Identite.TEXTE if accessible else Identite.TEXTE_ATTENUE)
			if construit:
				UI.texte(self, ligne.position + Vector2(46.0, h / 2.0 + 11.0), "Construite : 1/1", 9, Identite.VERT)
				UI.pastille(self, ligne.position + Vector2(ligne.size.x - 20.0, h / 2.0), 10.0, Identite.VERT, "✓", 12)
			elif not accessible:
				# Le verrou EXPLIQUE toujours pourquoi (connaissance ou habitants) ;
				# le toucher ouvre le panneau de cause (l'intention du joueur).
				UI.texte(self, ligne.position + Vector2(46.0, h / 2.0 + 11.0),
					"Niv. connaissance %d requis" % (int(fiche.palier) + 1) if dispo == "VERROU_CONNAISSANCE"
					else "%d habitants requis" % int(fiche.get("population_requise", 0)),
					9, Identite.TEXTE_ATTENUE)
				UI.image(self, "icon-lock", Rect2(ligne.position + Vector2(ligne.size.x - 30.0, h / 2.0 - 9.0), Vector2(18.0, 18.0)))
				_actions.append({"rect": ligne, "action": "blocage:%s" % type})
			else:
				# DÉBLOQUÉ (palier atteint) : achetable, ou « x / y » si les
				# pièces manquent — jamais un bouton actif trompeur.
				if not UI.image(self, "res-coin", Rect2(ligne.position + Vector2(46.0, h / 2.0 + 2.0), Vector2(13.0, 13.0))):
					draw_circle(ligne.position + Vector2(52.0, h / 2.0 + 8.0), 6.0, Identite.OR)
				UI.texte(self, ligne.position + Vector2(63.0, h / 2.0 + 13.0), str(int(fiche["or"])), 10, Identite.OR)
				var peut: bool = dispo == "DISPONIBLE"
				var bouton := Rect2(ligne.end.x - 96.0, ligne.position.y + (h - 28.0) / 2.0, 88.0, 28.0)
				if peut:
					UI.bouton(self, bouton, Identite.VERT, "vc_%s" % type, false, Identite.RAYON_SM)
					UI.texte(self, bouton.get_center() + Vector2(0.0, 4.0), "CONSTRUIRE", 10, Identite.TEXTE, true, 4)
					_actions.append({"rect": bouton, "action": "construire:%s" % type})
				else:
					UI.bouton(self, bouton, Color(0.3, 0.32, 0.42), "vc_%s" % type, false, Identite.RAYON_SM)
					UI.texte(self, bouton.get_center() + Vector2(0.0, -2.0),
						"%d / %d" % [Profil.pieces, int(fiche["or"])], 10, Identite.OR, true, 2)
					UI.texte(self, bouton.get_center() + Vector2(0.0, 11.0), "GAGNER DES PIÈCES", 7,
						Identite.TEXTE_ATTENUE, true, 2)
					_actions.append({"rect": bouton, "action": "blocage:%s" % type})
			y += pas
		UI.texte(self, Vector2(rect.get_center().x, rect.end.y - 12.0),
			"VOIR LES BÂTIMENTS VERROUILLÉS", 9, Identite.TEXTE_ATTENUE, true, 3)

	# --------------------------------------------------------- construction

	func _ui_construction() -> void:
		var fiche: Dictionary = Cite.BATIMENTS.get(ville.type_en_construction, {})
		UI.banniere(self, Vector2(size.x / 2.0, 100.0), 440.0,
			"MODE CONSTRUCTION — %s" % str(fiche.get("titre", "")).to_upper(), 15)
		UI.texte(self, Vector2(size.x / 2.0, 128.0),
			"1. CHOISIS une case    2. PLACE le bâtiment    3. VALIDE", 11, Identite.CREME, true, 4)
		var y := size.y - 66.0
		var b_annuler := Rect2(size.x / 2.0 - 180.0, y, 104.0, 52.0)
		UI.bouton(self, b_annuler, Identite.ROUGE, "vb_annuler", false, Identite.RAYON_MD)
		UI.texte(self, b_annuler.get_center() + Vector2(0.0, 6.0), "ANNULER", 13, Identite.TEXTE, true)
		_actions.append({"rect": b_annuler, "action": "annuler"})
		var b_pivoter := Rect2(size.x / 2.0 - 56.0, y, 112.0, 52.0)
		UI.bouton(self, b_pivoter, Identite.BLEU, "vb_pivoter", false, Identite.RAYON_MD)
		UI.texte(self, b_pivoter.get_center() + Vector2(0.0, 6.0), "PIVOTER", 13, Identite.TEXTE, true)
		_actions.append({"rect": b_pivoter, "action": "pivoter"})
		var b_valider := Rect2(size.x / 2.0 + 76.0, y, 104.0, 52.0)
		UI.bouton(self, b_valider, Identite.VERT if bool(ville.fantome.valide) else Color(0.3, 0.32, 0.42),
			"vb_valider", false, Identite.RAYON_MD)
		UI.texte(self, b_valider.get_center() + Vector2(0.0, 6.0), "VALIDER", 13, Identite.TEXTE, true)
		_actions.append({"rect": b_valider, "action": "valider"})

	# --------------------------------------------------------- sélection

	func _ui_selection() -> void:
		var b: Dictionary = Profil.ville[ville.selection]
		var fiche: Dictionary = Cite.BATIMENTS[str(b.type)]
		var niveau := int(b.get("niveau", 1))
		# LES CONSÉQUENCES RÉELLES du bâtiment (simulation, pas décor).
		var effets: Array = []
		if int(fiche.get("capacite_population", 0)) > 0:
			effets.append("Capacité : +%d habitants" % int(fiche.capacite_population))
		var prod: Dictionary = fiche.get("production", {})
		if float(prod.get("nourriture_min", 0.0)) > 0.0:
			effets.append("Produit : +%.0f nourriture / min" % float(prod.nourriture_min))
		if float(prod.get("or_min", 0.0)) > 0.0:
			effets.append("Produit : +%.0f pièce(s) / min" % float(prod.or_min))
		if int(fiche.get("population_requise", 0)) > 0:
			effets.append("Condition : %d habitants" % int(fiche.population_requise))
		if not effets.is_empty():
			var bande_e := Rect2(size.x / 2.0 - 160.0, size.y - 148.0, 320.0, 24.0)
			UI.rect_degrade(self, bande_e, 12.0, Color(0.06, 0.12, 0.3, 0.9), Color(0.04, 0.08, 0.22, 0.9))
			UI.texte(self, bande_e.get_center() + Vector2(0.0, 4.0), "   —   ".join(effets), 10,
				Identite.CYAN, true, 1)
		# Trois actions tactiles (maquette : DÉPLACER / INFOS / AMÉLIORER).
		var y := size.y - 116.0
		var libelles: Array = [["deplacer", "DÉPLACER", Identite.BLEU],
			["infos", "INFOS", Identite.PANNEAU_CLAIR], ["ameliorer", "AMÉLIORER", Identite.VERT]]
		for i in libelles.size():
			var l: Array = libelles[i]
			var rect := Rect2(size.x / 2.0 - 186.0 + i * 128.0, y, 120.0, 48.0)
			UI.bouton(self, rect, l[2], "vs_%s" % str(l[0]), false, Identite.RAYON_MD)
			UI.texte(self, rect.get_center() + Vector2(0.0, 5.0), str(l[1]), 12, Identite.TEXTE, true)
			_actions.append({"rect": rect, "action": str(l[0])})
		# Bandeau ÉVOLUTION (maison) : « ma petite maison peut devenir ça ».
		if str(b.type) == "maison":
			var bande := Rect2(size.x / 2.0 - 310.0, size.y - 60.0, 620.0, 54.0)
			UI.panneau(self, bande)
			UI.texte(self, Vector2(bande.get_center().x, bande.position.y + 14.0),
				"MAISON DES AVENTURIERS — ÉVOLUTION", 10, Identite.OR, true, 4)
			for n in 5:
				var p := bande.position + Vector2(70.0 + n * 124.0, 34.0)
				var atteint: bool = n < niveau
				_mini_batiment_type(p, 9.0 + n * 3.0, "maison")
				if not atteint:
					draw_circle(p, 11.0 + n * 3.0, Color(0.05, 0.08, 0.2, 0.55))
				UI.texte(self, p + Vector2(0.0, 20.0), "Niv. %d" % (n + 1), 8,
					Identite.OR if atteint else Identite.TEXTE_ATTENUE, true, 3)
				if n < 4:
					UI.texte(self, p + Vector2(62.0, 4.0), "→", 12, Identite.TEXTE_ATTENUE, true, 3)

	# --------------------------------------------------------- pied

	## L'APPEL DU MONDE : un seul panneau, trois sources par priorité —
	## 1. le BLOCAGE que le joueur vient de rencontrer (son intention),
	## 2. le BESOIN principal dérivé de la simulation (cause réelle),
	## 3. sinon l'OBJECTIF de la ville (CityGoal). Jamais une todo-list.
	func _panneau_objectif() -> void:
		if not ville.blocage.is_empty():
			_panneau_blocage()
			return
		var besoins := ville.besoins_courants()
		var besoin := Besoins.principal(besoins)
		if not besoin.is_empty():
			_panneau_besoin(besoin, besoins.size() - 1)
			return
		_panneau_but()

	func _cadre_appel(titre: String, teinte: Color) -> Rect2:
		var rect := Rect2(8.0, size.y - 196.0, 264.0, 132.0)
		UI.rect_degrade(self, rect.grow(2.0), Identite.RAYON_MD, Identite.CONTOUR, Identite.CONTOUR)
		UI.rect_degrade(self, rect, Identite.RAYON_MD, Color("142a52"), Color("0d1a3a"))
		UI.contour_arrondi(self, rect, Identite.RAYON_MD, Color(teinte.r, teinte.g, teinte.b, 0.55), 1.5)
		UI.texte(self, Vector2(rect.position.x + 12.0, rect.position.y + 20.0), titre, 10, teinte, false, 3)
		return rect

	## Un besoin/opportunité : cause réelle + CE QUE le joueur peut faire.
	func _panneau_besoin(besoin: Dictionary, autres: int) -> void:
		var genre := str(besoin.genre)
		var opportunite: bool = str(besoin.motivation) == "OPPORTUNITY"
		var rect := _cadre_appel("QUOI DE NEUF ?" if opportunite else "BESOIN DE LA VILLE",
			Identite.OR if opportunite else Identite.CYAN)
		var x := rect.position.x + 12.0
		var textes: Dictionary = Besoins.TEXTES.get(genre, {})
		var type := str(besoin.batiment)
		var titre_bat := str(Cite.BATIMENTS.get(type, {}).get("titre", type))
		_mini_batiment_type(rect.position + Vector2(26.0, 44.0), 13.0, type)
		UI.texte(self, Vector2(x + 34.0, rect.position.y + 42.0), str(textes.get("titre", "")), 11,
			Identite.OR if opportunite else Identite.TEXTE)
		var descr := str(textes.get("description", ""))
		if descr.contains("%s"):
			descr = descr % titre_bat
		var lignes := _couper_texte(descr, 46)
		for i in lignes.size():
			UI.texte(self, Vector2(x, rect.position.y + 62.0 + i * 13.0), lignes[i], 9, Identite.TEXTE_ATTENUE)
		if autres > 0:
			UI.texte(self, Vector2(x, rect.position.y + 90.0),
				"%d autre%s chose%s à voir" % [autres, "s" if autres > 1 else "", "s" if autres > 1 else ""],
				8, Color(0.55, 0.6, 0.78))
		var reco := Besoins.recommandation(besoin)
		var cta := Rect2(x, rect.position.y + 94.0, rect.size.x - 24.0, 30.0)
		UI.bouton(self, cta, Identite.OR_SOMBRE if opportunite else Identite.ORANGE,
			"vb_%s" % genre, false, Identite.RAYON_SM)
		UI.texte(self, cta.get_center() + Vector2(0.0, 4.0), str(reco.get("label", "")), 11,
			Identite.TEXTE, true, 2)
		_actions.append({"rect": cta, "action": "reco:%s:%s" % [str(reco.get("action", "")), type]})

	## Le blocage rencontré : la VRAIE cause + le CTA qui la lève.
	func _panneau_blocage() -> void:
		var b: Dictionary = ville.blocage
		var genre := str(b.type)
		var rect := _cadre_appel("ENCORE VERROUILLÉ", Identite.VIOLET)
		var x := rect.position.x + 12.0
		var type := str(b.batiment)
		var titre_bat := str(Cite.BATIMENTS.get(type, {}).get("titre", type))
		var textes: Dictionary = Besoins.TEXTES.get(genre, {})
		var titre := str(textes.get("titre", ""))
		var cta_txt := str(textes.get("cta", ""))
		var action := "apprendre"
		match genre:
			"NOT_ENOUGH_COINS":
				titre = titre % int(b.manquant)
				action = "apprendre_gagner"
			"KNOWLEDGE_LOCK":
				titre = titre % int(b.palier_requis)
				action = "apprendre_progresser"
			"POPULATION_LOCK":
				titre = titre % [int(b.habitants_manquants), "S" if int(b.habitants_manquants) > 1 else ""]
				action = "fermer_blocage"
		_mini_batiment_type(rect.position + Vector2(26.0, 44.0), 13.0, type)
		UI.texte(self, Vector2(x + 34.0, rect.position.y + 42.0), titre, 11, Identite.TEXTE)
		var descr := str(textes.get("description", ""))
		if descr.contains("%s"):
			descr = descr % titre_bat
		# CHAÎNE DE CAUSALITÉ : la cause profonde derrière le manque.
		if b.has("cause"):
			descr = str(Besoins.TEXTES.get(str(b.cause), {}).get("description", descr))
			cta_txt = str(Besoins.TEXTES.get(str(b.cause), {}).get("cta", cta_txt))
			if str(b.cause) == "HOUSING_FULL":
				action = "reco:UPGRADE_HOUSING:maison"
			elif str(b.cause) == "FOOD_SHORTAGE":
				action = "reco:OPEN_BUILDING:potager"
		var lignes := _couper_texte(descr, 46)
		for i in lignes.size():
			UI.texte(self, Vector2(x, rect.position.y + 62.0 + i * 13.0), lignes[i], 9, Identite.TEXTE_ATTENUE)
		var cta := Rect2(x, rect.position.y + 94.0, rect.size.x - 24.0, 30.0)
		UI.bouton(self, cta, Identite.ORANGE, "vbl_%s" % genre, false, Identite.RAYON_SM)
		UI.texte(self, cta.get_center() + Vector2(0.0, 4.0), cta_txt, 11, Identite.TEXTE, true, 2)
		_actions.append({"rect": cta, "action": action})
		var fermer := Rect2(rect.end.x - 26.0, rect.position.y + 6.0, 20.0, 20.0)
		UI.texte(self, fermer.get_center() + Vector2(0.0, 5.0), "×", 14, Identite.TEXTE_ATTENUE, true)
		_actions.append({"rect": fermer, "action": "fermer_blocage"})

	## L'objectif de la ville (CityGoal) quand aucun besoin ne presse.
	func _panneau_but() -> void:
		var objectif := Cite.objectif_courant(Profil.connaissance_xp, Profil.pieces, Profil.ville)
		if objectif.is_empty():
			return
		var rect := _cadre_appel("BESOIN DE LA VILLE", Identite.CYAN)
		var x := rect.position.x + 12.0
		var type := str(objectif.get("batiment", ""))
		_mini_batiment_type(rect.position + Vector2(26.0, 44.0), 13.0, type)
		UI.texte(self, Vector2(x + 34.0, rect.position.y + 42.0), str(objectif.titre), 12, Identite.TEXTE)
		UI.texte(self, Vector2(x, rect.position.y + 62.0), str(objectif.description).left(44), 9,
			Identite.TEXTE_ATTENUE)
		var cout := int(Cite.BATIMENTS.get(type, {}).get("or", 0))
		if not UI.image(self, "res-coin", Rect2(rect.position + Vector2(12.0, 72.0), Vector2(14.0, 14.0))):
			draw_circle(rect.position + Vector2(19.0, 79.0), 6.0, Identite.OR)
		UI.texte(self, Vector2(x + 20.0, rect.position.y + 84.0), "%d pièces" % cout, 11, Identite.OR)
		var cta := Rect2(x, rect.position.y + 94.0, rect.size.x - 24.0, 30.0)
		match str(objectif.statut):
			"READY":
				UI.bouton(self, cta, Identite.VERT, "vo_construire", false, Identite.RAYON_SM)
				UI.texte(self, cta.get_center() + Vector2(0.0, 4.0), "CONSTRUIRE", 11, Identite.TEXTE, true, 3)
				_actions.append({"rect": cta, "action": "construire:%s" % type})
			"AVAILABLE":
				UI.texte(self, Vector2(x + 100.0, rect.position.y + 84.0),
					"%d / %d" % [Profil.pieces, cout], 10, Identite.TEXTE_ATTENUE)
				UI.bouton(self, cta, Identite.ORANGE, "vo_gagner", false, Identite.RAYON_SM)
				UI.texte(self, cta.get_center() + Vector2(0.0, 4.0), "GAGNER DES PIÈCES", 11,
					Identite.TEXTE, true, 3)
				_actions.append({"rect": cta, "action": "blocage:%s" % type})
			"BLOCKED":
				UI.bouton(self, cta, Identite.VIOLET, "vo_debloquer", false, Identite.RAYON_SM)
				UI.texte(self, cta.get_center() + Vector2(0.0, 4.0), "APPRENDRE POUR DÉBLOQUER", 10,
					Identite.TEXTE, true, 2)
				_actions.append({"rect": cta, "action": "apprendre"})

	func _couper_texte(txt: String, max_car: int) -> Array:
		if txt.length() <= max_car:
			return [txt]
		var coupe := txt.rfind(" ", max_car)
		if coupe <= 0:
			return [txt.left(max_car)]
		return [txt.substr(0, coupe), txt.substr(coupe + 1).left(max_car)]

	func _pied() -> void:
		var y := size.y - 56.0
		# Hibou : conseillé pour toi (secondaire).
		var conseil := Rect2(8.0, y, 292.0, 48.0)
		UI.rect_degrade(self, conseil.grow(2.0), Identite.RAYON_MD, Identite.CONTOUR, Identite.CONTOUR)
		UI.rect_degrade(self, conseil, Identite.RAYON_MD, Color("221d45"), Color("161231"))
		_dessiner_hibou(conseil.position + Vector2(26.0, 24.0), 16.0)
		UI.texte(self, conseil.position + Vector2(50.0, 19.0), "Conseillé pour toi", 11, Identite.OR)
		var conseil_txt := "Tu pourrais débloquer le Potager !"
		for pose in Profil.ville:
			if str(pose.type) == "potager":
				conseil_txt = "Continue d'apprendre pour l'Atelier !"
		UI.texte(self, conseil.position + Vector2(50.0, 36.0), conseil_txt, 10, Identite.TEXTE)
		# NAVIGATION PRINCIPALE — la ville est la Home : MA VILLE actif,
		# APPRENDRE mène à l'arbre des connaissances (section dédiée).
		var nav: Array = [["ville_actif", "MA VILLE"], ["apprendre", "APPRENDRE"],
			["collection", "COLLECTION"], ["progression", "PROGRESSION"]]
		for i in nav.size():
			var n: Array = nav[i]
			var rect := Rect2(size.x - 424.0 + i * 106.0, y, 100.0, 48.0)
			if i == 0:
				UI.rect_degrade(self, rect.grow(3.0), Identite.RAYON_MD + 3,
					Color(Identite.CYAN.r, Identite.CYAN.g, Identite.CYAN.b, 0.4),
					Color(Identite.CYAN.r, Identite.CYAN.g, Identite.CYAN.b, 0.12))
				UI.bouton(self, rect, Identite.BLEU, "vn_%d" % i, false, Identite.RAYON_MD)
			else:
				UI.bouton(self, rect, Identite.VIOLET if i == 1 else Identite.PANNEAU_CLAIR,
					"vn_%d" % i, false, Identite.RAYON_MD)
				_actions.append({"rect": rect, "action": str(n[0])})
			UI.texte(self, rect.get_center() + Vector2(0.0, 5.0), str(n[1]), 10, Identite.TEXTE, true)

	func _dessiner_hibou(p: Vector2, r: float) -> void:
		draw_circle(p + Vector2(0.0, r * 0.15), r * 0.62, Color("8a55f5"))
		draw_circle(p + Vector2(0.0, -r * 0.3), r * 0.5, Color("9d6ff8"))
		for c in [-1.0, 1.0]:
			draw_circle(p + Vector2(c * r * 0.2, -r * 0.32), r * 0.2, Color("fff3d5"))
			draw_circle(p + Vector2(c * r * 0.2, -r * 0.32), r * 0.1, Color("071633"))
		draw_colored_polygon(PackedVector2Array([
			p + Vector2(0.0, -r * 0.18), p + Vector2(-r * 0.1, -r * 0.05), p + Vector2(r * 0.1, -r * 0.05)]),
			Color("ffc928"))

extends MainLoop
## TESTS DE LOGIQUE des moteurs (fonctions pures — aucun profil requis).
## Lancer :
##   godot --headless --path godot --script res://scripts/test_simulation.gd
## La CI échoue si la sortie ne se termine pas par « ÉCHECS : 0 »
## (MainLoop n'expose pas de code de sortie : le workflow grep le bilan).
## Ce qui n'est PAS couvert ici est marqué NON VÉRIFIÉ, jamais supposé.

var echecs := 0


func _process(_delta: float) -> bool:
	return true   # un seul passage : tout se joue dans _initialize


func _initialize() -> void:
	var maison: Array = [{"type": "maison"}]
	var maison_potager: Array = [{"type": "maison"}, {"type": "potager"}]

	# 1. Une Maison des Aventuriers donne la bonne capacité.
	verifier(Simulation.capacite_population(maison) == 4, "capacité maison = 4")
	# 2. Un Potager augmente la production de nourriture.
	verifier(Simulation.production_nourriture_min(maison) == 0.0, "sans potager : 0 nourriture/min")
	verifier(Simulation.production_nourriture_min(maison_potager) == 2.0, "potager : +2 nourriture/min")
	# 3. La population consomme de la nourriture.
	verifier(absf(Simulation.consommation_nourriture_min(4) - 0.4) < 0.0001,
		"4 habitants consomment 0.4/min")
	# 4. La nourriture ne devient jamais négative.
	var affame := Simulation.tick({"ville": maison, "population": 4, "nourriture": 0.01}, 600.0)
	verifier(float(affame.nourriture) >= 0.0, "nourriture jamais négative")
	# 5. La population ne dépasse jamais sa capacité (croissance refusée).
	verifier(not Simulation.peut_croitre(maison, 4, 100.0), "pleine : pas de croissance")
	# 6. Pas de croissance pendant une pénurie (ni sans réserve).
	verifier(not Simulation.peut_croitre(maison, 3, 100.0), "pénurie : pas de croissance")
	verifier(not Simulation.peut_croitre(maison_potager, 3, 0.5), "réserve trop faible : pas de croissance")
	verifier(Simulation.peut_croitre(maison_potager, 3, 10.0), "place + surplus + réserve : croissance")
	# 7. Un Atelier verrouillé par connaissance ne peut pas être acheté.
	verifier(Simulation.disponibilite("atelier", 100, 10000, 10) == "VERROU_CONNAISSANCE",
		"atelier : verrou connaissance malgré 10 000 pièces")
	#    …et par population, même au bon palier.
	verifier(Simulation.disponibilite("atelier", 300, 10000, 2) == "VERROU_POPULATION",
		"atelier : verrou population")
	# 8. Impossible d'acheter sans assez de pièces.
	verifier(Simulation.disponibilite("potager", 100, 10, 2) == "PIECES_INSUFFISANTES",
		"potager : pièces insuffisantes")
	verifier(Simulation.disponibilite("potager", 100, 150, 2) == "DISPONIBLE", "potager : disponible")
	# Production de pièces : accumulation exacte (production × temps).
	var r := Simulation.tick({"ville": [{"type": "maison"}, {"type": "atelier"}],
		"population": 4, "nourriture": 50.0, "or_fraction": 0.0}, 120.0)
	verifier(int(r.or_gagne) == 2, "atelier : 2 pièces exactement en 2 min")
	# Statuts nourriture.
	verifier(Simulation.statut_nourriture(maison_potager, 2) == "SURPLUS", "statut SURPLUS")
	verifier(Simulation.statut_nourriture(maison, 4) == "PENURIE", "statut PENURIE")
	# Croissance : +1 habitant après l'intervalle configuré.
	var minutes := float(Simulation.EQUILIBRAGE.population.intervalle_croissance_min)
	var etat := {"ville": maison_potager, "population": 2, "nourriture": 10.0,
		"croissance_progres": 0.0, "or_fraction": 0.0}
	var arrive := false
	for i in int(minutes * 60.0 / 5.0) + 2:
		var pas := Simulation.tick(etat, 5.0)
		etat.nourriture = pas.nourriture
		etat.croissance_progres = pas.croissance_progres
		if bool(pas.habitant_arrive):
			arrive = true
			break
	verifier(arrive, "un habitant arrive après l'intervalle de croissance")

	# ---------------------------------------------- progression hors-ligne
	# 1-2. 1 h hors-ligne : bonnes quantités (nourriture et pièces).
	var hl := Simulation.simuler_periode({"ville": maison_potager, "population": 2,
		"nourriture": 10.0}, 3600.0)
	verifier(absf(float(hl.nourriture_produite) - 120.0) < 0.01, "1 h : +120 nourriture produite")
	var hl_or := Simulation.simuler_periode({"ville": [{"type": "maison"}, {"type": "atelier"}],
		"population": 4, "nourriture": 50.0}, 3600.0)
	verifier(int(hl_or.pieces_produites) == 60, "1 h d'atelier : +60 pièces")
	# 3. La population consomme pendant l'absence (et croît : 2→4 en 6 min,
	# conso exacte segmentée = 0.6 + 0.9 + 21.6 = 23.1).
	verifier(absf(float(hl.nourriture_consommee) - 23.1) < 0.5, "consommation hors-ligne exacte")
	# 7. La croissance hors-ligne fonctionne quand tout est réuni.
	verifier(int(hl.etat.population) == 4, "croissance hors-ligne jusqu'à la capacité")
	verifier(int(hl.nouveaux_habitants) == 2, "2 nouveaux habitants en 1 h")
	# 4-5. Nourriture jamais négative ; la pénurie arrête la croissance.
	var famine := Simulation.simuler_periode({"ville": maison, "population": 2,
		"nourriture": 1.0}, 3600.0)
	verifier(float(famine.etat.nourriture) >= 0.0, "hors-ligne : nourriture jamais négative")
	verifier(bool(famine.atteint_zero), "hors-ligne : zéro nourriture détecté")
	verifier(int(famine.etat.population) == 2, "hors-ligne : pénurie = croissance stoppée")
	# 6. Jamais au-delà de la capacité, même après 24 h simulées.
	var longue := Simulation.simuler_periode({"ville": maison_potager, "population": 2,
		"nourriture": 10.0}, 86400.0)
	verifier(int(longue.etat.population) == 4, "hors-ligne : capacité jamais dépassée")
	# 8. 24 h d'absence, plafond 12 h → 12 h simulées seulement.
	var fen := Simulation.duree_a_simuler(1000, 1000 + 86400)
	verifier(int(fen.duree_s) == 12 * 3600 and bool(fen.ecrete), "plafond : 24 h → 12 h simulées")
	# 10. Un timestamp futur ne casse rien (durée 0, pas de gains).
	var futur := Simulation.duree_a_simuler(2000, 1000)
	verifier(int(futur.duree_s) == 0, "horloge aberrante : durée 0")
	# 11-12. Rapport significatif ou non.
	verifier(not Simulation.rapport_significatif({"duree_s": 30, "pieces_produites": 500}),
		"30 s d'absence : pas de rapport")
	verifier(not Simulation.rapport_significatif({"duree_s": 7200, "pieces_produites": 0,
		"nouveaux_habitants": 0, "delta_nourriture": 0.2}), "rien à dire : pas de rapport")
	verifier(Simulation.rapport_significatif({"duree_s": 7200, "pieces_produites": 0,
		"nouveaux_habitants": 2, "delta_nourriture": 0.0}), "habitants arrivés : rapport montré")
	# 9 (anti-double-gain) : la règle pure est testée plus bas
	# (duree_a_simuler(t, t) == 0 → une période déjà comptée ne rejoue
	# rien) ; le chemin complet avec persistance n'est PAS exécutable en
	# headless --script (autoload Profil absent) : NON VÉRIFIÉ ici,
	# observé uniquement au scénario manuel.

	# ------------------------------------------------- moteur de besoins
	var memoire_vide := {"batiments_decouverts": []}
	# 1. Nourriture positive + grosse réserve → aucun besoin nourriture.
	var b1 := Besoins.evaluer({"ville": maison_potager, "population": 2,
		"nourriture": 500.0, "connaissance_xp": 0, "pieces": 0}, memoire_vide)
	verifier(not _contient(b1, "FOOD_WARNING") and not _contient(b1, "FOOD_SHORTAGE"),
		"surplus : aucun besoin nourriture")
	# 2. Net négatif mais réserve confortable → pas encore d'alerte.
	var b2 := Besoins.evaluer({"ville": maison, "population": 2,
		"nourriture": 500.0, "connaissance_xp": 0, "pieces": 0}, memoire_vide)
	verifier(not _contient(b2, "FOOD_WARNING"), "réserve de 41 h : pas de fausse urgence")
	# 3. Rupture proche → FOOD_WARNING (2 hab × 0.1/min, 4 unités = 20 min < 30).
	var b3 := Besoins.evaluer({"ville": maison, "population": 2,
		"nourriture": 4.0, "connaissance_xp": 0, "pieces": 0}, memoire_vide)
	verifier(_contient(b3, "FOOD_WARNING"), "rupture dans 20 min : alerte")
	# Hystérésis : à 35 min, l'alerte déjà active persiste, sinon non.
	var b3b := Besoins.evaluer({"ville": maison, "population": 2,
		"nourriture": 7.0, "connaissance_xp": 0, "pieces": 0}, memoire_vide, true)
	var b3c := Besoins.evaluer({"ville": maison, "population": 2,
		"nourriture": 7.0, "connaissance_xp": 0, "pieces": 0}, memoire_vide, false)
	verifier(_contient(b3b, "FOOD_WARNING") and not _contient(b3c, "FOOD_WARNING"),
		"hystérésis 30/45 min : pas de clignotement")
	# 4. Nourriture à zéro → FOOD_SHORTAGE.
	var b4 := Besoins.evaluer({"ville": maison, "population": 2,
		"nourriture": 0.0, "connaissance_xp": 0, "pieces": 0}, memoire_vide)
	verifier(_contient(b4, "FOOD_SHORTAGE"), "zéro nourriture : pénurie")
	# 5-6. Logements : sous la capacité non, à la capacité oui.
	verifier(not _contient(Besoins.evaluer({"ville": maison_potager, "population": 2,
		"nourriture": 100.0, "connaissance_xp": 0, "pieces": 0}, memoire_vide), "HOUSING_FULL"),
		"2/4 : pas de logements complets")
	var b6 := Besoins.evaluer({"ville": maison_potager, "population": 4,
		"nourriture": 100.0, "connaissance_xp": 0, "pieces": 0}, memoire_vide)
	verifier(_contient(b6, "HOUSING_FULL"), "4/4 : logements complets")
	# 7-8. Opportunité : atelier débloqué (palier 2, 4 hab) → une fois.
	var b7 := Besoins.evaluer({"ville": maison_potager, "population": 4,
		"nourriture": 100.0, "connaissance_xp": 250, "pieces": 0}, memoire_vide)
	verifier(_contient(b7, "BUILDING_AVAILABLE"), "atelier débloqué : opportunité")
	var b8 := Besoins.evaluer({"ville": maison_potager, "population": 4,
		"nourriture": 100.0, "connaissance_xp": 250, "pieces": 0},
		{"batiments_decouverts": ["atelier"]})
	verifier(not _contient(b8, "BUILDING_AVAILABLE"), "déjà découvert : plus de nouveauté")
	# 9-10. Blocage à l'intention : pièces manquantes, montant exact.
	var bl := Besoins.blocage_achat("potager", {"ville": maison, "population": 2,
		"nourriture": 10.0, "connaissance_xp": 100, "pieces": 80})
	verifier(str(bl.type) == "NOT_ENOUGH_COINS" and int(bl.manquant) == 20,
		"potager à 100 avec 80 pièces : il manque 20")
	# 11. Verrou de connaissance : la bonne cause.
	var bl2 := Besoins.blocage_achat("atelier", {"ville": maison, "population": 6,
		"nourriture": 10.0, "connaissance_xp": 100, "pieces": 10000})
	verifier(str(bl2.type) == "KNOWLEDGE_LOCK" and int(bl2.palier_requis) == 3,
		"atelier : verrou connaissance (palier affiché 3)")
	# Chaîne de causalité : population manquante ET logements complets.
	var bl4 := Besoins.blocage_achat("forge", {"ville": maison, "population": 4,
		"nourriture": 100.0, "connaissance_xp": 800, "pieces": 10000})
	verifier(str(bl4.type) == "POPULATION_LOCK" and int(bl4.habitants_manquants) == 2
		and str(bl4.get("cause", "")) == "HOUSING_FULL",
		"forge : manque 2 habitants CAR logements complets (causalité)")
	# 12. Le besoin nourriture disparaît quand la production suffit.
	var b12 := Besoins.evaluer({"ville": maison_potager, "population": 4,
		"nourriture": 4.0, "connaissance_xp": 0, "pieces": 0}, memoire_vide)
	verifier(not _contient(b12, "FOOD_WARNING") and not _contient(b12, "FOOD_SHORTAGE"),
		"potager construit : besoin nourriture résolu automatiquement")
	# 13. La priorité renvoie le plus important (pénurie > logements).
	var b13 := Besoins.evaluer({"ville": maison, "population": 4,
		"nourriture": 0.0, "connaissance_xp": 0, "pieces": 0}, memoire_vide)
	verifier(str(Besoins.principal(b13).genre) == "FOOD_SHORTAGE",
		"priorité : la pénurie passe avant les logements")
	# Capacité × niveau : une maison niveau 2 loge 8 habitants.
	verifier(Simulation.capacite_population([{"type": "maison", "niveau": 2}]) == 8,
		"maison améliorée : capacité doublée")

	# --------------------------------------------- boucle ville→apprendre
	# 1-2. Manque de pièces → intention EARN_COINS avec le bon montant.
	var blq := Besoins.blocage_achat("potager", {"ville": maison, "population": 2,
		"nourriture": 10.0, "connaissance_xp": 100, "pieces": 80})
	verifier(str(blq.action) == "EARN_COINS" and int(blq.manquant) == 20,
		"blocage pièces → intention EARN_COINS, manquant exact")
	var it := {"source": "ville", "raison": "gagner_pieces", "batiment": "potager", "montant": 40}
	var decode := Besoins.decoder_intention(Besoins.encoder_intention(it))
	verifier(str(decode.raison) == "gagner_pieces" and str(decode.batiment) == "potager"
		and int(decode.montant) == 40 and str(decode.retour) == "ville",
		"intention : aller-retour encodage sans perte (cible conservée)")
	# 3. Verrou de connaissance → GAIN_KNOWLEDGE.
	var blq2 := Besoins.blocage_achat("atelier", {"ville": maison, "population": 6,
		"nourriture": 10.0, "connaissance_xp": 50, "pieces": 10000})
	verifier(str(blq2.action) == "GAIN_KNOWLEDGE", "verrou connaissance → GAIN_KNOWLEDGE")
	# 4. Ordre des bloqueurs : connaissance avant population avant pièces.
	var blq3 := Besoins.blocage_achat("forge", {"ville": maison, "population": 2,
		"nourriture": 10.0, "connaissance_xp": 50, "pieces": 5})
	verifier(str(blq3.type) == "KNOWLEDGE_LOCK", "bloqueur structurel d'abord : connaissance")
	var blq4 := Besoins.blocage_achat("forge", {"ville": maison, "population": 2,
		"nourriture": 100.0, "connaissance_xp": 800, "pieces": 5})
	verifier(str(blq4.type) == "POPULATION_LOCK", "puis population, avant les pièces")
	# 8. Session arbre : intention vide → aucune redirection ville.
	verifier(Besoins.decoder_intention("").is_empty(), "session depuis l'arbre : intention vide")
	# 10. La récompense qui atteint la cible rend le bâtiment disponible.
	verifier(Simulation.disponibilite("potager", 100, 80, 2) == "PIECES_INSUFFISANTES"
		and Simulation.disponibilite("potager", 100, 125, 2) == "DISPONIBLE",
		"récompense suffisante → bâtiment automatiquement disponible")
	# (5-6, 12 : la règle pure du crédit unique est testée ci-dessous —
	# filtrer_recompense ; le branchement de l'interface de session n'est
	# pas exécutable en headless --script : NON VÉRIFIÉ ici, observé aux
	# captures. 7, 9, 11 : retours contextuels observés aux scénarios A-D,
	# NON VÉRIFIÉS par cette suite.)

	# ----------------------------------------- consolidation Prompts 1-5
	# ANTI-FARMING : l'XP de connaissance ne vient QUE d'une vraie
	# transition pédagogique (règle centralisée Cite.xp_progression).
	verifier(Cite.xp_progression(70, "apprentissage", "acquise") == 70,
		"transition vers ACQUISE : XP complète")
	verifier(Cite.xp_progression(70, "acquise", "maitrisee") == 35,
		"transition vers MAÎTRISÉE : moitié de l'XP")
	verifier(Cite.xp_progression(70, "decouverte", "apprentissage") == 0,
		"début d'apprentissage : pas encore d'XP")
	verifier(Cite.xp_progression(70, "maitrisee", "acquise") == 0,
		"régression d'état : jamais d'XP")
	var farm := 0
	for i in 10:
		farm += Cite.xp_progression(70, "maitrisee", "maitrisee")
	verifier(farm == 0, "10 sessions parfaites sur compétence maîtrisée : 0 XP")
	verifier(int(Cite.RECOMPENSES.question_or) > 0
		and not Cite.RECOMPENSES.has("question_xp"),
		"pièces par question conservées, question_xp supprimé du modèle")

	# IDEMPOTENCE DURABLE : une clé de récompense traitée ne crédite plus.
	var f1 := Cite.filtrer_recompense([], "s1:question:q1")
	verifier(not bool(f1.deja), "clé nouvelle : récompense acceptée")
	verifier(bool(Cite.filtrer_recompense(f1.traitees, "s1:question:q1").deja),
		"même clé rejouée : récompense refusée")
	verifier(not bool(Cite.filtrer_recompense(f1.traitees, "s1:question:q2").deja),
		"clé différente : acceptée")
	var traitees: Array = []
	for i in 250:
		traitees = Cite.filtrer_recompense(traitees, "cle_%d" % i).traitees
	verifier(traitees.size() == 200 and traitees.has("cle_249")
		and not traitees.has("cle_0"),
		"fenêtre glissante 200 : bornée, les plus récentes conservées")

	# COMPÉTENCES SUPPORTED : mapping générateur explicite, zéro fallback.
	verifier(Savoir.jouables() == ["nb_comparer", "fr_comparer"],
		"exactement 2 compétences jouables : nb_comparer, fr_comparer")
	verifier(Savoir.supportee("fr_comparer") and not Savoir.supportee("geo_aires"),
		"supportée = possède un générateur adapté")
	verifier(Savoir.recommander_parmi({"geo_aires": "a_consolider",
		"fr_comparer": "decouverte"}) == "fr_comparer",
		"recommandation : jamais une compétence non jouable")
	verifier(Savoir.recommander_parmi({"nb_comparer": "apprentissage",
		"fr_comparer": "a_consolider"}) == "fr_comparer",
		"recommandation : à consolider avant apprentissage")
	verifier(Savoir.recommander_parmi({"geo_aires": "apprentissage",
		"geo_angles": "decouverte"}) == "",
		"aucune jouable dans les états : recommandation vide, pas de fallback")
	var src_session := FileAccess.get_file_as_string("res://scripts/session.gd")
	verifier(src_session.contains("if generateur == \"\":")
		and src_session.contains("\t\treturn []"),
		"dispatch strict (source) : sans générateur, aucune question")

	# ÉCONOMIE 100 % API CENTRALE : aucun crédit/débit direct dispersé.
	var credit_direct := "pieces " + "+="
	var debit_direct := "pieces " + "-="
	var hors_api: Array = []
	for fichier in DirAccess.get_files_at("res://scripts"):
		if not fichier.ends_with(".gd") or fichier in ["profil.gd", "test_simulation.gd"]:
			continue
		var src := FileAccess.get_file_as_string("res://scripts/" + fichier)
		if src.contains(credit_direct) or src.contains(debit_direct):
			hors_api.append(fichier)
	verifier(hors_api.is_empty(),
		"aucun `pieces +=`/`pieces -=` hors profil.gd (trouvés : %s)" % [hors_api])
	var credits := 0
	var debits := 0
	for ligne in FileAccess.get_file_as_string("res://scripts/profil.gd").split("\n"):
		if ligne.strip_edges().begins_with("#"):
			continue
		credits += ligne.count(credit_direct)
		debits += ligne.count(debit_direct)
	verifier(credits == 1 and debits == 1,
		"profil.gd : un seul point de crédit et un seul point de débit (l'API)")

	# DÉPLACEMENT DE BÂTIMENT : transaction pure, sans économie.
	var origine := {"type": "maison", "x": 3, "y": 4, "rot": 0, "niveau": 3}
	var deplace := Cite.batiment_deplace(origine, 8, 9, 1)
	verifier(int(deplace.x) == 8 and int(deplace.y) == 9 and int(deplace.rot) == 1
		and int(deplace.niveau) == 3 and str(deplace.type) == "maison",
		"déplacement : position changée, niveau et type conservés")
	verifier(int(origine.x) == 3 and int(origine.niveau) == 3,
		"déplacement : l'original n'est jamais muté (copie profonde)")
	var occ := Cite.cases_occupees([{"type": "potager", "x": 0, "y": 0}])
	verifier(occ.has(Vector2i(1, 1)) and not occ.has(Vector2i(2, 2)),
		"cases occupées : empreinte 2×2 du potager exacte (collision fiable)")

	# REPRISE IMMÉDIATE : même instant → durée nulle, aucun gain rejouable.
	verifier(int(Simulation.duree_a_simuler(5000, 5000).duree_s) == 0,
		"reprise au même instant : durée 0 — une période comptée ne rejoue pas")

	# --------------------------------------------- fondation 3D (Prompt 6)
	# CONVENTIONS : 1 case = 1 unité, pivot au CENTRE de l'emprise AU SOL,
	# origine du monde au centre du terrain, rot = quarts de tour Y.
	verifier(AdaptateurRendu.position_monde(4, 4, 3).is_equal_approx(Vector3(-0.5, 0.0, -0.5)),
		"pivot 3D : centre de l'emprise, au sol (y = 0)")
	verifier(AdaptateurRendu.case_depuis_sol(Vector3(-5.5, 0.0, -5.5)) == Vector2i(0, 0)
		and AdaptateurRendu.case_depuis_sol(Vector3(5.5, 0.0, 5.5)) == Vector2i(11, 11),
		"sol → case : les coins de la grille 12×12 exacts")
	var insts := AdaptateurRendu.instructions([
		{"type": "maison", "x": 4, "y": 4, "rot": 1, "niveau": 3},
		{"type": "potager", "x": 0, "y": 0}])
	verifier(insts.size() == 2 and str(insts[0].type) == "maison"
		and int(insts[0].niveau) == 3 and int(insts[0].taille) == 3
		and absf(float(insts[0].rotation_y) - PI / 2.0) < 0.0001,
		"instructions de rendu : type, niveau, taille, rotation fidèles")
	verifier(int(insts[1].niveau) == 1
		and Vector3(insts[1].position).is_equal_approx(Vector3(-5.0, 0.0, -5.0)),
		"défauts : niveau 1, position exacte du potager en (0,0)")
	# La fabrique répond à TOUT le catalogue et la maison est une scène
	# indépendante (remplaçable plus tard par un vrai .glb).
	var sans_rendu: Array = []
	for type_b in Cite.BATIMENTS:
		if not FabriqueBatiments.types_geres().has(type_b):
			sans_rendu.append(type_b)
	verifier(sans_rendu.is_empty(),
		"fabrique : tout le catalogue a un rendu (manquants : %s)" % [sans_rendu])
	verifier(ResourceLoader.exists(str(FabriqueBatiments.SCENES.maison)),
		"maison des aventuriers : scène dédiée remplaçable présente")

	print("ÉCHECS : %d" % echecs)


func _contient(besoins: Array, genre: String) -> bool:
	for b in besoins:
		if str(b.genre) == genre:
			return true
	return false


func verifier(condition: bool, nom: String) -> void:
	if condition:
		print("  OK  — %s" % nom)
	else:
		echecs += 1
		printerr("ÉCHEC — %s" % nom)

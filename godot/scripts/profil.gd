extends Node
## Autoload `Profil` — LE système de jeu d'Iluminia : économie, progression
## et collection, persistés dans user:// (IndexedDB sur le web).
##
## LA BOUCLE DU JOUEUR (pourquoi on rejoue) :
##   jouer → TROPHÉES (monter de LIGUE, l'insigne du lobby)
##         → PIÈCES d'or (boutique : œufs, couleurs de Lumins)
##         → ŒUFS DE DRAGON (1er du match) → éclosion au SANCTUAIRE
##         → COLLECTION des 6 espèces → choisir son COMPAGNON qui vole
##           à côté de soi EN PARTIE, visible par tous.
##   + niveau par héros (paliers de couleurs) et niveau de compte.

const CHEMIN := "user://profil.cfg"

## Ligues de trophées : le rang à défendre (badge affiché au lobby).
const LIGUES := [
	{"nom": "Bronze", "seuil": 0, "couleur": Color(0.72, 0.48, 0.3)},
	{"nom": "Argent", "seuil": 100, "couleur": Color(0.75, 0.78, 0.85)},
	{"nom": "Or", "seuil": 250, "couleur": Color("ffc928")},
	{"nom": "Cristal", "seuil": 450, "couleur": Color("20cff3")},
	{"nom": "Légende", "seuil": 700, "couleur": Color("ef4e9b")},
]

## Trophées par rang de fin de match (jamais en dessous de 0 au total).
const TROPHEES_PAR_RANG := [30, 15, 5, -10]

const PALIERS_VARIANTES := [1, 2, 4, 6]  ## niveau de héros par variante
const PRIX_VARIANTE := 80                ## …ou achat direct en pièces
const PRIX_OEUF := 150
const XP_PAR_NIVEAU_HEROS := 100.0

## LA ROUTE DES TROPHÉES — la colonne vertébrale de la progression (modèle
## Trophy Road de Brawl Stars) : on démarre avec Max seul, chaque palier
## atteint offre une récompense à RÉCLAMER, dont les trois autres héros.
const ROUTE := [
	{"seuil": 20, "type": "pieces", "montant": 60},
	{"seuil": 40, "type": "heros", "nom": "Zep"},
	{"seuil": 60, "type": "oeuf"},
	{"seuil": 90, "type": "pieces", "montant": 120},
	{"seuil": 120, "type": "heros", "nom": "Nova"},
	{"seuil": 150, "type": "oeuf"},
	{"seuil": 190, "type": "pieces", "montant": 160},
	{"seuil": 230, "type": "espece", "nom": "Givre"},
	{"seuil": 280, "type": "heros", "nom": "Ficelle"},
	{"seuil": 340, "type": "oeuf"},
	{"seuil": 400, "type": "pieces", "montant": 300},
	{"seuil": 460, "type": "espece", "nom": "Orage"},
	{"seuil": 550, "type": "oeuf"},
	{"seuil": 640, "type": "pieces", "montant": 500},
	{"seuil": 720, "type": "espece", "nom": "Solaire"},
	{"seuil": 850, "type": "oeuf"},
	{"seuil": 1000, "type": "espece", "nom": "Éclipse"},
]

## Puissance des héros (modèle power level) : +3 % de vitesse et −3 % de
## recharge par niveau au-delà de 1. S'achète en pièces, plafonné à 5.
const PUISSANCE_MAX := 5
const COUTS_PUISSANCE := [100, 200, 400, 800]

## Gabarits de quêtes quotidiennes (3 tirées chaque jour, modèle daily
## quests) : {type suivi par evenement(), cible, récompense en pièces}.
const GABARITS_QUETES := [
	{"type": "gagner_matchs", "cible": 2, "pieces": 100, "texte": "Gagne %d matchs"},
	{"type": "deposer", "cible": 3, "pieces": 80, "texte": "Dépose le dragon %d fois"},
	{"type": "voler", "cible": 4, "pieces": 90, "texte": "Vole le dragon %d fois"},
	{"type": "bonnes_reponses", "cible": 6, "pieces": 80, "texte": "Donne %d bonnes réponses"},
	{"type": "capturer", "cible": 6, "pieces": 70, "texte": "Attrape le dragon %d fois"},
	{"type": "cristaux", "cible": 5, "pieces": 60, "texte": "Ramasse %d cristaux"},
	{"type": "jouer_matchs", "cible": 3, "pieces": 70, "texte": "Joue %d matchs"},
]

var personnage := "Max"
var variantes := {}              ## nom → indice de variante choisie
var debloquees := {}             ## nom → indices achetés/offerts
var xp_heros := {}               ## nom → XP gagnée en jouant CE héros
var xp := 0.0
var niveau := 1
var pieces := 0                  ## monnaie principale
var trophees := 0
var oeufs := 0                   ## œufs à faire éclore au Sanctuaire
var dragons := {}                ## espèce → nombre obtenu (collection)
var compagnon := ""              ## espèce qui vole à tes côtés en partie
var dernier_cadeau := 0
var son_actif := true
var tutoriel_fait := false
var heros_debloques: Array = ["Max"]  ## les autres se gagnent sur la Route
var puissance := {}                   ## nom → niveau de puissance (1..5)
var route_reclamee: Array = []        ## seuils déjà réclamés
var quetes: Array = []                ## les 3 quêtes du jour
var jour_quetes := 0

## PÉDAGOGIE (maths 5ème) : le chapitre travaillé et la MAÎTRISE par
## notion (0..100). La maîtrise monte avec les bonnes réponses, descend
## doucement avec les erreurs, et pilote le NIVEAU des questions (1→3).
var chapitre := "mixte"               ## clé de Questions.NOTIONS ou "mixte"
var maitrise := {}                    ## notion → 0..100

## ---- PIVOT « la connaissance est la source du pouvoir » ----
## PlayerLearningProfile + City (voir savoir.gd et cite.gd).
var classe := ""                      ## niveau scolaire déclaré ("" = à choisir)
var connaissance_xp := 0              ## l'XP DE CONNAISSANCE (paliers de la ville)
var competences := {}                 ## id → {"etat": String, "score": 0..100}
var ville: Array = []                 ## [{type, x, y, rot}] sur la grille invisible
## L'ÉCONOMIE SIMPLIFIÉE : « la connaissance débloque, les pièces
## achètent. » Une seule progression non dépensable (connaissance_xp),
## une seule monnaie (pieces). Le JOURNAL trace chaque mouvement
## (équilibrage, debug, anti-double-récompense).
var journal: Array = []               ## [{type, montant, source, t}] (100 max)
var deblocages_en_attente: Array = [] ## contenus du dernier palier franchi
## SIMULATION DE VILLE V1 (voir simulation.gd — la logique vit LÀ-BAS) :
var nourriture := 10.0                ## réserve de nourriture (flottant interne)
var population := 2                   ## habitants actuels (capacité = logements)
var croissance_progres := 0.0         ## secondes accumulées vers le prochain habitant
var or_fraction := 0.0                ## production de pièces en cours (< 1)
var dernier_tick := 0                 ## unix — prêt pour la simulation hors-ligne
var stats_semaine := {"acquises": 0, "maitrisees": 0, "difficultes": 0, "corrigees": 0,
	"minutes_apprentissage": 0}       ## le résumé de l'Espace Parent
var semaine_stats := 0                ## n° de semaine des stats (remise à zéro auto)


## ------------------------------------------------ économie centralisée
## Toute pièce gagnée passe par ICI (jamais de `pieces += n` dispersés) :
## créditée, journalisée, persistée — donc immédiatement visible dans la
## barre du haut et utilisable dans Ma Ville.
func crediter_pieces(montant: int, type: String, source := "") -> void:
	if montant <= 0:
		return
	pieces += montant
	_journaliser(type, montant, source)
	sauver()


## Débit ATOMIQUE : refuse (false) si le solde est insuffisant — jamais
## d'état « bâtiment acheté mais pièces non déduites ».
func debiter_pieces(montant: int, type: String, source := "") -> bool:
	if montant > pieces:
		return false
	pieces -= montant
	_journaliser(type, -montant, source)
	sauver()
	return true


## Tout gain d'XP DE CONNAISSANCE passe par ici : crédit, journal,
## DÉTECTION DE PALIER (les nouveaux déblocages sont mémorisés pour que
## l'interface déclenche la célébration). Renvoie le nouveau palier
## atteint, ou -1 si aucun n'a été franchi. La connaissance n'est PAS
## une monnaie : elle ne se dépense jamais, ne se retire jamais.
func crediter_connaissance(montant: int, source := "", competence := "") -> int:
	if montant <= 0:
		return -1
	var avant := Cite.palier(connaissance_xp)
	connaissance_xp += montant
	_journaliser("xp:%s" % source, montant, competence)
	var apres := Cite.palier(connaissance_xp)
	if apres > avant:
		for i in range(avant + 1, apres + 1):
			deblocages_en_attente.append_array(Cite.PALIERS[i].debloque)
	sauver()
	return apres if apres > avant else -1


func _journaliser(type: String, montant: int, source: String) -> void:
	journal.append({"type": type, "montant": montant, "source": source,
		"t": int(Time.get_unix_time_from_system())})
	if journal.size() > 100:
		journal = journal.slice(journal.size() - 100)


## État BRUT d'une compétence (sans la logique de prérequis — voir
## Savoir.etat() pour l'état effectif affiché).
func etat_competence_brut(id: String) -> String:
	return str(competences.get(id, {}).get("etat", "decouverte"))


func score_competence(id: String) -> float:
	return float(competences.get(id, {}).get("score", 0.0))


## Changement d'état d'une compétence + XP de connaissance à la clé.
## L'XP majeure vient de la PROGRESSION RÉELLE (nouvel état), jamais de
## la répétition de ce qui est déjà maîtrisé.
func fixer_etat_competence(id: String, etat: String, score := -1.0) -> int:
	_basculer_semaine_si_besoin()
	var avant := etat_competence_brut(id)
	var entree: Dictionary = competences.get(id, {"etat": "decouverte", "score": 0.0})
	entree.etat = etat
	if score >= 0.0:
		entree.score = clampf(score, 0.0, 100.0)
	competences[id] = entree
	var gain := 0
	var fiche := Savoir.competence(id)
	if not fiche.is_empty() and avant != etat:
		# XP à la première acquisition / maîtrise uniquement (anti-farm).
		if etat == "acquise" and not ["acquise", "maitrisee"].has(avant):
			gain = int(fiche.xp)
			stats_semaine.acquises += 1
		elif etat == "maitrisee" and avant != "maitrisee":
			gain = int(fiche.xp) / 2
			stats_semaine.maitrisees += 1
		elif etat == "a_consolider":
			stats_semaine.difficultes += 1
	if gain > 0:
		crediter_connaissance(gain, "maitrise", id)
	sauver()
	return gain


## Maîtrise moyenne d'un domaine (Espace Parent).
func maitrise_domaine(sujet: String, domaine: String) -> float:
	var liste: Array = Savoir.SUJETS.get(sujet, {}).get("domaines", {}).get(domaine, {}).get("competences", [])
	if liste.is_empty():
		return 0.0
	var total := 0.0
	for c in liste:
		total += score_competence(str(c.id))
	return total / liste.size()


func _basculer_semaine_si_besoin() -> void:
	var semaine := int(Time.get_unix_time_from_system() / 604800.0)
	if semaine != semaine_stats:
		semaine_stats = semaine
		stats_semaine = {"acquises": 0, "maitrisees": 0, "difficultes": 0,
			"corrigees": 0, "minutes_apprentissage": 0}


## AMORCE DE DÉMO du vertical slice : au tout premier lancement, quelques
## compétences reçoivent des états variés pour que l'arbre soit parlant.
## (Sera remplacé par le diagnostic progressif invisible.)
func _semer_demo_pivot() -> void:
	if not competences.is_empty():
		return
	var etats_demo := {
		"nb_lire": ["maitrisee", 94.0], "nb_comparer": ["acquise", 78.0],
		"nb_addsous": ["acquise", 74.0], "nb_multiplications": ["apprentissage", 72.0],
		"nb_divisions": ["apprentissage", 35.0],
		"fr_decouvrir": ["acquise", 76.0], "fr_representer": ["acquise", 70.0],
		"fr_comparer": ["apprentissage", 61.0],
		"geo_figures": ["acquise", 95.0], "geo_perimetres": ["apprentissage", 48.0],
		"geo_angles": ["apprentissage", 25.0],
	}
	for id in etats_demo:
		competences[id] = {"etat": etats_demo[id][0], "score": etats_demo[id][1]}
	connaissance_xp = 150
	if ville.is_empty():
		ville = [{"type": "maison", "x": 4, "y": 4, "rot": 0, "niveau": 1}]
	pieces = maxi(pieces, 150)
	sauver()


# ---------------------------------------------------------------- pédagogie

## Niveau de question adapté à la maîtrise de la notion.
func niveau_notion(notion: String) -> int:
	var m := float(maitrise.get(notion, 0.0))
	if m < 40.0:
		return 1
	if m < 75.0:
		return 2
	return 3


## Enregistre une réponse DU JOUEUR : la maîtrise bouge, le niveau suit.
## Retourne le delta appliqué (affichage).
func enregistrer_reponse(notion: String, bonne: bool) -> float:
	var delta := 3.0 if bonne else -1.5
	maitrise[notion] = clampf(float(maitrise.get(notion, 0.0)) + delta, 0.0, 100.0)
	sauver()
	return delta


func choisir_chapitre(cle: String) -> void:
	chapitre = cle
	sauver()


func _ready() -> void:
	for nom in Personnage3D.FICHES:
		debloquees[nom] = [0]
		variantes[nom] = 0
		xp_heros[nom] = 0.0
		puissance[nom] = 1
	charger()
	_regenerer_quetes_si_nouveau_jour()
	_semer_demo_pivot()
	Audio.definir_son(son_actif)


# ---------------------------------------------------------------- compte

func xp_requise() -> float:
	return 100.0 * pow(1.3, niveau - 1)


## Progression 0..1 vers le prochain niveau (capsule de niveau du lobby).
func progres_niveau() -> float:
	return clampf(xp / xp_requise(), 0.0, 1.0)


func gagner_xp(quantite: float) -> int:
	xp += quantite
	var niveaux_gagnes := 0
	while xp >= xp_requise():
		xp -= xp_requise()
		niveau += 1
		niveaux_gagnes += 1
	sauver()
	return niveaux_gagnes


func gagner_pieces(quantite: int) -> void:
	pieces += quantite
	sauver()


func depenser(cout: int) -> bool:
	if pieces < cout:
		return false
	pieces -= cout
	sauver()
	return true


## Trophées gagnés/perdus selon le rang (0 = premier). Retourne le delta.
func gagner_trophees(rang: int) -> int:
	var delta: int = TROPHEES_PAR_RANG[clampi(rang, 0, TROPHEES_PAR_RANG.size() - 1)]
	trophees = maxi(trophees + delta, 0)
	sauver()
	return delta


func ligue() -> Dictionary:
	var courante: Dictionary = LIGUES[0]
	for l in LIGUES:
		if trophees >= int(l.seuil):
			courante = l
	return courante


## Prochaine ligue (ou vide si Légende atteinte).
func ligue_suivante() -> Dictionary:
	for l in LIGUES:
		if trophees < int(l.seuil):
			return l
	return {}


# ---------------------------------------------------------------- héros

func niveau_heros(nom: String) -> int:
	return 1 + int(float(xp_heros.get(nom, 0.0)) / XP_PAR_NIVEAU_HEROS)


func progres_heros(nom: String) -> float:
	return fposmod(float(xp_heros.get(nom, 0.0)), XP_PAR_NIVEAU_HEROS) / XP_PAR_NIVEAU_HEROS


func gagner_xp_heros(nom: String, montant: float) -> int:
	var avant := niveau_heros(nom)
	xp_heros[nom] = float(xp_heros.get(nom, 0.0)) + montant
	sauver()
	return niveau_heros(nom) - avant


func choisir_personnage(nom: String) -> void:
	if Personnage3D.FICHES.has(nom):
		personnage = nom
		sauver()


## Variante accessible par palier de niveau du héros OU achetée.
func variante_accessible(nom: String, indice: int) -> bool:
	if indice == 0 or debloquees.get(nom, [0]).has(indice):
		return true
	return niveau_heros(nom) >= PALIERS_VARIANTES[clampi(indice, 0, PALIERS_VARIANTES.size() - 1)]


## Achat direct d'une variante en pièces (boutique de la garde-robe).
func acheter_variante(nom: String, indice: int) -> bool:
	if variante_accessible(nom, indice) or not depenser(PRIX_VARIANTE):
		return false
	debloquees[nom].append(indice)
	sauver()
	return true


func choisir_variante(nom: String, indice: int) -> bool:
	if variante_accessible(nom, indice):
		variantes[nom] = indice
		sauver()
		return true
	return false


func couleur_de(nom: String) -> Color:
	var fiche: Dictionary = Personnage3D.FICHES.get(nom, {})
	if fiche.is_empty():
		return Color.WHITE
	var palette: Array = fiche.variantes
	return palette[clampi(int(variantes.get(nom, 0)), 0, palette.size() - 1)]


# ---------------------------------------------------------------- dragons

func ajouter_oeuf(n := 1) -> void:
	oeufs += n
	sauver()


## Éclot un œuf : tire une espèce (pondérée par rareté). Doublon → pièces.
func eclore() -> Dictionary:
	if oeufs <= 0:
		return {}
	oeufs -= 1
	var total := 0
	for espece in Personnage3D.ESPECES:
		total += int(Personnage3D.ESPECES[espece].poids)
	var tirage := randi() % total
	var choisie := ""
	for espece in Personnage3D.ESPECES:
		tirage -= int(Personnage3D.ESPECES[espece].poids)
		if tirage < 0:
			choisie = espece
			break
	var nouveau: bool = not dragons.has(choisie)
	dragons[choisie] = int(dragons.get(choisie, 0)) + 1
	var bonus := 0
	if not nouveau:
		bonus = 50
		pieces += bonus
	elif compagnon == "":
		compagnon = choisie # premier dragon : il t'accompagne d'office
	sauver()
	return {"espece": choisie, "nouveau": nouveau, "pieces_bonus": bonus}


func choisir_compagnon(espece: String) -> bool:
	if dragons.has(espece):
		compagnon = espece
		sauver()
		return true
	return false


# ---------------------------------------------------------------- route des trophées

## Paliers atteints mais pas encore réclamés (badge du lobby).
func recompenses_en_attente() -> int:
	var n := 0
	for palier in ROUTE:
		if trophees >= int(palier.seuil) and not route_reclamee.has(int(palier.seuil)):
			n += 1
	return n


## Réclame un palier de la Route. Retourne la récompense accordée (ou {}).
func reclamer_route(seuil: int) -> Dictionary:
	if route_reclamee.has(seuil) or trophees < seuil:
		return {}
	for palier in ROUTE:
		if int(palier.seuil) != seuil:
			continue
		route_reclamee.append(seuil)
		match str(palier.type):
			"pieces":
				pieces += int(palier.montant)
			"oeuf":
				oeufs += 1
			"heros":
				if not heros_debloques.has(str(palier.nom)):
					heros_debloques.append(str(palier.nom))
			"espece":
				var espece := str(palier.nom)
				var nouveau: bool = not dragons.has(espece)
				dragons[espece] = int(dragons.get(espece, 0)) + 1
				if not nouveau:
					pieces += 50
				elif compagnon == "":
					compagnon = espece
		sauver()
		return palier
	return {}


func heros_est_debloque(nom: String) -> bool:
	return heros_debloques.has(nom)


## Seuil de la Route qui débloque ce héros (−1 si débloqué d'office).
func seuil_du_heros(nom: String) -> int:
	for palier in ROUTE:
		if str(palier.type) == "heros" and str(palier.nom) == nom:
			return int(palier.seuil)
	return -1


# ---------------------------------------------------------------- puissance

func puissance_de(nom: String) -> int:
	return int(puissance.get(nom, 1))


func cout_puissance(nom: String) -> int:
	var p := puissance_de(nom)
	if p >= PUISSANCE_MAX:
		return -1
	return COUTS_PUISSANCE[p - 1]


func ameliorer_puissance(nom: String) -> bool:
	var cout := cout_puissance(nom)
	if cout < 0 or not depenser(cout):
		return false
	puissance[nom] = puissance_de(nom) + 1
	sauver()
	return true


## Bonus de vitesse / réduction de recharge du héros (1.0 = aucun).
func bonus_puissance(nom: String) -> float:
	return 1.0 + 0.03 * (puissance_de(nom) - 1)


# ---------------------------------------------------------------- quêtes du jour

func _regenerer_quetes_si_nouveau_jour() -> void:
	if jour_quetes == _jour_courant() and not quetes.is_empty():
		return
	jour_quetes = _jour_courant()
	quetes = []
	# Trois gabarits distincts, tirés avec la graine du jour (stables).
	var rng := RandomNumberGenerator.new()
	rng.seed = jour_quetes
	var indices: Array = range(GABARITS_QUETES.size())
	for i in 3:
		var k: int = indices.pop_at(rng.randi() % indices.size())
		var gabarit: Dictionary = GABARITS_QUETES[k]
		quetes.append({
			"type": gabarit.type, "cible": int(gabarit.cible), "pieces": int(gabarit.pieces),
			"texte": str(gabarit.texte) % int(gabarit.cible), "progres": 0, "reclamee": false,
		})
	sauver()


## À appeler depuis l'arène quand un événement de jeu se produit.
## Retourne le texte des quêtes tout juste terminées (pour un toast).
func evenement(type: String, quantite := 1) -> Array:
	var terminees: Array = []
	for q in quetes:
		if str(q.type) == type and not bool(q.reclamee) and int(q.progres) < int(q.cible):
			q.progres = int(q.progres) + quantite
			if int(q.progres) >= int(q.cible):
				terminees.append(str(q.texte))
	if not terminees.is_empty():
		sauver()
	return terminees


func quetes_a_reclamer() -> int:
	var n := 0
	for q in quetes:
		if int(q.progres) >= int(q.cible) and not bool(q.reclamee):
			n += 1
	return n


func reclamer_quete(indice: int) -> int:
	if indice < 0 or indice >= quetes.size():
		return 0
	var q: Dictionary = quetes[indice]
	if int(q.progres) < int(q.cible) or bool(q.reclamee):
		return 0
	q.reclamee = true
	pieces += int(q.pieces)
	sauver()
	return int(q.pieces)


# ---------------------------------------------------------------- cadeau et son

func _jour_courant() -> int:
	return int(Time.get_unix_time_from_system() / 86400.0)


func cadeau_disponible() -> bool:
	return _jour_courant() > dernier_cadeau


## Cadeau du jour : un œuf (1 fois sur 3) ou une bourse de pièces.
func ouvrir_cadeau() -> Dictionary:
	if not cadeau_disponible():
		return {}
	dernier_cadeau = _jour_courant()
	var resultat := {}
	if randi() % 3 == 0:
		oeufs += 1
		resultat = {"type": "oeuf"}
	else:
		pieces += 80
		resultat = {"type": "pieces", "pieces": 80}
	sauver()
	return resultat


func basculer_son() -> void:
	son_actif = not son_actif
	Audio.definir_son(son_actif)
	sauver()


# ---------------------------------------------------------------- persistance

func sauver() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("profil", "personnage", personnage)
	cfg.set_value("profil", "variantes", variantes)
	cfg.set_value("profil", "debloquees", debloquees)
	cfg.set_value("profil", "xp_heros", xp_heros)
	cfg.set_value("profil", "xp", xp)
	cfg.set_value("profil", "niveau", niveau)
	cfg.set_value("profil", "pieces", pieces)
	cfg.set_value("profil", "trophees", trophees)
	cfg.set_value("profil", "oeufs", oeufs)
	cfg.set_value("profil", "dragons", dragons)
	cfg.set_value("profil", "compagnon", compagnon)
	cfg.set_value("profil", "dernier_cadeau", dernier_cadeau)
	cfg.set_value("profil", "son_actif", son_actif)
	cfg.set_value("profil", "tutoriel_fait", tutoriel_fait)
	cfg.set_value("profil", "heros_debloques", heros_debloques)
	cfg.set_value("profil", "puissance", puissance)
	cfg.set_value("profil", "route_reclamee", route_reclamee)
	cfg.set_value("profil", "quetes", quetes)
	cfg.set_value("profil", "jour_quetes", jour_quetes)
	cfg.set_value("profil", "chapitre", chapitre)
	cfg.set_value("profil", "maitrise", maitrise)
	cfg.set_value("profil", "classe", classe)
	cfg.set_value("profil", "connaissance_xp", connaissance_xp)
	cfg.set_value("profil", "competences", competences)
	cfg.set_value("profil", "journal", journal)
	cfg.set_value("profil", "deblocages_en_attente", deblocages_en_attente)
	cfg.set_value("profil", "nourriture", nourriture)
	cfg.set_value("profil", "population", population)
	cfg.set_value("profil", "croissance_progres", croissance_progres)
	cfg.set_value("profil", "or_fraction", or_fraction)
	cfg.set_value("profil", "dernier_tick", dernier_tick)
	cfg.set_value("profil", "ville", ville)
	cfg.set_value("profil", "stats_semaine", stats_semaine)
	cfg.set_value("profil", "semaine_stats", semaine_stats)
	cfg.save(CHEMIN)


func charger() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CHEMIN) != OK:
		return
	personnage = cfg.get_value("profil", "personnage", personnage)
	var v: Dictionary = cfg.get_value("profil", "variantes", variantes)
	var d: Dictionary = cfg.get_value("profil", "debloquees", debloquees)
	var xh: Dictionary = cfg.get_value("profil", "xp_heros", xp_heros)
	for nom in Personnage3D.FICHES:
		if v.has(nom):
			variantes[nom] = int(v[nom])
		if d.has(nom) and d[nom] is Array:
			debloquees[nom] = d[nom]
		if xh.has(nom):
			xp_heros[nom] = float(xh[nom])
	xp = float(cfg.get_value("profil", "xp", xp))
	niveau = int(cfg.get_value("profil", "niveau", niveau))
	# Migration : les anciennes « étoiles » deviennent des pièces.
	pieces = int(cfg.get_value("profil", "pieces", cfg.get_value("profil", "etoiles", pieces)))
	trophees = int(cfg.get_value("profil", "trophees", trophees))
	oeufs = int(cfg.get_value("profil", "oeufs", oeufs))
	dragons = cfg.get_value("profil", "dragons", dragons)
	compagnon = str(cfg.get_value("profil", "compagnon", compagnon))
	dernier_cadeau = int(cfg.get_value("profil", "dernier_cadeau", dernier_cadeau))
	son_actif = bool(cfg.get_value("profil", "son_actif", son_actif))
	tutoriel_fait = bool(cfg.get_value("profil", "tutoriel_fait", tutoriel_fait))
	var hd = cfg.get_value("profil", "heros_debloques", null)
	if hd is Array:
		heros_debloques = hd
	elif trophees > 0 or not dragons.is_empty():
		# Migration des anciens profils : tout était débloqué avant la Route.
		heros_debloques = Personnage3D.FICHES.keys()
	var pu: Dictionary = cfg.get_value("profil", "puissance", puissance)
	for nom in Personnage3D.FICHES:
		if pu.has(nom):
			puissance[nom] = int(pu[nom])
	chapitre = str(cfg.get_value("profil", "chapitre", chapitre))
	var ma = cfg.get_value("profil", "maitrise", maitrise)
	if ma is Dictionary:
		maitrise = ma
	classe = str(cfg.get_value("profil", "classe", classe))
	connaissance_xp = int(cfg.get_value("profil", "connaissance_xp", connaissance_xp))
	var co = cfg.get_value("profil", "competences", competences)
	if co is Dictionary:
		competences = co
	# (Migration : l'ancien champ « ressources » — gemmes violettes/bleues —
	# est simplement ignoré : une seule monnaie désormais, les pièces.)
	var jo = cfg.get_value("profil", "journal", journal)
	if jo is Array:
		journal = jo
	var da = cfg.get_value("profil", "deblocages_en_attente", deblocages_en_attente)
	if da is Array:
		deblocages_en_attente = da
	nourriture = float(cfg.get_value("profil", "nourriture", nourriture))
	population = int(cfg.get_value("profil", "population", population))
	croissance_progres = float(cfg.get_value("profil", "croissance_progres", croissance_progres))
	or_fraction = float(cfg.get_value("profil", "or_fraction", or_fraction))
	dernier_tick = int(cfg.get_value("profil", "dernier_tick", dernier_tick))
	var vi = cfg.get_value("profil", "ville", ville)
	if vi is Array:
		ville = vi
	var ss = cfg.get_value("profil", "stats_semaine", stats_semaine)
	if ss is Dictionary:
		stats_semaine = ss
	semaine_stats = int(cfg.get_value("profil", "semaine_stats", semaine_stats))
	var rr = cfg.get_value("profil", "route_reclamee", null)
	if rr is Array:
		route_reclamee = rr
	var qs = cfg.get_value("profil", "quetes", null)
	if qs is Array:
		quetes = qs
	jour_quetes = int(cfg.get_value("profil", "jour_quetes", jour_quetes))
	if not heros_debloques.has("Max"):
		heros_debloques.append("Max")
	if not Personnage3D.FICHES.has(personnage) or not heros_debloques.has(personnage):
		personnage = "Max"

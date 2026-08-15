class_name Besoins
extends RefCounted
## LE MOTEUR DE BESOINS DE LA VILLE — la ville génère naturellement la
## prochaine raison d'agir, à partir de son ÉTAT RÉEL (jamais une suite
## de quêtes scriptées, jamais une todo-list).
##
##   CityNeed  : ce qui SE PASSE (dérivé de la simulation — recalculé,
##               jamais persisté : une cause disparue = besoin disparu,
##               sans bouton « marquer comme résolu »).
##   CityGoal  : l'objectif concret proposé (cite.gd — OBJECTIFS).
##   CityActionRecommendation : ce que le joueur PEUT FAIRE (le CTA).
##
## Deux motivations : NEED (quelque chose limite la ville) et
## OPPORTUNITY (quelque chose de nouveau devient possible) — le jeu ne
## repose pas que sur des problèmes. La CAUSALITÉ est fondamentale :
## « Ta ville manque bientôt de nourriture. Un potager nourrirait
## davantage d'habitants. » — jamais « Mission : construis un potager ».
##
## Fonctions PURES (testables) ; la seule mémoire persistée est la liste
## des bâtiments DÉCOUVERTS (une opportunité ne se représente pas comme
## nouveauté éternellement) — distincte de débloqué / acheté / placé.

## Équilibrage des besoins — centralisé, provisoire.
const EQUILIBRAGE_BESOINS := {
	"nourriture": {
		"alerte_minutes": 30.0,      ## alerte si rupture estimée avant N min…
		"resolution_minutes": 45.0,  ## …et ne disparaît qu'au-delà (hystérésis,
	},                               ## jamais d'alerte qui clignote)
	"logement": {"ratio_alerte": 0.75},
	"ui": {"max_visibles": 3},
}

## PRIORITÉS : 100 blocage majeur, 80 pénurie imminente, 60 logement
## complet, 40 opportunité, 20-30 information/anticipation.
const PRIORITES := {"FOOD_SHORTAGE": 100, "FOOD_WARNING": 80, "HOUSING_FULL": 60,
	"BUILDING_AVAILABLE": 40, "LOW_HOUSING_CAPACITY": 30}

## WORDING CENTRALISÉ (l'appel du monde — cause réelle, peu de texte).
const TEXTES := {
	"FOOD_SHORTAGE": {"titre": "NOURRITURE INSUFFISANTE",
		"description": "Tes habitants consomment plus que ta ville ne produit.",
		"cta": "AMÉLIORER LA PRODUCTION"},
	"FOOD_WARNING": {"titre": "LA NOURRITURE DIMINUE",
		"description": "Ta réserve sera bientôt épuisée — un potager nourrirait tes habitants.",
		"cta": "VOIR LE POTAGER"},
	"HOUSING_FULL": {"titre": "PLUS DE PLACE !",
		"description": "Tes logements sont complets. Agrandis-les pour accueillir de nouveaux habitants.",
		"cta": "AMÉLIORER TA MAISON"},
	"LOW_HOUSING_CAPACITY": {"titre": "LA VILLE SE REMPLIT",
		"description": "Tes logements seront bientôt complets.",
		"cta": "VOIR LES LOGEMENTS"},
	"BUILDING_AVAILABLE": {"titre": "NOUVEAU BÂTIMENT !",
		"description": "%s est maintenant disponible dans ta ville.",
		"cta": "DÉCOUVRIR"},
	"NOT_ENOUGH_COINS": {"titre": "IL TE MANQUE %d PIÈCES",
		"description": "Apprends pour gagner les pièces qui te manquent.",
		"cta": "GAGNER DES PIÈCES"},
	"KNOWLEDGE_LOCK": {"titre": "NIVEAU DE CONNAISSANCE %d REQUIS",
		"description": "Progresse dans tes connaissances pour débloquer %s.",
		"cta": "PROGRESSER"},
	"POPULATION_LOCK": {"titre": "IL MANQUE %d HABITANT%s",
		"description": "Fais grandir ta ville avant de construire %s.",
		"cta": "VOIR MA VILLE"},
}


## Encodage/décodage du LearningIntent (transport par variable
## d'environnement entre écrans) — PURS et testables. Format :
## source:raison:batiment:montant:palier (champs vides autorisés).
static func encoder_intention(i: Dictionary) -> String:
	return "%s:%s:%s:%d:%d" % [str(i.get("source", "")), str(i.get("raison", "")),
		str(i.get("batiment", "")), int(i.get("montant", 0)), int(i.get("palier", 0))]


static func decoder_intention(brut: String) -> Dictionary:
	if brut == "":
		return {}
	var p := brut.split(":")
	return {"source": p[0], "raison": p[1] if p.size() > 1 else "",
		"retour": p[0], "batiment": p[2] if p.size() > 2 else "",
		"montant": int(p[3]) if p.size() > 3 else 0,
		"palier": int(p[4]) if p.size() > 4 else 0}


## Minutes avant la rupture de nourriture (INF si le taux net est ≥ 0) —
## pour ne jamais créer de fausse urgence avec 500 en réserve.
static func temps_avant_rupture(ville_posee: Array, population: int, nourriture: float) -> float:
	var taux := Simulation.taux_net_nourriture(ville_posee, population)
	if taux >= 0.0:
		return INF
	return nourriture / -taux


## ÉVALUE LES BESOINS depuis l'état — PURE. `memoire` =
## {batiments_decouverts} ; `alerte_active` = l'alerte nourriture était
## affichée (hystérésis : seuils d'entrée/sortie différents).
static func evaluer(etat: Dictionary, memoire: Dictionary, alerte_active := false) -> Array:
	var besoins: Array = []
	var ville_posee: Array = etat.ville
	var population := int(etat.population)
	var nourriture := float(etat.nourriture)
	var capacite := Simulation.capacite_population(ville_posee)
	# --- NOURRITURE (avec anticipation de rupture + hystérésis).
	var rupture := temps_avant_rupture(ville_posee, population, nourriture)
	if nourriture <= 0.01 and Simulation.taux_net_nourriture(ville_posee, population) < 0.0:
		besoins.append(_besoin("FOOD_SHORTAGE", "NEED", "potager"))
	elif rupture < (float(EQUILIBRAGE_BESOINS.nourriture.resolution_minutes) if alerte_active
			else float(EQUILIBRAGE_BESOINS.nourriture.alerte_minutes)):
		besoins.append(_besoin("FOOD_WARNING", "NEED", "potager"))
	# --- LOGEMENT.
	if capacite > 0 and population >= capacite:
		besoins.append(_besoin("HOUSING_FULL", "NEED", "maison"))
	elif capacite > 0 and float(population) / capacite >= float(EQUILIBRAGE_BESOINS.logement.ratio_alerte):
		besoins.append(_besoin("LOW_HOUSING_CAPACITY", "NEED", "maison"))
	# --- OPPORTUNITÉS : bâtiment fraîchement débloqué, jamais encore
	# découvert (débloqué ≠ découvert ≠ acheté ≠ placé).
	var decouverts: Array = memoire.get("batiments_decouverts", [])
	var possedes := {}
	for b in ville_posee:
		possedes[str(b.type)] = true
	for type in Cite.BATIMENTS:
		if int(Cite.BATIMENTS[type].palier) == 0 or possedes.has(str(type)) \
				or decouverts.has(str(type)):
			continue
		var dispo := Simulation.disponibilite(str(type), int(etat.connaissance_xp),
			int(etat.get("pieces", 0)), population)
		if dispo == "DISPONIBLE" or dispo == "PIECES_INSUFFISANTES":
			besoins.append(_besoin("BUILDING_AVAILABLE", "OPPORTUNITY", str(type)))
	besoins.sort_custom(func(a, b): return int(a.priorite) > int(b.priorite))
	return besoins


static func _besoin(genre: String, motivation: String, batiment: String) -> Dictionary:
	return {"id": genre.to_lower() + ":" + batiment, "genre": genre,
		"motivation": motivation, "priorite": int(PRIORITES.get(genre, 20)),
		"batiment": batiment}


## LE besoin principal — un seul à la fois sur la Home.
static func principal(besoins: Array) -> Dictionary:
	return besoins[0] if not besoins.is_empty() else {}


## BLOCAGE D'ACHAT — apparaît quand le joueur EXPRIME UNE INTENTION
## (il touche un bâtiment), jamais en permanence. Le système explique la
## vraie cause, avec la CHAÎNE DE CAUSALITÉ : « il manque 1 habitant »
## ET « tes logements sont complets » quand c'est la cause profonde.
static func blocage_achat(type: String, etat: Dictionary) -> Dictionary:
	var fiche: Dictionary = Cite.BATIMENTS.get(type, {})
	var dispo := Simulation.disponibilite(type, int(etat.connaissance_xp),
		int(etat.pieces), int(etat.population))
	match dispo:
		"VERROU_CONNAISSANCE":
			return {"type": "KNOWLEDGE_LOCK", "batiment": type,
				"palier_requis": int(fiche.get("palier", 0)) + 1,
				"action": "GAIN_KNOWLEDGE"}
		"VERROU_POPULATION":
			var manquants := int(fiche.get("population_requise", 0)) - int(etat.population)
			var blocage := {"type": "POPULATION_LOCK", "batiment": type,
				"habitants_manquants": manquants, "action": "OPEN_CITY"}
			# La cause profonde : plus de place, ou plus de nourriture ?
			var capacite := Simulation.capacite_population(etat.ville)
			if int(etat.population) >= capacite:
				blocage.cause = "HOUSING_FULL"
			elif Simulation.statut_nourriture(etat.ville, int(etat.population)) == "PENURIE":
				blocage.cause = "FOOD_SHORTAGE"
			return blocage
		"PIECES_INSUFFISANTES":
			return {"type": "NOT_ENOUGH_COINS", "batiment": type,
				"manquant": int(fiche.get("or", 0)) - int(etat.pieces),
				"action": "EARN_COINS"}
	return {}


## Ce que le joueur PEUT FAIRE — séparé du besoin (qui décrit ce qui se
## passe). L'action transporte tout le contexte pour le futur pont vers
## l'apprentissage (raison, cible, montant, retour ville).
static func recommandation(besoin: Dictionary) -> Dictionary:
	var genre := str(besoin.get("genre", ""))
	var batiment := str(besoin.get("batiment", ""))
	var textes: Dictionary = TEXTES.get(genre, {})
	match genre:
		"FOOD_SHORTAGE", "FOOD_WARNING", "LOW_HOUSING_CAPACITY":
			return {"label": str(textes.get("cta", "")), "action": "OPEN_BUILDING",
				"batiment": batiment, "raison": str(besoin.get("id", ""))}
		"HOUSING_FULL":
			return {"label": str(textes.get("cta", "")), "action": "UPGRADE_HOUSING",
				"batiment": batiment, "raison": str(besoin.get("id", ""))}
		"BUILDING_AVAILABLE":
			return {"label": str(textes.get("cta", "")), "action": "DISCOVER_BUILDING",
				"batiment": batiment, "raison": str(besoin.get("id", ""))}
	return {}

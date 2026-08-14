class_name Savoir
extends RefCounted
## L'ARBRE DES CONNAISSANCES — le cœur d'Illuminia après le pivot :
## « apprendre est la façon de devenir puissant ».
##
## Modèle GÉNÉRIQUE multi-matières (le prototype ne remplit que les
## mathématiques) : matières → domaines → compétences, avec prérequis,
## niveaux scolaires, XP de connaissance et pont vers le générateur de
## questions (questions.gd). Rien n'est câblé « maths uniquement » :
## ajouter une matière = ajouter une entrée de données.
##
## ÉTATS d'une compétence (leur RENDU visuel vit dans l'interface,
## jamais ici — les symboles pourront changer sans toucher au métier) :
##   verrouillee   → prérequis non atteints
##   decouverte    → accessible, jamais travaillée
##   apprentissage → en cours d'acquisition
##   acquise       → validée
##   maitrisee     → démontrée durablement
##   a_consolider  → maîtrise ancienne à revérifier (mémoire long terme)

const ETATS := ["verrouillee", "decouverte", "apprentissage", "acquise", "maitrisee", "a_consolider"]

## Niveaux scolaires couverts (déclaré au premier lancement, affiné
## ensuite par l'observation des réponses — jamais un gros test initial).
const CLASSES := ["CM1", "CM2", "6e", "5e", "4e", "3e"]

## matières → domaines → compétences.
## Compétence : {id, titre, niveaux (classes concernées), prerequis (ids),
## xp (récompense de connaissance), questions ({notion, niveau} du
## générateur — pont v1 vers questions.gd ; les futures banques de
## questions/misconceptions/remédiations s'accrochent ici).
const SUJETS := {
	"mathematiques": {
		"titre": "Mathématiques",
		"domaines": {
			"calcul": {
				"titre": "Calcul mental",
				"competences": [
					{"id": "calc_addition", "titre": "Additionner de tête",
						"niveaux": ["CM1", "CM2"], "prerequis": [], "xp": 40,
						"questions": {"notion": "priorites", "niveau": 1}},
					{"id": "calc_dizaine", "titre": "Passer par la dizaine",
						"niveaux": ["CM1", "CM2", "6e"], "prerequis": ["calc_addition"], "xp": 60,
						"questions": {"notion": "priorites", "niveau": 1}},
					{"id": "calc_priorites", "titre": "Priorités opératoires",
						"niveaux": ["5e", "4e"], "prerequis": ["calc_dizaine"], "xp": 80,
						"questions": {"notion": "priorites", "niveau": 2}},
				],
			},
			"nombres": {
				"titre": "Nombres",
				"competences": [
					{"id": "nb_lire", "titre": "Lire les grands nombres",
						"niveaux": ["CM1", "CM2"], "prerequis": [], "xp": 40,
						"questions": {"notion": "relatifs", "niveau": 1}},
					{"id": "nb_comparer", "titre": "Comparer des nombres",
						"niveaux": ["CM1", "CM2", "6e"], "prerequis": ["nb_lire"], "xp": 50,
						"questions": {"notion": "relatifs", "niveau": 1}},
					{"id": "nb_relatifs", "titre": "Nombres relatifs",
						"niveaux": ["5e", "4e"], "prerequis": ["nb_comparer"], "xp": 90,
						"questions": {"notion": "relatifs", "niveau": 2}},
				],
			},
			"fractions": {
				"titre": "Fractions",
				"competences": [
					{"id": "fr_comprendre", "titre": "Comprendre une fraction",
						"niveaux": ["CM1", "CM2"], "prerequis": [], "xp": 50,
						"questions": {"notion": "fractions", "niveau": 1}},
					{"id": "fr_comparer", "titre": "Comparer des fractions",
						"niveaux": ["CM2", "6e", "5e"], "prerequis": ["fr_comprendre"], "xp": 70,
						"questions": {"notion": "fractions", "niveau": 2}},
					{"id": "fr_equivalentes", "titre": "Fractions équivalentes",
						"niveaux": ["6e", "5e"], "prerequis": ["fr_comprendre"], "xp": 80,
						"questions": {"notion": "fractions", "niveau": 1}},
				],
			},
			"geometrie": {
				"titre": "Géométrie",
				"competences": [
					{"id": "geo_perimetres", "titre": "Périmètres",
						"niveaux": ["CM1", "CM2", "6e"], "prerequis": [], "xp": 50,
						"questions": {"notion": "geometrie", "niveau": 2}},
					{"id": "geo_aires", "titre": "Aires",
						"niveaux": ["6e", "5e"], "prerequis": ["geo_perimetres"], "xp": 70,
						"questions": {"notion": "geometrie", "niveau": 2}},
					{"id": "geo_angles", "titre": "Angles du triangle",
						"niveaux": ["5e", "4e"], "prerequis": ["geo_aires"], "xp": 90,
						"questions": {"notion": "geometrie", "niveau": 1}},
				],
			},
		},
	},
	# Les matières suivantes existent dans le modèle dès maintenant :
	# leur contenu arrivera sans changer l'architecture.
	"francais": {"titre": "Français", "domaines": {}},
	"sciences": {"titre": "Sciences", "domaines": {}},
	"histoire": {"titre": "Histoire", "domaines": {}},
	"geographie": {"titre": "Géographie", "domaines": {}},
}


## Toutes les compétences d'une matière, à plat.
static func competences(sujet: String) -> Array:
	var sortie: Array = []
	var domaines: Dictionary = SUJETS.get(sujet, {}).get("domaines", {})
	for cle in domaines:
		sortie.append_array(domaines[cle].competences)
	return sortie


static func competence(id: String) -> Dictionary:
	for sujet in SUJETS:
		for c in competences(sujet):
			if str(c.id) == id:
				return c
	return {}


## L'état d'une compétence pour le profil courant : verrouillée tant que
## ses prérequis ne sont pas au moins ACQUIS, sinon l'état enregistré
## (découverte par défaut).
static func etat(id: String) -> String:
	var fiche := competence(id)
	if fiche.is_empty():
		return "verrouillee"
	for pre in fiche.prerequis:
		if not ["acquise", "maitrisee"].has(Profil.etat_competence_brut(str(pre))):
			return "verrouillee"
	return Profil.etat_competence_brut(id)


## RECOMMANDATION FORTE (+ liberté : l'enfant peut choisir toute
## compétence déverrouillée) : la première à consolider, sinon la
## première en apprentissage, sinon une découverte accessible.
static func recommandation(sujet := "mathematiques") -> String:
	var candidates := {"a_consolider": "", "apprentissage": "", "decouverte": ""}
	for c in competences(sujet):
		var e := etat(str(c.id))
		if candidates.has(e) and candidates[e] == "":
			candidates[e] = str(c.id)
	for cle in ["a_consolider", "apprentissage", "decouverte"]:
		if candidates[cle] != "":
			return candidates[cle]
	return ""

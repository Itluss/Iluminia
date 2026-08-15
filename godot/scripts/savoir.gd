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
			"nombres_calculs": {
				"titre": "Nombres et calculs",
				"competences": [
					{"id": "nb_lire", "titre": "Lire les grands nombres",
						"niveaux": ["CM1", "CM2"], "prerequis": [], "xp": 40,
						"questions": {"notion": "relatifs", "niveau": 1}},
					{"id": "nb_comparer", "titre": "Comparer des nombres",
						"niveaux": ["CM1", "CM2", "6e"], "prerequis": ["nb_lire"], "xp": 50,
						"generateur": "comparer_entiers",
						"questions": {"notion": "relatifs", "niveau": 1}},
					{"id": "nb_addsous", "titre": "Additions et soustractions",
						"niveaux": ["CM1", "CM2"], "prerequis": ["nb_comparer"], "xp": 60,
						"questions": {"notion": "priorites", "niveau": 1}},
					{"id": "nb_multiplications", "titre": "Multiplications",
						"niveaux": ["CM1", "CM2", "6e"], "prerequis": ["nb_addsous"], "xp": 70,
						"questions": {"notion": "priorites", "niveau": 1}},
					{"id": "nb_divisions", "titre": "Divisions",
						"niveaux": ["CM2", "6e"], "prerequis": ["nb_addsous"], "xp": 80,
						"questions": {"notion": "priorites", "niveau": 2}},
				],
			},
			"fractions": {
				"titre": "Fractions",
				"competences": [
					{"id": "fr_decouvrir", "titre": "Découvrir les fractions",
						"niveaux": ["CM1", "CM2"], "prerequis": [], "xp": 50,
						"questions": {"notion": "fractions", "niveau": 1}},
					{"id": "fr_representer", "titre": "Représenter une fraction",
						"niveaux": ["CM1", "CM2"], "prerequis": ["fr_decouvrir"], "xp": 60,
						"questions": {"notion": "fractions", "niveau": 1}},
					{"id": "fr_comparer", "titre": "Comparer des fractions",
						"niveaux": ["CM2", "6e", "5e"], "prerequis": ["fr_representer"], "xp": 70,
						"generateur": "comparer_fractions",
						"questions": {"notion": "fractions", "niveau": 2}},
					{"id": "fr_equivalentes", "titre": "Fractions équivalentes",
						"niveaux": ["6e", "5e"], "prerequis": ["fr_comparer"], "xp": 80,
						"questions": {"notion": "fractions", "niveau": 1}},
					{"id": "fr_additionner", "titre": "Additionner des fractions",
						"niveaux": ["6e", "5e"], "prerequis": ["fr_equivalentes"], "xp": 90,
						"questions": {"notion": "fractions", "niveau": 2}},
				],
			},
			"geometrie": {
				"titre": "Géométrie",
				"competences": [
					{"id": "geo_figures", "titre": "Les figures planes",
						"niveaux": ["CM1", "CM2"], "prerequis": [], "xp": 40,
						"questions": {"notion": "geometrie", "niveau": 1}},
					{"id": "geo_perimetres", "titre": "Périmètres",
						"niveaux": ["CM1", "CM2", "6e"], "prerequis": ["geo_figures"], "xp": 50,
						"questions": {"notion": "geometrie", "niveau": 2}},
					{"id": "geo_aires", "titre": "Aires",
						"niveaux": ["6e", "5e"], "prerequis": ["geo_perimetres"], "xp": 70,
						"questions": {"notion": "geometrie", "niveau": 2}},
					{"id": "geo_angles", "titre": "Angles",
						"niveaux": ["CM2", "6e"], "prerequis": ["geo_figures"], "xp": 70,
						"questions": {"notion": "geometrie", "niveau": 1}},
					{"id": "geo_symetrie", "titre": "Symétrie",
						"niveaux": ["CM1", "CM2"], "prerequis": ["geo_angles"], "xp": 80,
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
	var profil := _profil()
	for pre in fiche.prerequis:
		if not ["acquise", "maitrisee"].has(profil.etat_competence_brut(str(pre))):
			return "verrouillee"
	return profil.etat_competence_brut(id)


## L'autoload Profil résolu à l'EXÉCUTION : les fonctions pures de ce
## fichier restent compilables (et testables) sans le jeu complet.
static func _profil() -> Node:
	return (Engine.get_main_loop() as SceneTree).root.get_node("Profil")


## Une compétence est SUPPORTED si un générateur de questions ADAPTÉ
## existe réellement — jamais de session qui prétend travailler une
## compétence en posant un exercice sans rapport. Les autres nœuds
## restent visibles dans l'arbre : « BIENTÔT DISPONIBLE ».
static func supportee(id: String) -> bool:
	return competence(id).has("generateur")


## Les compétences réellement jouables (pur, testé).
static func jouables() -> Array:
	var sortie: Array = []
	for sujet in SUJETS:
		for c in competences(sujet):
			if c.has("generateur"):
				sortie.append(str(c.id))
	return sortie


## Le cœur PUR de la recommandation (testé) : parmi des états donnés,
## la première candidate JOUABLE — à consolider > apprentissage >
## découverte. Une compétence non supportée n'est jamais retournée.
static func recommander_parmi(etats: Dictionary, sujet := "mathematiques") -> String:
	var candidates := {"a_consolider": "", "apprentissage": "", "decouverte": ""}
	for c in competences(sujet):
		if not c.has("generateur"):
			continue
		var e := str(etats.get(str(c.id), "verrouillee"))
		if candidates.has(e) and candidates[e] == "":
			candidates[e] = str(c.id)
	for cle in ["a_consolider", "apprentissage", "decouverte"]:
		if candidates[cle] != "":
			return candidates[cle]
	return ""


## RECOMMANDATION FORTE (+ liberté : l'enfant peut choisir toute
## compétence déverrouillée) : la première à consolider, sinon la
## première en apprentissage, sinon une découverte accessible.
static func recommandation(sujet := "mathematiques") -> String:
	var etats := {}
	for c in competences(sujet):
		etats[str(c.id)] = etat(str(c.id))
	return recommander_parmi(etats, sujet)

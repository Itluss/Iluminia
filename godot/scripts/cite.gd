class_name Cite
extends RefCounted
## MA VILLE — la matérialisation du progrès. L'ÉCONOMIE tient en une
## phrase : « LA CONNAISSANCE DÉBLOQUE. LES PIÈCES ACHÈTENT. »
##
##   CONNAISSANCE (XP)  → progression NON dépensable, impossible à
##                        acheter : elle répond à « ai-je le droit
##                        d'avoir cet objet ? » (paliers). Un palier
##                        atteint ne disparaît jamais.
##   PIÈCES (or)        → l'unique monnaie dépensable : elle répond à
##                        « puis-je me le payer ? ».
##
## Découplage impératif : jamais de lien question → bâtiment. La chaîne
## est : apprentissage → XP/maîtrise → palier → catalogue → choix libre.
##
## La ville vit sur une GRILLE INVISIBLE (placement, collisions,
## sauvegarde) : Profil.ville = [{type, x, y, rot}] en cases entières.
## L'or ne suffit JAMAIS pour le contenu majeur : chaque bâtiment exige
## aussi le palier de connaissance (pas de pay-to-win pédagogique).

const TAILLE_GRILLE := 12       ## cases de côté du terrain v1

## RÉCOMPENSES de l'apprentissage (valeurs PROVISOIRES et data-driven :
## l'équilibrage se fera ici, jamais dans la logique). Chaque bonne
## réponse produit une petite récompense RÉELLE ; la session complète
## ajoute un bonus. Une erreur ne retire JAMAIS de pièces. Sources
## futures prévues sans changer le modèle : CITY_PRODUCTION,
## ACHIEVEMENT, EVENT, SOCIAL.
const RECOMPENSES := {
	"question_or": 5,        ## pièces par bonne réponse (QUESTION_REWARD)
	"question_xp": 10,       ## XP de connaissance par bonne réponse
	"bonus_session_or": 15,  ## bonus de session complète (SESSION_REWARD)
}

## Les PALIERS DE CONNAISSANCE : fortement croissants — les premières
## récompenses arrivent vite, le prestige se mérite longtemps.
## (Chiffres provisoires : l'équilibrage viendra plus tard.)
const PALIERS := [
	{"xp": 0, "nom": "Campement", "debloque": []},
	{"xp": 80, "nom": "Hameau", "debloque": ["potager"]},
	{"xp": 220, "nom": "Village", "debloque": ["atelier", "heros:Zep"]},
	{"xp": 450, "nom": "Bourg", "debloque": ["forge", "animal:Braise"]},
	{"xp": 800, "nom": "Cité", "debloque": ["ecurie", "heros:Nova"]},
	{"xp": 1400, "nom": "Citadelle", "debloque": ["murailles", "heros:Ficelle"]},
	{"xp": 2400, "nom": "Cité radieuse", "debloque": ["chateau"]},
	{"xp": 4000, "nom": "Illuminia", "debloque": ["tour_celeste"]},
]

## Catalogue des constructions (v1). Chaque contenu déblocable définit :
## `palier` (unlockKnowledgeLevel — la CONNAISSANCE d'abord) et `or`
## (coinCost). Règle d'achat : palier atteint ET pièces suffisantes.
## PRIX PROGRESSIFS (provisoires) : petit contenu rapide, prestige à
## long terme. `production` = économie passive future — en PIÈCES
## uniquement (monnaie unique), non implémentée dans cette itération.
## `or_amelioration` = coût de base d'une amélioration (× niveau).
const BATIMENTS := {
	"maison": {"titre": "Maison des Aventuriers", "palier": 0, "or": 0, "taille": 3,
		"categorie": "economie", "niveau_max": 5, "or_amelioration": 120,
		"production": {}, "descr": "Ton premier toit — il peut devenir un manoir."},
	"potager": {"titre": "Potager", "palier": 1, "or": 40, "taille": 2,
		"categorie": "economie", "niveau_max": 3, "or_amelioration": 30,
		"production": {"or": 1}, "descr": "Produit quelques pièces."},
	"atelier": {"titre": "Atelier", "palier": 2, "or": 250, "taille": 2,
		"categorie": "economie", "niveau_max": 3, "or_amelioration": 90,
		"production": {"or": 2}, "descr": "Un artisanat qui rapporte."},
	"forge": {"titre": "Forge", "palier": 3, "or": 700, "taille": 2,
		"categorie": "economie", "niveau_max": 4, "or_amelioration": 220,
		"production": {"or": 3}, "descr": "Travaille pierre et métal."},
	"ecurie": {"titre": "Écurie", "palier": 4, "or": 1500, "taille": 3,
		"categorie": "economie", "niveau_max": 3, "or_amelioration": 400,
		"production": {}, "descr": "Accueille tes montures."},
	"murailles": {"titre": "Murailles", "palier": 5, "or": 3000, "taille": 1,
		"categorie": "defense", "niveau_max": 3, "or_amelioration": 800,
		"production": {}, "descr": "Protège ta ville."},
	"chateau": {"titre": "Château", "palier": 6, "or": 12000, "taille": 4,
		"categorie": "prestige", "niveau_max": 5, "or_amelioration": 3000,
		"production": {"or": 5}, "descr": "Le cœur de ta cité."},
	"tour_celeste": {"titre": "Tour céleste", "palier": 7, "or": 30000, "taille": 3,
		"categorie": "prestige", "niveau_max": 3, "or_amelioration": 8000,
		"production": {}, "descr": "La magie d'Illuminia elle-même."},
}

## L'ÉVOLUTION de la Maison des Aventuriers : chaque niveau a un nom —
## « ma petite maison peut devenir ça » (moteur de désir).
const EVOLUTION_MAISON := ["Maison des Aventuriers", "Maison améliorée",
	"Grande maison", "Relais des Aventuriers", "Manoir des Héros"]

## FUTURS DÉBLOCAGES D'ÉCOSYSTÈME (catégorie séparée des bâtiments
## économiques — décorations, nature, eau). ABSENTS du terrain initial
## et du catalogue v1 : « le terrain vide est une promesse, pas un
## manque de contenu ». Chaque élément deviendra une récompense.
const ENVIRONNEMENT := {
	"arbre_simple": {"titre": "Petit arbre", "palier": 2},
	"arbre_fruitier": {"titre": "Arbre fruitier", "palier": 3},
	"parterre_fleurs": {"titre": "Parterre de fleurs", "palier": 2},
	"buisson": {"titre": "Buisson", "palier": 2},
	"chemin_pierre": {"titre": "Chemin de pierre", "palier": 2},
	"lanterne": {"titre": "Lanterne", "palier": 3},
	"banc": {"titre": "Banc", "palier": 3},
	"fontaine": {"titre": "Fontaine", "palier": 4},
	"riviere": {"titre": "Rivière", "palier": 5},
	"etang": {"titre": "Étang", "palier": 5},
	"pont": {"titre": "Pont", "palier": 5},
	"arbre_magique": {"titre": "Arbre magique", "palier": 7},
}


## Palier atteint pour une quantité d'XP de connaissance.
static func palier(xp: int) -> int:
	var p := 0
	for i in PALIERS.size():
		if xp >= int(PALIERS[i].xp):
			p = i
	return p


## Le PROCHAIN déblocage : ce que l'écran d'accueil doit faire désirer
## (« encore N XP pour débloquer la FORGE »). Vide si tout est atteint.
static func prochain_palier(xp: int) -> Dictionary:
	for i in PALIERS.size():
		if xp < int(PALIERS[i].xp):
			return {"indice": i, "xp_manquant": int(PALIERS[i].xp) - xp,
				"nom": str(PALIERS[i].nom), "debloque": PALIERS[i].debloque}
	return {}


## Un bâtiment est constructible si LE PALIER DE CONNAISSANCE est
## atteint ET l'or suffisant — la connaissance ne s'achète pas.
static func constructible(type: String, xp: int, or_joueur: int) -> bool:
	var b: Dictionary = BATIMENTS.get(type, {})
	if b.is_empty():
		return false
	return palier(xp) >= int(b.palier) and or_joueur >= int(b["or"])

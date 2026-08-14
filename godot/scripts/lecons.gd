class_name Lecons
extends RefCounted
## LE CONTENU DES LEÇONS — séparé du moteur (cinematique.gd).
##
## ENGINE ≠ LESSON CONTENT : créer une nouvelle leçon = écrire un
## nouveau scénario ici (acteurs + timeline + narration), sans toucher
## au player. Le storyboard « Comparer des fractions » de la planche est
## LE PREMIER CAS D'UTILISATION du moteur, pas une animation codée en
## dur (aucune logique 3/4 dans le moteur).
##
## Chaque scène répond à la question pédagogique : « qu'est-ce que
## l'enfant comprend grâce à cette animation qu'il comprendrait moins
## bien avec une phrase ? » Aucune animation gratuite.

## La leçon associée à une compétence (et plus tard à une misconception
## précise). Vide si aucune leçon n'existe encore.
static func pour(competence_id: String) -> Dictionary:
	match competence_id:
		"fr_comparer":
			return COMPARER_FRACTIONS
	return {}


## COMPARER DES FRACTIONS — 3/4 est-il plus grand que 2/3 ?
## Objectif : on ne compare pas les dénominateurs directement ; on
## compare la part du tout. Durée ≈ 1 min 15 (propre à CETTE leçon :
## le moteur ne suppose jamais 75 s).
const COMPARER_FRACTIONS := {
	"id": "fractions-comparer-denominateurs",
	"competence_id": "fr_comparer",
	"theme": "fractions",
	"objectif": "Comprendre que l'on ne peut pas comparer les dénominateurs directement. On compare la part du tout.",
	"scenes": [
		# ---------------------------------- 1. DEUX TOUTS IDENTIQUES
		{"id": "touts_identiques", "duree": 5.0,
			"narration": [{"a": 0.4, "texte": "Regarde ces deux gâteaux. Ils sont exactement de la même taille."}],
			"acteurs": [
				{"id": "socleA", "type": "plateforme", "pos": {"x": 32, "y": 60}, "taille": 24},
				{"id": "socleB", "type": "plateforme", "pos": {"x": 68, "y": 60}, "taille": 24},
				{"id": "gateauA", "type": "cercle", "pos": {"x": 32, "y": 44}, "taille": 19,
					"props": {"parts": 1, "teinte": "primaire"}},
				{"id": "gateauB", "type": "cercle", "pos": {"x": 68, "y": 44}, "taille": 19,
					"props": {"parts": 1, "teinte": "secondaire"}},
			],
			"actions": [
				{"a": 0.0, "acteur": "socleA", "type": "apparaitre"},
				{"a": 0.2, "acteur": "socleB", "type": "apparaitre"},
				{"a": 0.5, "acteur": "gateauA", "type": "apparaitre", "duree": 0.7},
				{"a": 1.0, "acteur": "gateauB", "type": "apparaitre", "duree": 0.7},
			]},
		# ---------------------------------- 2. ON LES PARTAGE DIFFÉREMMENT
		{"id": "partage", "duree": 8.0,
			"narration": [
				{"a": 0.3, "texte": "Celui-ci est partagé en quatre parts égales."},
				{"a": 4.0, "texte": "Celui-là est partagé en trois parts égales."}],
			"acteurs": [
				{"id": "labelA", "type": "etiquette", "pos": {"x": 32, "y": 74}, "taille": 5,
					"props": {"texte": "en 4 parts égales"}},
				{"id": "labelB", "type": "etiquette", "pos": {"x": 68, "y": 74}, "taille": 5,
					"props": {"texte": "en 3 parts égales"}},
			],
			"actions": [
				{"a": 0.5, "acteur": "gateauA", "type": "decouper", "valeur": 4, "duree": 1.8},
				{"a": 2.2, "acteur": "labelA", "type": "apparaitre"},
				{"a": 4.2, "acteur": "gateauB", "type": "decouper", "valeur": 3, "duree": 1.8},
				{"a": 5.9, "acteur": "labelB", "type": "apparaitre"},
			]},
		# ---------------------------------- 3. CHAQUE PART N'A PAS LA MÊME TAILLE
		{"id": "taille_parts", "duree": 9.0,
			"narration": [{"a": 1.2, "texte": "Quand on partage le même tout en davantage de parts, chaque part devient plus petite."}],
			"acteurs": [],
			"actions": [
				{"a": 0.2, "acteur": "labelA", "type": "disparaitre"},
				{"a": 0.2, "acteur": "labelB", "type": "disparaitre"},
				{"a": 0.8, "acteur": "gateauA", "type": "detacher", "duree": 1.1},
				{"a": 1.8, "acteur": "gateauB", "type": "detacher", "duree": 1.1},
				{"a": 3.2, "acteur": "gateauA", "type": "surligner"},
				{"a": 3.2, "acteur": "gateauB", "type": "surligner"},
				{"a": 6.8, "acteur": "gateauA", "type": "eteindre"},
				{"a": 6.8, "acteur": "gateauB", "type": "eteindre"},
			]},
		# ---------------------------------- 4. REGARDONS CES QUANTITÉS
		{"id": "construire", "duree": 9.0,
			"narration": [
				{"a": 1.0, "texte": "Ici, on prend trois parts sur quatre."},
				{"a": 4.8, "texte": "Ici, on prend deux parts sur trois."}],
			"acteurs": [
				{"id": "fracA", "type": "fraction", "pos": {"x": 32, "y": 73}, "taille": 7,
					"props": {"num": 3, "den": 4, "teinte": "primaire"}},
				{"id": "fracB", "type": "fraction", "pos": {"x": 68, "y": 73}, "taille": 7,
					"props": {"num": 2, "den": 3, "teinte": "secondaire"}},
			],
			"actions": [
				{"a": 0.2, "acteur": "gateauA", "type": "detacher", "valeur": 0.0},
				{"a": 0.2, "acteur": "gateauB", "type": "detacher", "valeur": 0.0},
				{"a": 1.0, "acteur": "gateauA", "type": "colorier", "valeur": 3, "duree": 2.0},
				{"a": 1.8, "acteur": "fracA", "type": "apparaitre"},
				{"a": 4.8, "acteur": "gateauB", "type": "colorier", "valeur": 2, "duree": 1.7},
				{"a": 5.6, "acteur": "fracB", "type": "apparaitre"},
			]},
		# ---------------------------------- 5. METTONS-LES CÔTE À CÔTE
		{"id": "cote_a_cote", "duree": 6.0, "camera": {"zoom": 1.1},
			"narration": [{"a": 0.5, "texte": "Comparons maintenant ces deux quantités."}],
			"acteurs": [],
			"actions": [
				{"a": 0.3, "acteur": "gateauA", "type": "deplacer", "valeur": {"x": 40, "y": 44}, "duree": 1.0},
				{"a": 0.3, "acteur": "socleA", "type": "deplacer", "valeur": {"x": 40, "y": 60}, "duree": 1.0},
				{"a": 0.3, "acteur": "fracA", "type": "deplacer", "valeur": {"x": 40, "y": 73}, "duree": 1.0},
				{"a": 0.3, "acteur": "gateauB", "type": "deplacer", "valeur": {"x": 60, "y": 44}, "duree": 1.0},
				{"a": 0.3, "acteur": "socleB", "type": "deplacer", "valeur": {"x": 60, "y": 60}, "duree": 1.0},
				{"a": 0.3, "acteur": "fracB", "type": "deplacer", "valeur": {"x": 60, "y": 73}, "duree": 1.0},
			]},
		# ---------------------------------- 6. SUR UNE MÊME LONGUEUR
		{"id": "meme_longueur", "duree": 11.0,
			"narration": [{"a": 2.2, "texte": "Sur une même longueur, on voit que 3/4 occupe plus de place que 2/3."}],
			"acteurs": [
				{"id": "puceA", "type": "fraction", "pos": {"x": 14, "y": 30}, "taille": 7,
					"props": {"num": 3, "den": 4, "teinte": "primaire"}},
				{"id": "puceB", "type": "fraction", "pos": {"x": 14, "y": 66}, "taille": 7,
					"props": {"num": 2, "den": 3, "teinte": "secondaire"}},
				{"id": "ligneA", "type": "droite", "pos": {"x": 57, "y": 30}, "taille": 6,
					"props": {"largeur": 62, "valeur": 0.75, "teinte": "primaire"}},
				{"id": "ligneB", "type": "droite", "pos": {"x": 57, "y": 66}, "taille": 6,
					"props": {"largeur": 62, "valeur": 0.6667, "teinte": "secondaire"}},
				{"id": "trait", "type": "repere", "pos": {"x": 72.5, "y": 48}, "taille": 6,
					"props": {"hauteur": 52}},
			],
			"actions": [
				{"a": 0.2, "acteur": "gateauA", "type": "disparaitre", "duree": 0.6},
				{"a": 0.2, "acteur": "gateauB", "type": "disparaitre", "duree": 0.6},
				{"a": 0.2, "acteur": "socleA", "type": "disparaitre", "duree": 0.6},
				{"a": 0.2, "acteur": "socleB", "type": "disparaitre", "duree": 0.6},
				{"a": 0.2, "acteur": "fracA", "type": "disparaitre", "duree": 0.6},
				{"a": 0.2, "acteur": "fracB", "type": "disparaitre", "duree": 0.6},
				{"a": 0.9, "acteur": "puceA", "type": "apparaitre"},
				{"a": 1.1, "acteur": "ligneA", "type": "apparaitre"},
				{"a": 1.3, "acteur": "ligneA", "type": "tracer", "duree": 1.8},
				{"a": 3.4, "acteur": "puceB", "type": "apparaitre"},
				{"a": 3.6, "acteur": "ligneB", "type": "apparaitre"},
				{"a": 3.8, "acteur": "ligneB", "type": "tracer", "duree": 1.8},
				{"a": 6.4, "acteur": "trait", "type": "apparaitre"},
				{"a": 6.6, "acteur": "trait", "type": "impulsion"},
			]},
		# ---------------------------------- 7. ON NE PEUT PAS REGARDER SEULEMENT LES NOMBRES
		{"id": "corriger", "duree": 12.0,
			"narration": [
				{"a": 0.6, "texte": "On ne peut pas décider en regardant seulement 4 et 3."},
				{"a": 6.2, "texte": "Il faut comparer la part du tout représentée par chaque fraction."}],
			"acteurs": [
				{"id": "grandA", "type": "fraction", "pos": {"x": 34, "y": 40}, "taille": 12,
					"props": {"num": 3, "den": 4, "teinte": "primaire"}},
				{"id": "grandB", "type": "fraction", "pos": {"x": 66, "y": 40}, "taille": 12,
					"props": {"num": 2, "den": 3, "teinte": "secondaire"}},
				{"id": "pasegal", "type": "symbole", "pos": {"x": 50, "y": 38}, "taille": 9,
					"props": {"texte": "≠", "teinte": "important"}},
				{"id": "mentor", "type": "hibou", "pos": {"x": 87, "y": 70}, "taille": 13},
			],
			"actions": [
				{"a": 0.2, "acteur": "puceA", "type": "disparaitre"},
				{"a": 0.2, "acteur": "puceB", "type": "disparaitre"},
				{"a": 0.2, "acteur": "ligneA", "type": "disparaitre"},
				{"a": 0.2, "acteur": "ligneB", "type": "disparaitre"},
				{"a": 0.2, "acteur": "trait", "type": "disparaitre"},
				{"a": 0.7, "acteur": "grandA", "type": "apparaitre"},
				{"a": 0.9, "acteur": "grandB", "type": "apparaitre"},
				{"a": 1.6, "acteur": "grandA", "type": "surligner", "duree": 0.6},
				{"a": 1.8, "acteur": "grandB", "type": "surligner", "duree": 0.6},
				{"a": 2.6, "acteur": "pasegal", "type": "apparaitre"},
				{"a": 2.9, "acteur": "pasegal", "type": "impulsion"},
				{"a": 6.2, "acteur": "grandA", "type": "eteindre"},
				{"a": 6.2, "acteur": "grandB", "type": "eteindre"},
				{"a": 6.6, "acteur": "mentor", "type": "apparaitre"},
			]},
		# ---------------------------------- 8. CONCLUSION
		{"id": "conclusion", "duree": 9.0,
			"narration": [{"a": 1.4, "texte": "Donc, 3/4 est plus grand que 2/3."}],
			"acteurs": [
				{"id": "plusgrand", "type": "symbole", "pos": {"x": 50, "y": 36}, "taille": 11,
					"props": {"texte": ">", "teinte": "important"}},
				{"id": "verdict", "type": "etiquette", "pos": {"x": 50, "y": 68}, "taille": 7,
					"props": {"texte": "3/4 est plus grand que 2/3.", "style": "or"}},
			],
			"actions": [
				{"a": 0.2, "acteur": "pasegal", "type": "disparaitre"},
				{"a": 0.2, "acteur": "mentor", "type": "disparaitre"},
				{"a": 0.4, "acteur": "grandA", "type": "deplacer", "valeur": {"x": 37, "y": 36}, "duree": 0.8},
				{"a": 0.4, "acteur": "grandB", "type": "deplacer", "valeur": {"x": 63, "y": 36}, "duree": 0.8},
				{"a": 1.1, "acteur": "plusgrand", "type": "apparaitre"},
				{"a": 1.4, "acteur": "plusgrand", "type": "impulsion"},
				{"a": 2.2, "acteur": "verdict", "type": "apparaitre"},
			]},
		# ---------------------------------- 9. À TOI DE JOUER !
		{"id": "a_toi", "duree": 6.0, "attente": true, "bouton_fin": true,
			"narration": [{"a": 0.8, "texte": "C'est à toi de jouer !"}],
			"acteurs": [
				{"id": "compagnon", "type": "hibou", "pos": {"x": 26, "y": 52}, "taille": 17},
				{"id": "invite", "type": "bulle", "pos": {"x": 60, "y": 38}, "taille": 4,
					"props": {"lignes": ["À toi maintenant !",
						"Compare ces fractions", "et choisis la bonne réponse."]}},
			],
			"actions": [
				{"a": 0.2, "acteur": "grandA", "type": "disparaitre"},
				{"a": 0.2, "acteur": "grandB", "type": "disparaitre"},
				{"a": 0.2, "acteur": "plusgrand", "type": "disparaitre"},
				{"a": 0.2, "acteur": "verdict", "type": "disparaitre"},
				{"a": 0.5, "acteur": "compagnon", "type": "apparaitre"},
				{"a": 1.0, "acteur": "invite", "type": "apparaitre"},
			]},
	],
}

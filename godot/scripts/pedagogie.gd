class_name Pedagogie
extends Node
## SQUELETTE PÉDAGOGIQUE ELUMINIA — NON ACTIVÉ DANS CETTE RÉGION (v1).
##
## Cœur du projet Eluminia : la progression du jeu est alimentée par la
## scolarité réelle (photos de cours → IA → compétences → missions).
## Cette région Godot « Terres d'Émeraude » est pour l'instant un pur
## action-RPG ; ce fichier balise où brancher la boucle pédagogique,
## en cohérence avec docs/programme-cm1-quetes.md du dépôt.
##
## BRANCHEMENT PRÉVU :
## 1. Un service externe (déjà prototypé côté Three.js) transforme les photos
##    de cours en une liste de compétences travaillées, ex. :
##      {"competence": "fractions_comparaison", "niveau": 2}
## 2. Ce nœud récupère ces compétences (HTTPRequest vers l'API familiale)
##    et génère des MISSIONS en jeu : un PNJ du sanctuaire central propose
##    un défi (« Compare 3/4 et 2/3 pour débloquer le pont de la Forêt »).
## 3. Récompenses : XP, orbes de lumière bonus, objets — en réutilisant
##    joueur.gagner_xp() / monde._lacher_objet(), rien d'autre à créer.
##
## Structure de mission suggérée :
##   {"id": "m1", "competence": "fractions_comparaison",
##    "enonce": "...", "reponses": [...], "bonne_reponse": 2,
##    "recompense_xp": 60, "recompense_objet_rarete_min": 1}

func charger_missions(_url_api: String) -> void:
	push_warning("Boucle pédagogique non activée dans cette région (v1).")

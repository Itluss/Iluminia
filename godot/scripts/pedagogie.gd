class_name Pedagogie
extends Node
## SQUELETTE PÉDAGOGIQUE ELUMINIA — le cœur du projet : la progression du
## jeu est alimentée par la scolarité réelle (photos de cours → IA →
## compétences → missions).
##
## Dans cette arène Godot, les questions viennent de questions.gd (générateur
## maths CM1 aligné sur docs/programme-cm1-quetes.md). C'est le SEUL point à
## remplacer pour brancher la boucle pédagogique réelle :
##
## 1. Un service externe transforme les photos de cours en compétences
##    travaillées, ex. {"competence": "fractions_comparaison", "niveau": 2}.
## 2. Ce nœud les récupère (HTTPRequest vers l'API familiale) et fournit à
##    l'arène des questions ciblées AU MÊME FORMAT que Questions.generer() :
##      {"enonce": String, "reponses": [4 × String], "bonne": int}
##    → remplacer l'appel `Questions.generer()` dans arene.gd par une file
##    de questions alimentée ici, rien d'autre à changer.
## 3. Le suivi des progrès (bonnes/mauvaises réponses par compétence) peut
##    être renvoyé à l'API depuis arene._tenter_zone() pour le diagnostic
##    parent — brancher un signal ici le moment venu.

func charger_missions(_url_api: String) -> void:
	push_warning("Boucle pédagogique non branchée : questions.gd génère en local (v1).")

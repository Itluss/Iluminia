# Dossier `assets/`

Ce dossier est prévu pour accueillir les **vrais sprites** (PNG) de la v2.

En v1, tous les visuels sont dessinés **par code** (formes vectorielles, gros
contours cartoon) dans `scripts/visuel.gd`. Chaque entité (joueur, ennemis)
possède déjà un nœud `Sprite2D` vide, frère du visuel vectoriel :

1. Déposez vos images ici (ex. `assets/joueur.png`).
2. Dans le script de l'entité (ou via l'éditeur), assignez la texture au
   `Sprite2D` et masquez le dessin par code :

```gdscript
$Sprite2D.texture = preload("res://assets/joueur.png")
visuel.visible = false
```

Voir la section « Remplacer les visuels » du README principal.

# Critères de qualité visuelle — Eluminia

## Les 30 points de contrôle (Phase G)

1. netteté du décor · 2. netteté des personnages · 3. cohérence
personnages/décor · 4. proportions · 5. ancrage au sol · 6. ombres de contact ·
7. profondeur · 8. placement des PNJ · 9. HUD · 10. dialogue · 11. boutons ·
12. icônes · 13. effets · 14. particules · 15. cadrage · 16. caméra · 17. zones
vides · 18. chevauchements · 19. éléments coupés · 20. artefacts de détourage ·
21. fonds blancs (ou noirs) résiduels · 22. collisions de debug visibles ·
23. flou global · 24. pixelisation · 25. étirement · 26. lisibilité du texte ·
27. cohérence des marges · 28. surcharge visuelle · 29. performance probable ·
30. conformité à la demande utilisateur.

## Défauts BLOQUANTS (déclenchent un cycle de correction, max 3)

- fond flou ; personnage pixelisé ; image étirée ; asset mal détouré
  (liseré, bloc de fond, texte de planche incrusté visible) ;
- UI hors écran ; dialogue illisible ;
- collision cassée ; personnage inaccessible ;
- effet visuel masquant le gameplay ;
- fond blanc ou noir résiduel visible ;
- mise à l'échelle destructrice (upscale fort d'un petit PNG) ;
- régression de gameplay ; erreur de build ; erreur console importante.

## Calibrage de l'UI (règle ajoutée après comparaison Guild Wars 2)

- AUCUN élément de HUD ne doit dépasser ~6 % de la hauteur d'écran (panneau
  XP, icônes) ; les polices de HUD restent ≤ 14 px logiques.
- Résolution logique : hauteur 900 (PC) — une UI dessinée pour 540 devient
  géante en plein écran : BLOQUANT.
- Tout badge/icône vit ENTIÈREMENT dans son panneau (marge ≥ 6 px) : un
  débordement d'écran ou de panneau est BLOQUANT.
- La coquille de jeu attendue : barre XP compacte (haut-gauche), suivi de
  quête (haut-droit), mini-carte (bas-droit), inventaire près de la mini-carte.
- Vérification : comparer mentalement la capture à un jeu commercial (GW2,
  Prodigy) — si un élément d'UI attire l'œil avant le monde, il est trop gros.

## Fidélité des couleurs (règle ajoutée après l'incident « tout est terne »)

- INTERDIT : tout voile plein écran (vignette MULTIPLY, overlay SCREEN,
  teinte globale). Ces couches délavent et jaunissent le décor entier.
- Le décor affiché doit garder les couleurs du fichier source : en cas de
  doute, comparer la capture à l'asset d'origine (Read des deux).
- Les effets lumineux sont PONCTUELS et LOCALISÉS (halo d'une lanterne, rai
  près de la fontaine), jamais étalés sur la scène.
- BLOQUANT : une capture globalement plus terne/jaune que l'asset source.

## Animations de personnages (règle ajoutée après les bugs du cycle de marche)

Toute itération qui touche aux animations DOIT être validée sur DEUX bancs,
jamais sur une capture statique seule :

1. `node scripts/dump-frames.mjs` → `art/reviews/frames/` : les textures de
   frames EXACTEMENT telles que le moteur les a fabriquées au boot.
   - BLOQUANT : une frame dont la hauteur s'écarte de plus de 10 % de la
     médiane de sa planche (personnage qui « pulse » ou rétrécit en jeu) ;
   - BLOQUANT : fond résiduel visible (rectangle gris/blanc autour du
     personnage) ; fragment d'une cellule voisine ; membre coupé.
2. `node scripts/capture-walk.mjs` → `art/reviews/walk/` : rafales en jeu
   dans les 4 directions + transition gauche→haut (le cas piège du miroir).
   - BLOQUANT : sprite aminci/écrasé pendant un changement de direction
     (interpolation du retournement passant par zéro) ; taille du héros
     différente d'une direction à l'autre ; frame de fond blanc.
3. L'ordre des poses doit lire comme un cycle de marche (contact → amorti →
   croisement → contact opposé) : un pas « mécanique » ou saccadé se corrige
   par réordonnancement (WALK_ORDER dans Player.ts) ou régénération.
4. Échelle : les frames d'une même planche partagent un facteur COMMUN
   (normalisation par la médiane dans addAnimSet) — jamais de normalisation
   par frame.

## Repères propres au projet

- Résolution logique 960×540, Scale.FIT, CENTER_BOTH — le canvas ne doit pas
  être redimensionné par du CSS supplémentaire.
- Décor : illustration peinte → filtrage linéaire (pixelArt désactivé).
- Le décor du village est affiché ×1,7 (source 675×412 → monde 1148×700) :
  c'est la limite d'agrandissement acceptée, ne pas aller au-delà.
- Personnages ~96 px (héros) : hauteur d'une porte du décor.
- Caméra : zoom 1.08, lerp 0.09, anticipation ±46 px — le héros n'est jamais
  exactement centré ; il se tient au tiers inférieur (followOffset y=90).
- Profondeur : depth = y (pieds) ; occlusions par découpes du décor
  (fontaine, bannières).
- HUD : ardoise sombre translucide + liseré or, jamais envahissant.

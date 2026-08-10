# Fiche d'itération — le dragon libre s'enfuit

Idée Camille (2026-08-10) : « ce qui serait très cool c'est que le
dragon essaye de nous échapper à chaque fois que personne ne le
possède. »

## Changements (public/spike3d-arena.html)

1. Dans la boucle `AVAILABLE` : le dragon repère le chasseur le plus
   proche (< 5,5 u) et fuit à l'opposé — trottinement 2,0 u/s, PANIQUE
   2,6 u/s sous 2,6 u (bonds rapides + bouffées de poussière dorée).
   Toujours rattrapable : bots 3,2 u/s, joueur 4,4 u/s.
2. Anti-coin : près des murs, un biais courbe sa fuite vers le centre
   (il longe les bords au lieu de s'y coincer). `clampToArena` en
   garde-fou.
3. Il REGARDE dans la direction de sa fuite (fini la toupie quand il
   est chassé ; la rotation lente reste quand personne n'est proche).
4. Valeurs centralisées dans `LUMIN_CONFIG` : `fleeSpeed`,
   `fleeCalmSpeed`, `fleeDetectRadius`, `fleePanicRadius`.

## Vérifié (probes Playwright, 0 erreur console)

- Joueur téléporté à 3 u du dragon libre → la distance AUGMENTE
  (3,2 → 4,0 u en 1,5 s headless, plus vif en conditions réelles).
- Le dragon reste dans l'arène pendant la fuite.
- La capture au contact marche toujours (téléport sur lui → capturé).
- Capture visuelle : dragon en fuite dos au joueur.

## Note d'équilibrage

La fuite rallonge un peu la chasse (bots : ~0,6 u/s de vitesse de
rattrapage en panique). Si les manches traînent, baisser `fleeSpeed`
à 2,3-2,4 suffit.

# Fiche d'itération — obstacles infranchissables dans l'arène

Demande Camille (2026-08-11) : « des petits obstacles infranchissables,
des choses qui nous fassent faire des détours ».

## Changements (public/spike3d-arena.html)

1. `ARENA_OBSTACLES` : 8 obstacles circulaires (x, z, rayon, type) —
   4 formations de cristaux, 2 piliers en ruine, 2 amas de rochers —
   placés à mi-terrain en diagonales symétriques, jamais sur les zones
   de réponse ni les points d'apparition (marge mini vérifiée : 2,3 u).
2. `resolveObstacles(pos, marge)` : collision par cercle — on repousse
   hors du cercle, ce qui fait GLISSER le long du bord : le détour se
   dessine tout seul, pour le joueur COMME pour les bots (aucun
   pathfinding nécessaire). Appliquée en fin de frame à toutes les
   entités (marche, dash, poussées), au dragon en fuite, et au spawn du
   dragon (jamais DANS un obstacle).
3. `buildArenaObstacles()` : visuels bâtis avec le kit toon existant
   (cristaux du kit + socles rocheux, colonnes beiges brisées, rochers
   sombres) + disque d'occlusion au sol + ombres portées.

## Réglages

Tout dans `ARENA_OBSTACLES` (cherche ce mot) : position, rayon, type.
Ajouter/retirer un obstacle = une ligne.

## Vérifié (probes Playwright, 0 erreur console)

- Téléporté AU CENTRE d'un obstacle → repoussé à 2,9 u (rayon 2,4 +
  marge 0,5) dès la frame suivante.
- Clairance obstacles ↔ tous les pools de points (spawns joueurs,
  spawns dragon, zones de réponse) : minimum 2,31 u — rien de bloqué.
- Captures : formation de cristaux, amas de rochers, pilier.

## À surveiller après test Camille

- Le pilier vu du dessus (caméra iso) lit comme un gros galet beige —
  si peu lisible, le remplacer par un type cristal/rocher.
- Densité : 8 obstacles pour 68×46 u — en ajouter si les détours ne se
  sentent pas assez.

# Critères de qualité visuelle — Eluminia (spike 3D)

## Points de contrôle (Phase G)

1. netteté du toon shading (pas de flou/aliasing excessif) · 2. cohérence des
contours peints (épaisseur régulière, couleur `0x3d2f52`) · 3. cohérence
palette bonbon entre objets · 4. proportions des objets/personnages entre eux
· 5. ancrage au sol (pas d'objet flottant non voulu) · 6. ombres portées
cohérentes avec le soleil · 7. lisibilité de la scène à l'angle iso par
défaut · 8. placement des PNJ (accessibles, pas dans un obstacle) · 9. HUD
DOM (position, proportion, lisibilité) · 10. dialogue (lisible, ne déborde
pas) · 11. boutons/slots d'action · 12. icônes/badges · 13. effets (halos,
particules) localisés · 14. performance probable (nombre de draw calls,
`InstancedMesh` pour les objets répétés) · 15. cadrage caméra (rien de
significatif coupé au bord de l'écran) · 16. caméra (angle iso conservé) ·
17. zones vides ou surchargées · 18. chevauchements d'objets 3D · 19.
éléments 3D ou DOM partiellement hors cadre · 20. artefacts de shader
(courbure, tessellation visible) · 21. couleurs délavées vs la scène de
référence connue · 22. collisions de debug visibles · 23. flou global · 24.
scintillement/z-fighting · 25. étirement d'une géométrie (scale non uniforme
non voulu) · 26. lisibilité du texte HUD · 27. cohérence des marges HUD · 28.
surcharge visuelle · 29. performance probable · 30. conformité à la demande
utilisateur.

## Défauts BLOQUANTS (déclenchent un cycle de correction, max 1)

- UI (DOM) hors écran ou tronquée ; dialogue illisible ;
- élément 3D significatif (PNJ, panneau, portail) partiellement hors cadre à
  l'angle de caméra par défaut ;
- collision cassée ; PNJ ou objectif de quête inaccessible ;
- effet visuel masquant le gameplay ;
- angle/type de caméra modifié sans demande explicite ;
- mise à l'échelle destructrice (scale non uniforme non voulu, géométrie
  étirée) ;
- régression de gameplay (déplacement, dialogue, pont, portail, HUD) ;
- erreur console au chargement.

Un défaut hors périmètre de la demande initiale (préexistant, sans lien avec
la fonctionnalité touchée) reste signalé même s'il est bloquant, mais n'est
PAS corrigé automatiquement — cf. Phase H de `SKILL.md`.

## Calibrage du HUD (DOM, règle héritée du calibrage GW2)

- AUCUN élément de HUD ne doit dépasser ~6 % de la hauteur d'écran (mesuré
  sur une capture 1600×900 → seuil ≈ 54 px) ; police ≤ 14 px logiques.
- Tout badge/icône vit ENTIÈREMENT dans son panneau (marge ≥ 6 px) : un
  débordement d'écran ou de panneau est BLOQUANT.
- Vérification : comparer mentalement la capture à un jeu commercial (GW2,
  Prodigy) — si un élément d'UI attire l'œil avant le monde, il est trop gros.

## Fidélité des couleurs

- INTERDIT : tout voile plein écran (vignette MULTIPLY, overlay SCREEN,
  teinte globale). Ces couches délavent et jaunissent la scène entière.
- Les effets lumineux sont PONCTUELS et LOCALISÉS (halo d'une lanterne,
  particules d'un portail), jamais étalés sur la scène.
- BLOQUANT : une capture globalement plus terne/jaune qu'attendu du style
  toon/palette bonbon établi.

## Performance — ce qui NE se juge PAS en headless

- **Le FPS affiché dans une capture Playwright est sans rapport avec le FPS
  réel** (rendu logiciel SwiftShader ≈ quelques FPS structurels). Ne jamais
  conclure à un problème ou à une réussite de performance sur cette base —
  seul un retour de Camille en navigateur réel fait foi.
- Ce qui reste vérifiable en headless : le nombre d'objets non instanciés
  ajoutés (repérable en lisant le code — tout ajout de N objets répétés
  similaires doit utiliser `THREE.InstancedMesh`, pas N appels individuels).

## Repères propres au projet

- Caméra orthographique isométrique, style validé explicitement par Camille —
  ne jamais changer l'angle ou le type sans demande explicite, même si une
  référence externe semble suggérer autre chose.
- Décor 100 % procédural : toon shading (`MeshToonMaterial` + gradient map),
  contours peints par inverted-hull (`addOutline`/`addGlowOutline`), palette
  bonbon (voir `asset-rules.md`).
- Courbure « petite planète » : tout matériau de décor doit passer par
  `applyCurvature()` pour rester cohérent avec le sol et la coque de planète
  lors du dézoom (vue système).

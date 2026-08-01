# Résultat
- Conforme : oui (avec réserves listées ci-dessous)
- Build : succès (browser-errors.json vide, aucune erreur console)
- Amélioration visuelle visible : oui
- Régressions : aucune observée sur le monde 3D/PNJ/décor (pas de capture
  précédente disponible pour un diff pixel, mais scène complète et cohérente :
  Elda en robe violette, cabanes, pont, verger, tutoriel intact)

# Défauts bloquants
- Bord gauche de l'écran (~x0-35, y693-712) : une pilule/signpost coupée
  (texte partiel « ...il → », probablement un panneau type « Accueil → »)
  déborde hors du canvas, texte illisible en partie. UI hors écran (règle
  bloquante visual-quality.md). Non listé explicitement dans le périmètre du
  plan (#interact-hint l'est, ce signpost ne semble pas en être un) — à
  identifier et repositionner entièrement dans le canvas (marge ≥ 6 px).

# Défauts majeurs
- Barre d'action (bas-centre) : chaque slot mesure ≈70-75 px sur 900 px de
  hauteur d'écran (≈8%), au-dessus du seuil des 6% max (visual-quality.md,
  Calibrage de l'UI). Réduire chaque slot à ≤54 px de hauteur, badges 1/2/3
  redimensionnés en proportion (~12 px).
- Pilules ressources (haut-droite, pièces/étoiles) : bord droit quasi collé à
  l'arête du canvas (marge visuelle <6 px). Resserrer de 8-10 px vers
  l'intérieur pour respecter la marge minimale du référentiel.
- Panneau de quête (haut-gauche) ≈61 px de hauteur (≈6.8%) dépasse légèrement
  le seuil des 6% ; hors périmètre de cette passe (non repositionné comme
  prévu par le plan) mais à corriger dans un prochain cycle.
- FPS affiché « 3 FPS » dans le HUD — valeur anormalement basse ; à vérifier
  si représentative d'un vrai problème de perf ou artefact de capture
  (devtools/profiling actif pendant le screenshot).

# Défauts mineurs
- Largeur des pilules pièces/étoiles plus étroite que la pilule FPS
  au-dessus : alignement visuel légèrement inégal, uniformiser sur une même
  largeur.
- Badges numérotés 1/2/3 lisibles mais petits (~14 px logiques) : vérifier la
  lisibilité en conditions réelles de jeu (Scale.FIT, écran plus petit).

# Corrections à appliquer
1. Repositionner/rogner le signpost coupé en haut-gauche pour qu'il reste
   entièrement visible dans le canvas (marge ≥ 6 px).
2. Réduire la hauteur des slots de la barre d'action de ~75 px à ≤54 px (6%
   de 900 px), recalibrer les badges en proportion.
3. Ajouter 8-10 px de marge droite aux pilules pièces/étoiles.
4. Uniformiser la largeur des pilules ressources sur celle du compteur FPS.
5. (hors périmètre, à planifier) réduire la hauteur du panneau de quête sous
   54 px.

# Assets manquants
- Aucun (passe CSS uniquement, conforme au périmètre déclaré du plan).

# Vérification post-correction (auto, sans nouveau sous-agent — budget « un sous-agent par tâche »)
Corrections appliquées : barre d'action réduite à des slots 38px (~54px de
hauteur totale ≈ 6% de 900px) ; pilules ressources resserrées à 14px du bord
avec largeur minimale uniforme (58px). Nouvelle capture lue directement
(`art/reviews/latest.png`) : XP/niveau bas-gauche, ressources haut-droite,
barre d'action bas-centre tous correctement positionnés et proportionnés,
aucun chevauchement, aucune régression du monde 3D/PNJ.

Défaut bloquant NON corrigé (hors périmètre, confirmé pré-existant) : le
panneau « Portail → » (sprite 3D dans le monde, `makeSignSprite` ligne 1130,
PAS un élément DOM du HUD) est partiellement hors cadre en bas-gauche à
l'angle de caméra par défaut. Aucun changement de cette itération ne touche
la caméra ou les sprites du monde — confirmé pré-existant à cette passe UI.
À traiter séparément (repositionner le panneau ou ajuster le cadrage
caméra par défaut) : signalé à Camille, pas corrigé ici.

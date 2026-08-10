# Fiche d'itération — questions entières + arc de boutons « arc-en-ciel »

Retour Camille (2026-08-10, 2e passe layout) : « les questions doivent
être visibles dans leur intégralité ainsi que les boutons — pas de
slider. Questions vraiment plus en haut à droite. Boutons plus ramassés
en bas à droite en forme d'arc-en-ciel : je pars vraiment du bas à
droite et j'arrive vraiment sur le latéral droit. »

## Changements (public/spike3d-arena.html, CSS uniquement)

1. **Panneau question tout en haut à droite** : `top: 8px` (le HUD
   Menu/score est à gauche, la place était libre) au lieu de 56 px.
2. **Plus jamais de défilement** : panneau élargi à 240 px (les
   questions longues passent de 3 à 2 lignes) + rangées compactées sur
   écrans ≤ 480 px de haut. Le `max-height` ne reste qu'en garde-fou.
3. **Bug corrigé au passage** : le bloc `@media` compact était placé
   AVANT les règles de base `.qa-row` dans la feuille → écrasé (même
   spécificité, dernière règle gagne). Déplacé après : les styles
   compacts s'appliquent réellement maintenant.
4. **Arc « arc-en-ciel » autour du coin** : ⚡ posé sur le BORD BAS,
   💥 (grande) dans le COIN, 🛡️ remonté sur le BORD DROIT — l'arc part
   du bas et arrive sur le latéral droit, exactement le geste décrit.
   Les boutons ne bougent jamais (règle q-open supprimée à la passe
   précédente).

## Vérifié (probes Playwright, pire cas = question la plus longue de la
banque « En quelle année commence la Révolution française ? », 0 erreur)

- 844×390 : question + 4 réponses ENTIÈRES (scroll 180 = client 180),
  0 chevauchement, 47 px d'écart panneau→🛡️.
- 740×360 : entières aussi, 0 chevauchement, 20 px d'écart.
- 1280×720 : entières, 0 chevauchement, 288 px d'écart.
- Boutons strictement immobiles à l'ouverture/fermeture du panneau
  (vérifié à la passe précédente, positions inchangées ici).

# Fiche d'itération — arc resserré + zéro scroll garanti sur la question

Retour Camille (2026-08-10, 3e passe layout) : « les boutons plus
resserrés en bas à droite et pas de scroll sur les questions !!! »

## Changements (public/spike3d-arena.html)

1. **Boutons nettement plus petits et collés au coin** : 💥 58→80 px
   (avant 68→94), ⚡/🛡️ 44→60 px (avant 52→74), écarts 12→8 px.
   L'arc complet (bord bas → coin → bord droit) tient dans ~110 px de
   haut sur téléphone paysage (~148 px sur desktop).
2. **Zéro scroll possible sur la question** : rangées encore compactées
   sur écrans ≤ 480 px (police 12, médaillons 16 px, marges 3 px) — la
   question LA PLUS LONGUE de la banque + ses 4 réponses gardent
   52-99 px de marge au-dessus des boutons, même sur un écran 700×340.
3. **Indicateur 🐉 tenu à l'écart du coin des boutons** : il se glissait
   derrière le bouton 💥 ; désormais repoussé hors de la boîte des
   boutons par le déplacement le plus court (comme il évitait déjà le
   panneau question).

## Vérifié (probes Playwright, pire cas = « En quelle année commence la
Révolution française ? », 0 erreur console)

- 844×390 : contenu entier, 0 chevauchement, 99 px d'écart, arc 113 px.
- 740×360 : contenu entier, 0 chevauchement, 72 px d'écart.
- 700×340 : contenu entier, 0 chevauchement, 52 px d'écart.
- 1280×720 : contenu entier, 0 chevauchement, 320 px d'écart.
- Boutons strictement immobiles panneau ouvert/fermé (tous viewports).
- Indicateur 🐉 : 0 chevauchement avec les boutons (dragon placé hors
  écran côté coin bas droit).

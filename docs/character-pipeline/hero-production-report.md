# Rapport de production — héros (Étape 2, 2026-07-30)

## Réalisé
- Vue avant canonique (`master_front`) générée depuis la planche ELUMINIA,
  détourée, purgée du magenta fantôme, **approuvée par Camille**, promue
  référence secondaire de toutes les pièces.
- **19 pièces générées** (granularité V1 « puppet cutout » + expressions),
  détourées et rognées automatiquement, versionnées avec prompt/paramètres/
  références/coût par génération.
- 2 pièces défectueuses détectées (revue de planche + contrôle auto) et
  régénérées avec prompts durcis : `eyes_closed` (buste entier au lieu du
  bandeau), `mouth_neutral` (lèvres réalistes hors style).
- Planche de contrôle : `art/characters/hero/qa/contact-sheet.png` ·
  Rapport auto : `qa/validation-report.json` · Coûts : `qa/costs.json`.

## Appels API et coûts
- 1 maître (2K, 0,24 $) + 19 pièces + 2 reprises (1K, 0,134 $) ≈ **3,06 $**.
- Cache anti-doublon actif ; 3 tentatives max/pièce ; budget 3 $/exécution.

## Qualité constatée
- Cohérence identité/style très bonne sur 17/19 pièces du premier coup
  (palette pétrole/or, épaisseur de trait, chevauchements d'articulation).
- Points à surveiller à l'assemblage : ceinture présente sur `torso` ET
  `pelvis` (doublon visuel possible) ; cils de `eyes_closed` un peu marqués ;
  `mouth_open` en anneau (à juger à taille réelle).

## Limites Nano Banana observées
- Les pièces « négatives » (un élément SEUL, sans le reste) exigent des
  prompts très défensifs (« STRICTLY NOTHING ELSE… like a sticker »).
- Légère dérive stylistique possible sur les micro-pièces (bouches) —
  toujours passer par la planche de contrôle avant approbation.

## Prochains travaux (dans l'ordre de la mission)
1. Approbation humaine du lot → `approve` par pièce.
2. Phase 9 : assemblage + rig (`hero.rig.json`, puppet Phaser natif,
   pivots depuis le manifeste) — révèle les vrais réglages de pivots.
3. Phase 14 : Character Lab (ancien vs nouveau, os/pivots, ralenti 0,25×).
4. Phases 10-11 : idle vivant puis walk_down avec ancrage des pieds.
5. V2 : renard, mains interchangeables, mèches, vues dos/profil.

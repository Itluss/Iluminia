# Fiche d'itération — Charte UI sur spike3d-village.html

## Objectif
Camille signale que `public/spike3d-village.html` (spike 3D actif, jeu 2D
gelé) ne respecte pas la charte graphique UI (planche de référence : HUD,
barre XP, barre de compétences, ressources, pop-ups). Aligner les éléments
d'interface du spike sur la palette et le style « planche bois/crème » de la
référence, sans casser le gameplay (marche, PNJ Elda, pont des fractions).

## Périmètre
- Fichier unique : `public/spike3d-village.html` (CSS uniquement, `<style>`
  lignes 6-86). Aucun changement JS/logique, aucune nouvelle image générée
  (style reproductible en CSS pur : dégradés, bordures, coins arrondis).
- Éléments concernés : `#progress-panel` (niveau + barre XP + ressources),
  `#action-bar` (barre d'actions façon barre de compétences), `#quest-box`,
  `#dialogue-box`, `#target`, `#streak`, `#end`, `#pause-overlay`,
  `#interact-hint`. `#hud` (tutoriel) reste sombre (déjà proche du panneau 1
  de la référence).

## Palette de référence (planche 9)
Vert #77B36A / #5CAD5A (XP), orange #FF9A4A, violet #8A77E6, rose #FFACC2,
bleu #6CC9EB, crème #F6E7C6, tan #EAD4A6, brun #684A2F, blanc #FFFFFF.

## Changements visuels
- Panneaux XP/ressources/compétences : fond crème→tan, bordure brune,
  coins arrondis, texte brun (au lieu du dégradé brun uni + texte crème
  actuel qui ne correspond pas à la référence).
- Barre XP : remplissage vert (au lieu du bleu actuel), piste tan.
- Barre d'actions : slots carrés arrondis crème/tan, surbrillance verte au
  survol (état « sélectionnée » de la référence) au lieu du gris actuel.
- Pop-ups (dialogue, target, streak, fin, pause) : repris dans le même
  langage crème/brun pour cohérence, texte brun sur fond clair.

## Hors périmètre
Ajout de slots de compétences supplémentaires, verrouillage/cooldown visuel,
carte, inventaire, journal de quêtes détaillé — non présents dans le spike
actuel, non demandés explicitement. Le plan précédent (non archivé) portait
sur le jeu 2D Phaser (`Hud.ts`) — obsolète depuis le pivot 3D acté ce jour,
remplacé par cette fiche.

## Complément (2e passe, après retour de Camille)
Le 1er jet ne reproduisait que la palette, pas l'ordre/emplacement/proportions
de la planche. Camille a choisi « repositionner l'existant seulement » (pas
de minimap). Livré : XP/niveau déplacé en pilule bas-gauche, ressources en
pile verticale haut-droite sous le FPS, barre d'action réduite à des slots
numérotés 1/2/3 conformes à la règle des 6% de hauteur (visual-quality.md).
Quest-box et popups (dialogue/target/streak/end/pause) volontairement non
repositionnés (hors périmètre choisi). Défaut pré-existant repéré et non
corrigé (hors périmètre CSS) : panneau 3D « Portail → » partiellement hors
cadre à l'angle de caméra par défaut — sprite du monde, pas un élément HUD.

## Risques
- Lisibilité du texte brun sur fond crème en plein soleil (capture) : à
  vérifier en revue.
- Ne pas dépasser 6% de hauteur d'écran par panneau (règle visual-quality.md).

## Critères d'acceptation
- Panneaux visuellement cohérents avec la planche de référence (palette,
  formes arrondies, style bois/crème).
- Zéro régression fonctionnelle (marche, dialogue Elda, pont, pause).
- Aucune nouvelle erreur console.

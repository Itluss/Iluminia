# Fiche d'itération — Seam test (monde en deux images invisibles)

## Objectif utilisateur
Valider une nouvelle technique proposée par Camille : `public/art/generated/image.png`
(1632×963, nouvelle image "monde" principale) est coupée verticalement en son
centre (x=816) en deux moitiés. Le joueur doit pouvoir marcher de la fontaine
(moitié gauche, spawn) jusqu'au château (moitié droite, but) SANS jamais
percevoir qu'il s'agit de deux images/scènes séparées : transition « parfaite »
(pas de flash, pas de saut de caméra, pas de téléportation visible).

Ce n'est PAS une migration du jeu : c'est un prototype isolé (même schéma que
`#lab`/`#tiletest`), jetable si non concluant.

## Portée (confirmée avec Camille)
- Prototype isolé : pas de remplacement de `VillageScene`/`village-world.png`
  en production. Reconstruction complète du monde de jeu (quêtes, colliders
  fins, Lina/Fox) sur cette nouvelle image = HORS PÉRIMÈTRE de cette itération.
- Risque identifié : PAS le raccord artistique (les deux moitiés viennent du
  même fichier source, pixels strictement adjacents des deux côtés de la
  coupe — raccord garanti par construction). Le vrai risque est la MÉCANIQUE
  de transition entre deux scènes Phaser (caméra, position, timing).

## Expérience joueur attendue
Scène de test accessible via `#seamtest`. Spawn près de la fontaine (moitié
gauche). Déplacement clavier standard (`Player` existant, réutilisé tel quel).
En marchant vers la droite jusqu'au bord de la moitié gauche : bascule
invisible vers la moitié droite (château visible), mouvement continu sans
interruption perceptible. Réciproque vers la gauche.

## Scène concernée
Nouvelle scène `SeamTestScene` (`src/game/scenes/SeamTestScene.ts`), ajoutée
à `src/game/config.ts` et accessible via `#seamtest` dans `BootScene.ts`
(même schéma que `#lab`/`#tiletest`). `VillageScene.ts`/`BootScene.ts` (route
`village`) ne sont pas altérées dans leur comportement par défaut.

## Changements fonctionnels
- Une seule classe de scène, paramétrée par `side` ('west'|'east') passé en
  data de scène — pas de duplication de code entre les deux moitiés.
- Bascule déclenchée par proximité du bord DANS la direction du déplacement
  (évite tout aller-retour en boucle à la jointure).
- Pas de fondu (`fadeIn`) ni de tween de zoom d'intro sur cette bascule
  latérale (réservés à l'entrée initiale du jeu) — snap caméra immédiat sur la
  bonne position avant le premier rendu.

## Changements visuels / assets nécessaires
- `public/art/generated/village-west.png` (0,0,816,963) — crop pur.
- `public/art/generated/village-east.png` (816,0,816,963) — crop pur.
- Script : `scripts/art-qa/split-seam-image.mjs` (sharp, aucune génération IA).

## Risques
- Snap caméra imparfait → micro-saut visible au franchissement.
- `collideWorldBounds` empêchant d'atteindre le seuil de bascule avant la
  limite physique du monde.
- Oscillation si le joueur change de direction pile à la jointure (mitigé par
  la vérification de direction avant bascule).

## Critères d'acceptation
- Build TypeScript strict sans erreur.
- Capture initiale (`#seamtest`, spawn fontaine) analysée.
- Vérification PAR CALCUL (pas à l'œil) : diff pixel moyenne entre frames
  consécutives autour du franchissement ne dépasse pas significativement la
  diff pixel moyenne en marche normale — pas de pic = pas de saut/flash.
- Aucune régression sur `VillageScene`/`BootScene` (route `village` intacte).

## Hors périmètre
- Colliders détaillés par bâtiment (zone praticable = rectangle englobant
  pour ce prototype, limite connue à signaler).
- Intégration en jeu réel (remplacement de `village-world.png`, quêtes,
  Lina/Fox) — décision de Camille après validation de la technique.

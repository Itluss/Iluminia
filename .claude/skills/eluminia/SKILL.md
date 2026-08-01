---
name: eluminia
description: Transforme une demande narrative ou fonctionnelle en une itération jouable, testée et visuellement vérifiée du jeu Eluminia.
argument-hint: "<scénario ou amélioration demandée>"
---

# Rôle

Tu es le studio de production autonome d'Eluminia.

L'utilisateur fournit uniquement une expression de besoin. Exemples :

- « Ajoute un village dans lequel le pont s'est effondré. »
- « Rends la fontaine plus vivante. »
- « Le héros rencontre un renard magique. »
- « Ajoute une quête de fractions pour un élève de CM1. »
- « Le rendu est trop flou et les personnages sont pixelisés. »

Tu conduis toute l'itération sans demander à l'utilisateur : des coordonnées, une
architecture technique, des noms de classes, un découpage de tâches, un prompt
destiné à une autre IA, ou une correction manuelle du code.

Lis aussi, dans ce dossier : `visual-quality.md` (critères), `asset-rules.md`
(règles assets et détourage), `acceptance-criteria.md` (acceptation finale).

# Pipeline obligatoire

## Phase A — Comprendre le besoin

Transforme la demande en fiche d'itération : objectif utilisateur, expérience
joueur attendue, scène ou système concerné, changements fonctionnels,
changements visuels, assets nécessaires, risques, critères d'acceptation,
éléments explicitement hors périmètre.

Écris cette fiche dans `art/reviews/current-plan.md`. Ne modifie pas encore le code.

## Phase B — Inspecter l'existant

Avant toute modification, inspecte UNIQUEMENT ce qui est concerné par la
demande (pas d'exploration complète du dépôt, ~10 fichiers lus maximum) parmi :
scènes Phaser (`src/game/scenes/`),
composants UI (`src/game/ui/`), entités (`src/game/entities/`), effets
(`src/game/fx/`), assets disponibles sous `public/art/` (dimensions réelles,
transparence — la plupart ont un FOND OPAQUE détouré à l'exécution, voir
`asset-rules.md`), filtrage, échelles, résolution logique (960×540, Scale.FIT),
caméra, collisions, état global (`src/game/state.ts`), scripts npm, erreurs
présentes.

Réutilise les composants et assets adaptés. Ne duplique pas ce qui existe.

## Phase C — Planifier les assets

Crée ou mets à jour `art/generated/manifest.json` (format documenté dans le
fichier lui-même). Règles :

- chercher d'abord dans `public/art/` ;
- utiliser les assets existants lorsqu'ils suffisent ;
- jamais de formes géométriques visibles comme remplacement final ;
- jamais d'agrandissement excessif d'un petit PNG, jamais d'étirement ;
- ne jamais prétendre qu'un asset a été généré si aucun générateur n'est connecté.

Un générateur est connecté : l'outil MCP `generate_image` du serveur
`eluminia-images` (ou son équivalent CLI `node scripts/generate-image.mjs`).
Il joint automatiquement la bible graphique comme référence de style et écrit
dans `public/art/generated/` — voir `asset-rules.md` pour les règles d'usage.
Après chaque génération : vérifier l'image (Read) avant intégration.
Si `OPENAI_API_KEY` est absente (échec propre de l'outil) : écrire les prompts
détaillés dans `art/generated/image-prompts.md`, utiliser les assets existants
cohérents, signaler les assets bloquants dans le rapport final.

## Phase D — Implémenter

Seulement les changements nécessaires. Contraintes : Phaser 3, TypeScript
strict (`npm run build` inclut tsc), architecture existante respectée, aucune
régression fonctionnelle, aucune dépendance inutile, aucun élément temporaire
visible, aucune collision visible, aucun asset déformé, pas de double
redimensionnement, pas de mise à l'échelle CSS du canvas, filtrage cohérent
(illustrations peintes = linéaire, jamais pixelArt ; ne jamais mélanger),
HUD discret, transitions fluides, personnages ancrés au sol (origin 0.5/1 +
ombre), profondeur cohérente (depth = y), 60 FPS (pools réutilisés).

## Phase E — Construire et lancer

`npm install` si nécessaire, puis `npm run build`. Lance le serveur de
développement (`npm run dev`, port par défaut 5173 — détecte le port réel dans
la sortie de Vite). Conserve le serveur actif le temps de la capture.

## Phase F — Capturer le jeu

`node scripts/capture-game.mjs` (ou `npm run capture`). GAME_URL surchargeable
en variable d'environnement. La capture est écrite dans `art/reviews/latest.png`
et les erreurs console dans `art/reviews/browser-errors.json`.

## Phase G — Revue visuelle

UNE SEULE revue par itération : lance le sous-agent `eluminia-visual-reviewer`
(il lit l'image et écrit `art/reviews/latest-review.md`) et appuie-toi sur son
rapport — ne relis PAS `latest.png` toi-même. Un build qui réussit ne suffit
jamais : la revue visuelle est obligatoire, mais jamais en double.

Seulement si le sous-agent est indisponible : analyse toi-même l'image (outil
Read, une seule lecture) selon les 30 points de `visual-quality.md` et écris la
revue dans `art/reviews/latest-review.md` au format :

```
# Résultat
- Conforme : oui/non
- Build : succès/échec
- Amélioration visuelle visible : oui/non
- Régressions : liste
# Défauts bloquants
# Défauts secondaires
# Corrections à appliquer
# Assets manquants
```

## Phase H — Corriger automatiquement

Si un défaut bloquant est détecté : corrige, reconstruis, recapture, réanalyse.
Maximum 1 cycle complet de correction automatique. S'il reste des défauts
bloquants après ce cycle : les lister dans le rapport final et S'ARRÊTER —
Camille décidera de la suite. Les défauts bloquants sont listés dans
`visual-quality.md`. Ne prétends JAMAIS qu'un problème est corrigé sans
l'avoir vérifié sur une nouvelle capture.

## Phase I — Historique

Après chaque itération : copie `current-plan.md` et `latest-review.md` dans
`art/reviews/history/` préfixés d'un timestamp (`yyyyMMdd-HHmmss-`), conserve
`latest.png`, ne supprime aucune revue ancienne.

## Phase J — Rapport final

Réponds avec uniquement : 1. résumé de l'itération ; 2. fichiers créés ;
3. fichiers modifiés ; 4. assets utilisés ; 5. assets manquants ; 6. résultat
du build ; 7. nombre de cycles de correction ; 8. principaux défauts corrigés ;
9. limites restantes ; 10. chemin de la capture finale.

Aucun commentaire vague (« rendu professionnel ») : uniquement des constats vérifiés.

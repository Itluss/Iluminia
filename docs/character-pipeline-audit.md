# Audit — pipeline de personnages (Phase 1, 2026-07-30)

## Moteur et rendu
- **Phaser 3.87** (WebGL via `Phaser.AUTO`), TypeScript strict, Vite 6.
- Résolution logique : hauteur 900, largeur = ratio fenêtre borné 16:9→21:9,
  `Scale.FIT` + `CENTER_BOTH` (`src/game/config.ts`).
- Décors affichés en natif ×1 (2528×1696) ; monde = pixels du décor.

## Personnage actuel
- Héros : sprite unique `Player` (`src/game/entities/Player.ts`),
  `HERO_HEIGHT = 116` px monde (~123 px écran au zoom 1,06) — dans la cible
  « lisible à 80-120 px » de la mission.
- Animation actuelle : **échange de textures image par image** (pas de
  squelette). Cycles marche : profil 9 frames / face 8 / dos 6, cadence
  90 ms, découpés au boot depuis des planches Banana par `addAnimSet`
  (`src/game/utils/keying.ts`) : détourage flood-fill à fond médian, plus
  grande composante connexe, normalisation par MÉDIANE des hauteurs.
- Effets procéduraux : squash départ/arrêt, respiration idle, perspective
  2,5D (`perspScale`), ombre portée dynamique, retournement miroir profil.
- Aucun rig, aucune pièce séparée, aucune expression faciale.

## Génération d'images
- Deux moteurs via `scripts/lib/image-gen.mjs` : `openai` (gpt-image-1,
  alpha natif) et `banana` (**gemini-3-pro-image / Nano Banana Pro**, 1K/2K
  auto, PAS d'alpha → détourage aval). CLI `scripts/generate-image.mjs`,
  serveur MCP `eluminia-images`.
- Appel Banana : POST `generateContent`, réfs images en `inline_data`
  base64, ratio + taille via `generationConfig.imageConfig`.
- Sortie unique : `public/art/generated/` (plat). Versionnage : AUCUN
  (écrasement possible si même nom) → à corriger dans ce sprint.
- Traçabilité prompts/paramètres : manifest.json partiel, pas de journal
  par génération, pas de cache anti-doublon, pas de suivi de coûts.

## Secrets
- `OPENAI_API_KEY` / `GEMINI_API_KEY` en variables d'environnement
  utilisateur Windows (HKCU) ; lues par `process.env` ; jamais dans le repo.
  En session : `$env:GEMINI_API_KEY = (Get-ItemProperty "HKCU:\Environment").GEMINI_API_KEY`.

## Outils de contrôle existants (réutilisables)
- `scripts/capture-game.mjs`, `scripts/capture-walk.mjs` (rafales 4
  directions + transition), `scripts/dump-frames.mjs` (textures moteur),
  banc `scripts/art-qa/`, agent revieweur `eluminia-visual-reviewer`,
  critères `visual-quality.md` (section Animations ajoutée).

## Contraintes structurantes pour le pipeline
1. **Pas de Spine/DragonBones** (licences) → le rig 2D sera un « puppet »
   Phaser natif : conteneurs hiérarchisés + rotations/tweens pilotés par un
   `hero.rig.json` (aucune coordonnée en dur dans le code).
2. **Traitement d'images côté Node** requis (masters transparents hors
   navigateur) → ajout de `pngjs` (pur JS, sans licence, sans binaire) et
   portage du détourage flood-fill existant.
3. Le jeu charge depuis `public/` → les assets de jeu vivent sous
   `public/art/characters/<id>/`, les artefacts de travail (générations
   brutes, QA, rapports) sous `art/characters/<id>/` (non servis).

## ⚠️ Recommandation d'associé : granularité des pièces (V1)
La mission liste ~60 pièces (mèches séparées, mains ×3, oreilles…). Risque
élevé : à cette granularité, la cohérence inter-pièces de Nano Banana chute
(dérives d'échelle/teinte constatées sur les planches de marche) et le
budget explose (60 pièces × reprises ≈ 100+ appels). **V1 proposée : le
« puppet cutout » professionnel à ~15 pièces** (tête+cheveux en bloc, torse,
cape, bras en 2 segments + main incluse, jambes en 2 segments + botte
incluse) + **calques d'expression** (2 états d'yeux, 3 bouches) par-dessus
la tête. Les mèches séparées, mains interchangeables et le renard passent en
V2 une fois la V1 validée à l'écran. Le manifeste et le schéma acceptent dès
maintenant la liste complète — on ne génère simplement pas tout en V1.

## Décision d'arborescence (adaptation demandée par la mission)
- Assets jeu : `public/art/characters/hero/{references,approved,parts,rig,animations,exports}`
- Travail : `art/characters/hero/{generations,qa}`
- Outillage : `scripts/character-pipeline/` (convention scripts/ existante)
- Docs : `docs/character-pipeline/`

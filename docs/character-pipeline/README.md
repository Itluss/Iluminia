# Pipeline de personnages Eluminia

Production automatisée de personnages 2D animables (pièces séparées + rig
« puppet » Phaser) à partir d'une planche de référence, via Nano Banana Pro.

## Prérequis
- `GEMINI_API_KEY` dans l'environnement (HKCU sous Windows ; en session :
  `$env:GEMINI_API_KEY = (Get-ItemProperty "HKCU:\Environment").GEMINI_API_KEY`).
- Node ≥ 20 (`$env:Path = "C:\Program Files\nodejs;$env:Path"`), `npm install`.

## Structure
```
public/art/characters/<id>/   assets servis au jeu
  character.manifest.json     source de vérité : pièces, pivots, ordre, historique
  references/                 planches de référence (source artistique)
  approved/                   masters validés (dont master_front.png)
  parts/                      pièces approuvées, transparentes (chargées par le jeu)
  rig/                        <id>.rig.json (os, limites, ordre) — Phase 9
  animations/, exports/       Phases 10-15
art/characters/<id>/          artefacts de travail (non servis)
  generations/                brut + .keyed.png + .json (prompt, hash, coût) par génération
  qa/                         validation-report.json, costs.json
scripts/character-pipeline/   CLI, prompts, schémas, détourage Node (pngjs)
```

## Commandes
```
node scripts/character-pipeline/index.mjs status hero
node scripts/character-pipeline/index.mjs dry-run hero              # plan + coût, 0 appel
node scripts/character-pipeline/index.mjs generate hero --part master_front
node scripts/character-pipeline/index.mjs generate hero --all --confirm
node scripts/character-pipeline/index.mjs process hero --generation <gid>
node scripts/character-pipeline/index.mjs validate hero
node scripts/character-pipeline/index.mjs approve hero --part hair_front --generation <gid>
node scripts/character-pipeline/index.mjs init lina                 # nouveau personnage
```

## Règles intégrées
- **Cache** : une génération = hash(prompt+taille) + hash(références) ; un
  doublon n'appelle pas l'API (contourner : `--force`).
- **Versionnage** : chaque appel produit `gen-<date>-<hash>.png` + `.json`
  (prompt, paramètres, références, coût) ; rien n'est écrasé.
- **Coûts** : estimation par taille (1K ≈ 0,13 $, 2K ≈ 0,24 $), journal
  `qa/costs.json`, budget par exécution 3 $ (`--all` refuse au-delà),
  3 tentatives max par pièce sans `--force`.
- **Approbation humaine** : `parts/` et `approved/` ne changent QUE via
  `approve` ; remplacement d'une pièce approuvée = `--force` explicite, l'
  ancienne génération passe `superseded`.
- **Ordre imposé** : la vue avant canonique (`master_front`) doit être
  générée ET approuvée avant les pièces (elle devient référence secondaire).

## Ajouter une pièce / un prompt
Déclarer la pièce dans le manifeste (id, parent, pivots, zIndex) et son
prompt dans `scripts/character-pipeline/prompts/parts.mjs` (`PART_PROMPTS`).

## Granularité V1 (choix documenté dans l'audit)
~15 pièces « puppet cutout » + calques d'expression. Mèches fines, mains
interchangeables, renard, vues dos/profil : V2, après validation V1 à l'écran.

## Limites connues
- Cohérence inter-pièces Nano Banana non garantie : la validation humaine
  (Phase 8) reste le portail obligatoire.
- Rig : puppet Phaser natif (containers + tweens), pas de format Spine.
- Phases 9-15 (rig, idle, marche, Character Lab, atlas) : à construire après
  validation de l'assemblage statique (Étape 2 de la mission).

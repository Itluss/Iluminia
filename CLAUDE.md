# Eluminia

Eluminia est un RPG éducatif 2D destiné aux enfants, construit avec Phaser 3,
TypeScript et Vite.

## État du projet (inspection 2026-07-29)

- Framework : Phaser `^3.87.0`, TypeScript strict (`tsc --noEmit` dans le
  build), Vite 6. Résolution logique 960×540, `Scale.FIT` + `CENTER_BOTH`,
  port de dev : 5173 (défaut Vite, à détecter dans la sortie).
- Entrée : `index.html` → `src/main.ts` → `src/game/config.ts`.
- Scènes : `src/game/scenes/` (BootScene = chargement + détourage runtime,
  VillageScene = monde, caméra, collisions, interactions).
- Entités : `src/game/entities/` (Player, Lina) · UI : `src/game/ui/`
  (Hud, DialogueBox, QuestionPanel, InventoryPanel, widgets) · Effets :
  `src/game/fx/environment.ts` · Utilitaires : `src/game/utils/`
  (keying = détourage flood-fill, textures = découpes et textures de lumière).
- État global : `src/game/state.ts` (xp, niveau, pièces, planches, drapeaux UI).
- Assets : `public/art/` (voir `.claude/skills/eluminia/asset-rules.md` —
  fonds opaques, titres incrustés, noms parfois mélangés : tout est documenté).
- QA assets : `scripts/art-qa/rulers.ps1` et `scripts/art-qa/crops-qa.ps1`
  (contrôle visuel des découpes AVANT intégration — obligatoire).
- Anciens prototypes : pages autonomes dans `public/*.html` (accueil,
  cinematique, aventure, poc-royaume, defi-pont, poc-combat, monde-pixel) et
  `archive/prototype-phaser-v1/`. Ne pas les casser, ne pas les étendre.
- Le dépôt git n'a AUCUN commit : ne rien supprimer sans archiver.

## Priorités

1. Qualité visuelle vérifiée. 2. Cohérence artistique. 3. Simplicité de prise
en main. 4. Fiabilité. 5. Performance. 6. Réutilisabilité des assets.

## Règles absolues

- Ne jamais utiliser de formes temporaires visibles.
- Ne jamais prétendre qu'un asset existe sans le vérifier.
- Ne jamais étirer une image ; ne jamais agrandir fortement un petit PNG.
- Ne jamais mélanger filtrage pixel art et illustration peinte.
- Toute modification visuelle importante doit être contrôlée par une capture
  (`npm run capture`) puis ANALYSÉE — un build réussi ne suffit pas.
- Toute nouvelle découpe d'asset passe par le banc `scripts/art-qa/` avant code.
- Les régressions fonctionnelles sont interdites (déplacement, dialogue,
  question, XP, inventaire).
- Assets : `public/art/` · Revues : `art/reviews/` · Besoins d'images :
  `art/generated/`.
- Utiliser `/eluminia` pour toute nouvelle scène ou itération importante.

## Budget et économie de tokens (règle absolue)

- Optimiser en permanence la consommation : recherches ciblées (Grep), lectures
  partielles, jamais de relecture d'un fichier ou d'une image inchangés.
- Aucun sous-agent lancé automatiquement en dehors de la revue visuelle prévue
  par `/eluminia` ; accord de Camille requis au-delà d'UN sous-agent par tâche ;
  un sous-agent ne lance jamais de sous-agent ; pas d'agents parallèles sans
  justification écrite.
- Ne pas explorer tout le dépôt pour une modification locale ; ignorer
  node_modules, dist, archive/ et les fichiers générés sauf nécessité.
- Une seule capture et une seule revue visuelle par itération ; maximum 1 cycle
  de correction automatique, ensuite s'arrêter et faire un rapport.
- Build ciblé d'abord ; `verify-eluminia` complet uniquement en fin d'itération.
- Réponses et rapports courts : constats, pas de paraphrase.
- Si le périmètre s'élargit, ou avant toute action coûteuse (boucle, génération
  d'images en série, analyse massive) : s'arrêter et demander l'accord.
- Abandonner les hypothèses obsolètes ; en session longue, résumer le contexte
  utile et recommander une NOUVELLE session dès que le contexte devient lourd
  (nombreuses images, itération terminée). Une tâche = une session.
- Modèle : Sonnet par défaut. Opus/Fable uniquement sur demande explicite de
  Camille (`/model`) pour architecture ou bug difficile.

## Commandes

```
npm run dev          # serveur de développement (port affiché par Vite)
npm run build        # tsc strict + build Vite
npm run capture      # capture Playwright -> art/reviews/latest.png
npm run visual-check # contrôles automatiques post-capture
npm run verify-eluminia  # build + capture + visual-check
```

## Génération d'images

Serveur MCP local **eluminia-images** (`.mcp.json` →
`scripts/mcp-image-server.mjs`, moteur OpenAI gpt-image-1) : outil MCP
`generate_image`, ou CLI `node scripts/generate-image.mjs --prompt "..."
--filename x.png [--transparent]`. La bible graphique `public/art/image.png`
est jointe automatiquement comme référence de style ; sortie dans
`public/art/generated/`. Prérequis : `OPENAI_API_KEY` dans l'environnement —
sans clé, retomber sur les prompts manuels (`art/generated/image-prompts.md`,
générés par Camille via son outil externe). Détails :
`.claude/skills/eluminia/asset-rules.md`.

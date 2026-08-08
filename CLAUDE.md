# Eluminia

Eluminia est un jeu vidéo éducatif dont la progression est alimentée par la
scolarité réelle de l'enfant (photos de cours → IA → missions). Cible POC :
CM1–CM2, mathématiques, fractions.

## État du projet (grand ménage 2026-08-01 : pivot 3D définitif)

Le POC 2D (Phaser 3 + TypeScript + Vite, `src/`, `public/art/`, pipelines
d'assets/personnages/cartes, prototypes autonomes) a été **entièrement
supprimé** après le pivot 3D acté le 2026-08-01 (décision de Camille, testée
et validée sur 4 critères : qualité en jeu, animation, 60 FPS réel,
soutenabilité de l'effort). L'état d'avant suppression reste consultable dans
l'historique git (1er commit du dépôt). Ne PAS tenter de le restaurer sans
demande explicite de Camille.

Le jeu est aujourd'hui un **spike 3D procédural** :

- **Zéro build, zéro bundler, zéro TypeScript.** Chaque planète est un seul
  fichier HTML autonome sous `public/`, Three.js `0.160.0` chargé par
  importmap depuis `unpkg` (`<script type="module">` direct dans le fichier).
  `npm run dev` (Vite) sert `public/` en statique — Vite ne fait aucune
  transformation, c'est un simple serveur de fichiers avec live-reload.
- **Le monde 3D est procédural** (décor, personnages, PNJ, portails : géométries
  Three.js + toon shading `MeshToonMaterial` + contours peints inverted-hull,
  palette bonbon Eluminia) — ne PAS introduire de GLB/texture 3D sans décision
  explicite de Camille. **Le HUD DOM, lui, utilise de VRAIES images** (`public/ui/`,
  fournies par Camille depuis sa planche de référence, ex. `interface.png`) :
  panneaux/icônes qui ne sont pas de simples rectangles doivent être incrustés
  tels quels (voir `asset-rules.md`), pas reconstruits en CSS approximatif.
- `index.html` (racine) fait un simple renvoi vers `/spike3d-village.html`.
- `public/spike3d-village.html` — planète de départ : prairie procédurale,
  PNJ Elda (dialogue), village (puits/place/maisons/clôtures), pont des
  fractions (mini-jeu : sauter sur la bonne fraction), portail vers la
  planète voisine, HUD DOM (XP/niveau, ressources, barre d'action, quête).
  Hook de debug : `window.__spikeDebug` (voir le fichier pour l'API exacte).
- `public/spike3d-planet2.html` — 2e planète (palette mauve/cyan, cristaux,
  rochers flottants), son propre portail de retour. Même hook `window.__spikeDebug`.
- **Portails** : vraie navigation de page (`location.href`, PAS un téléport
  de scène) avec `?from=portal` pour faire apparaître le héros à côté du
  portail d'arrivée. Fondu CSS (`#portal-fade`) autour de la navigation.
- **Vue système dézoomée** : pas de caméra séparée — extension continue du
  zoom orthographique existant (`controls.minZoom`) ; au-delà du zoom de jeu
  normal, un facteur `spaceT` fait fondre le ciel vers l'espace étoilé et
  révèle la planète voisine à distance fixe. Courbure "petite planète"
  appliquée à tout le décor via un shader partagé (`applyCurvature`).
- **Caméra** : orthographique isométrique, style validé explicitement par
  Camille (« j'adore le style que tu as posé »). Ne JAMAIS changer l'angle ou
  le type de caméra sans demande explicite, même si une référence externe
  (ex. Guild Wars 2) semble suggérer une 3e personne rapprochée.
- Outils de génération d'images (`scripts/generate-image.mjs`,
  `scripts/lib/image-gen.mjs`, serveur MCP `eluminia-images`) conservés
  comme infra réutilisable mais **actuellement inutilisés** par le jeu
  (100 % procédural) — ne pas les brancher sans besoin réel identifié.

## Priorités

1. Qualité visuelle vérifiée en jeu réel. 2. Cohérence artistique (toon
shading, palette bonbon, contours peints). 3. 60 FPS confirmé par Camille.
4. Simplicité de prise en main. 5. Fiabilité. 6. Performance.

## Règles absolues

- Ne jamais utiliser de formes temporaires visibles (capsule de test, etc.)
  dans une capture livrée à Camille.
- Ne jamais prétendre qu'un changement visuel est correct sans capture
  vérifiée (`npm run capture`) — un build/chargement sans erreur ne suffit
  jamais.
- Ne jamais ajouter de voile plein écran (vignette/teinte globale) : les
  effets lumineux sont ponctuels et localisés.
- **Ne jamais juger le FPS via une capture headless** (Playwright/SwiftShader
  = rendu logiciel, ~3 FPS structurel, sans rapport avec le FPS réel) — le
  FPS ne se valide qu'en navigateur réel, par Camille.
- Les régressions fonctionnelles sont interdites (déplacement, dialogue PNJ,
  saut sur le pont, traversée du portail, HUD).
- Ne jamais changer l'angle/type de caméra sans demande explicite de Camille.
- Utiliser `/eluminia` pour toute nouvelle scène ou itération importante.

## Budget et économie de tokens (règle absolue)

- Optimiser en permanence la consommation : recherches ciblées (Grep), lectures
  partielles, jamais de relecture d'un fichier ou d'une image inchangés.
- Aucun sous-agent lancé automatiquement en dehors de la revue visuelle prévue
  par `/eluminia` ; accord de Camille requis au-delà d'UN sous-agent par tâche ;
  un sous-agent ne lance jamais de sous-agent ; pas d'agents parallèles sans
  justification écrite.
- Ne pas explorer tout le dépôt pour une modification locale ; ignorer
  node_modules et les fichiers générés sauf nécessité.
- Une seule capture et une seule revue visuelle par itération ; maximum 1 cycle
  de correction automatique, ensuite s'arrêter et faire un rapport.
- Réponses et rapports courts : constats, pas de paraphrase.
- Si le périmètre s'élargit, ou avant toute action coûteuse (boucle, génération
  d'images en série, analyse massive, suppression de fichiers) : s'arrêter et
  demander l'accord.
- Abandonner les hypothèses obsolètes ; en session longue, résumer le contexte
  utile et recommander une NOUVELLE session dès que le contexte devient lourd.
  Une tâche = une session.
- Modèle : Sonnet par défaut. Opus/Fable uniquement sur demande explicite de
  Camille (`/model`) pour architecture ou bug difficile.

## Commandes

```
npm run dev      # serveur de développement (port affiché par Vite, 5173 par défaut)
npm run capture  # capture Playwright -> art/reviews/latest.png
                 # GAME_URL surchargeable, ex :
                 # GAME_URL="http://localhost:5173/spike3d-village.html" npm run capture
```

Pas de `build` : rien à compiler, `public/*.html` est servi tel quel.

## Génération d'images

Serveur MCP local **eluminia-images** (`.mcp.json` →
`scripts/mcp-image-server.mjs`, moteur OpenAI gpt-image-1) : outil MCP
`generate_image`, ou CLI `node scripts/generate-image.mjs --prompt "..."
--filename x.png [--transparent]`. Prérequis : `OPENAI_API_KEY` dans
l'environnement. **Actuellement non utilisé** par le jeu (style 100 %
procédural) — ne l'utiliser que sur demande explicite de Camille pour un
besoin identifié (ex. texture, icône UI).

## Génération de modèles 3D (Meshy)

API **Meshy** (`https://api.meshy.ai`, endpoint `openapi/v1/image-to-3d`,
auth `Authorization: Bearer $MESHY_API_KEY`) — clé configurée le
2026-08-07 (`setx MESHY_API_KEY`, même convention que `OPENAI_API_KEY`),
connexion vérifiée par un appel de liste gratuit (HTTP 200). Décision
explicite de Camille du 2026-08-07 : premier avatar joueur en 3D généré
depuis une planche qu'elle doit fournir (image-to-3D). **Aucun script de
génération ni intégration écrits pour l'instant** — en attente de la
planche de référence. Une fois le premier personnage 3D intégré, ce
document devra être mis à jour (la règle "monde 100 % procédural, pas de
GLB sans décision explicite" ligne ci-dessus cessera de s'appliquer à ce
personnage précis).

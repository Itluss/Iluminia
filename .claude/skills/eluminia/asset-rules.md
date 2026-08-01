# Règles assets — Eluminia

## Emplacements

- `public/art/eluminia_poc_assets/` — décor du village, héros, Lina, portrait,
  panneau de dialogue, bouton, icônes (fonds BLANCS opaques).
- `public/art/eluminia_sprint01_environment_fx/` — effets d'environnement :
  strips d'animation, végétation, overlays, UI v2 (fonds NOIRS à vignette,
  titres incrustés par le générateur dans la plupart des planches).
- `public/art/` (racine) — planches de concept (`image.png` = bible graphique
  « Les Gardiens du Savoir », `planche-2.png`) et ancrage historique.
- `public/art/generated/` — destination des futurs assets générés.
- `art/generated/` — manifest et prompts (hors public, non servi).

## Particularités CONNUES des planches existantes

- AUCUN asset n'a de transparence : détourage à l'exécution obligatoire.
- Fonds noirs (sprint FX) : fusion additive (ADD) pour les éléments lumineux ;
  flood-key (tolérance 72) pour les éléments opaques ; UI : tolérance 60.
- Titres incrustés (« FIREFLIES », « INTEGRATION GUIDE »…) : découpes ciblées.
- Noms de fichiers UI du sprint 01 MÉLANGÉS : `quest-icon.png` = sac
  d'inventaire, `xp-icon.png` = icône de quête, blason XP dans
  `button-background.png`, `inventory-icon.png` = étincelles bleues.

## Pipeline de détourage (dans le code)

- `src/game/utils/keying.ts` :
  - `addKeyedTexture(scene, srcKey, outKey, tol)` — image entière ;
  - `addKeyedRegionTexture(scene, srcKey, outKey, x, y, w, h, tol)` — découpe ;
  - flood-fill depuis les bords : les blancs/noirs INTERNES sont préservés.
- `src/game/utils/textures.ts` : `addRegionTexture` (sans détourage, pour ADD),
  textures procédurales autorisées UNIQUEMENT pour lumière/ombre (glow, ombre
  douce, poussières) — jamais pour un objet de jeu visible.

## Contrôle qualité OBLIGATOIRE avant toute nouvelle découpe

Ne JAMAIS intégrer une découpe sans validation visuelle préalable :

1. `powershell scripts/art-qa/rulers.ps1` — génère des versions graduées des
   planches sources (grille 10 px, repères 50 px) pour lire les coordonnées ;
2. `powershell scripts/art-qa/crops-qa.ps1` — applique EXACTEMENT l'algorithme
   crop+flood-key du jeu et produit une planche de contrôle sur damier ;
3. lire la planche de contrôle (outil Read), corriger les coordonnées, itérer ;
4. seulement ensuite, porter les coordonnées validées dans le code.

Adapter la liste `$crops` de `crops-qa.ps1` à chaque nouvelle planche.

## Échelles

- Jamais d'étirement (ratio toujours conservé).
- Icônes : jamais au-delà de leur résolution native.
- Décor : agrandissement max ×1,7 (déjà atteint sur le fond du village).
- Illustrations peintes : filtrage linéaire. Pixel art véritable :
  nearest-neighbor + échelle entière. Ne jamais mélanger les deux régimes.

## Génération d'images

Générateur connecté : serveur MCP local **eluminia-images** (`.mcp.json` →
`scripts/mcp-image-server.mjs`), moteur OpenAI gpt-image-1.

- Outil MCP : `generate_image` (prompt, filename, size, transparent,
  references, use_style_base). Équivalent CLI :
  `node scripts/generate-image.mjs --prompt "..." --filename x.png [--transparent] [--ref chemin] [--no-style-ref]`
- **Base de style automatique** : `public/art/image.png` (bible « Les Gardiens
  du Savoir ») est jointe par défaut comme image de référence — toute
  génération « prend comme base public/art ». Ajouter d'autres références de
  `public/art/` selon le sujet (ex. le décor du village pour un élément de décor).
- Sortie : `public/art/generated/<filename>` (jamais ailleurs).
- Toujours demander `transparent: true` pour personnages et objets de jeu.
- Ne PAS décrire le style dans le prompt (il vient des références) ; décrire le
  CONTENU. Interdits : texte, cadre, filigrane (déjà rappelés par le serveur).
- Prérequis : variable d'environnement `OPENAI_API_KEY` (clé créée par
  Camille). SANS clé, l'outil échoue proprement → retomber sur le mode
  « prompts » : écrire les demandes dans `art/generated/image-prompts.md`,
  marquer `"source": "missing"` dans le manifest, signaler comme bloquant.
- Après CHAQUE génération : vérifier l'image (Read), passer les découpes au
  banc `scripts/art-qa/` si besoin, mettre à jour `manifest.json`
  (`"source": "generated"`).

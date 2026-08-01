# Audit — pipeline d'extension de map par outpainting contrôlé

Date : 2026-07-31. Périmètre : lecture seule, aucune map modifiée.

## 1. Où est stockée la map actuelle

- Fichier affiché en jeu : `public/art/generated/village-world.png`
  (chargé dans `src/game/scenes/BootScene.ts:22` :
  `this.load.image('village', 'art/generated/village-world.png')`).
- Affiché dans `VillageScene.ts:61` : `this.add.image(0, 0, 'village').setOrigin(0)`,
  **résolution native ×1** (aucune mise à l'échelle du décor).
- Source pré-upscale conservée : `public/art/generated/village-world-v1.png`
  — **note** : malgré l'extension `.png`, ce fichier est en réalité un
  **JPEG** (`sharp` renvoie `format: "jpeg"`, chroma 4:2:0). À ne jamais
  réutiliser comme source pixel-parfaite pour un pipeline sans perte : repartir
  de `village-world.png` (vrai PNG, `hasAlpha: false`, RGB 8 bits).

## 2. Résolution réelle et format

| Fichier | Dimensions | Format réel | Alpha |
|---|---|---|---|
| `village-world.png` (ACTIF) | 2544×3792 | PNG (8 bits/canal) | non |
| `village-world-v1.png` (archive) | 1696×2528 | **JPEG** malgré `.png` | non |

`village-world.png` = `village-world-v1.png` mis à l'échelle ×1,5 (sharp,
ratio exact, cf. `art/generated/manifest.json`).

## 3. Mode d'affichage Phaser et échelle

- `src/game/config.ts` : `Phaser.AUTO`, `Scale.FIT` + `CENTER_BOTH`.
- **Résolution logique réelle** : `GAME_HEIGHT = 900` (PC), largeur calculée
  depuis le ratio de fenêtre réel, borné entre 16:9 et 21:9
  (`GAME_WIDTH = round(900 * aspect / 2) * 2`). **Écart avec CLAUDE.md**, qui
  documente encore « résolution logique 960×540 » — information obsolète, à
  corriger dans CLAUDE.md séparément (hors périmètre de cette tâche).
- Le décor est affiché à l'échelle **1:1** (aucun `setScale` sur l'image
  `village`) : 1 pixel du PNG = 1 unité du monde Phaser = 1 pixel logique.
  **Conséquence directe pour le pipeline** : toute mesure faite dans l'éditeur
  d'image (largeur de chemin, de rivière, taille de bâtiment) est directement
  utilisable comme coordonnée de collision dans le code, sans conversion.
- Personnage : `HERO_HEIGHT = 145` (`src/game/entities/Player.ts:6`), dans ce
  même repère 1:1.

## 4. Nano Banana — appel déjà en place

- `scripts/lib/image-gen.mjs`, fonction `callBanana()` (lignes 99-133) :
  appelle `generativelanguage.googleapis.com/v1beta/models/{model}:generateContent`
  avec `responseModalities: ['IMAGE']`, modèle par défaut `gemini-3-pro-image`
  (surchargeable par `GEMINI_IMAGE_MODEL`, ex. `gemini-3.1-flash-image` si la
  facturation Gemini n'est pas activée).
- Entrée multimodale : jusqu'à N images de référence (`inline_data`
  base64) + un prompt texte, dans un seul message `contents[0].parts[]`.
- **Aucun paramètre de masque natif** dans cet appel : c'est de la génération
  conditionnée par image(s) de référence, pas un endpoint d'edit/inpaint avec
  masque binaire. Confirmé par la structure de la requête (pas de champ
  `mask`, pas de `image_config.mask`).
- `size` mappé en `aspectRatio` + `imageSize` (`1K` ou `2K` selon le format
  demandé) — **pas de contrôle pixel-exact de la résolution de sortie**,
  seulement un ratio + un palier de taille. Point de friction direct avec
  l'exigence « ne jamais redimensionner la map source, ne jamais interpoler » :
  la taille de sortie brute de l'API ne collera quasi jamais exactement au
  canevas attendu → un redimensionnement/recadrage post-traitement de la
  zone générée sera nécessaire avant recomposition (voir §9 du plan).

## 5. Scripts de génération existants

- `scripts/generate-image.mjs` — CLI (`--prompt`, `--filename`, `--size`,
  `--transparent`, `--ref`, `--no-style-ref`, `--engine openai|banana`).
- `scripts/mcp-image-server.mjs` — même moteur exposé en outil MCP
  (`generate_image`) pour les sessions interactives.
- `scripts/lib/image-gen.mjs` — cœur partagé (`generateImage()`,
  `callBanana()`, `callApi()` pour gpt-image-1 `/images/edits` et
  `/images/generations`).
- **Aucun de ces scripts ne gère aujourd'hui de canevas étendu ni de masque** :
  ils génèrent toujours une image complète depuis zéro (ou depuis des
  références de style), jamais une extension d'un canevas existant protégé.
  Le pipeline demandé est un besoin entièrement nouveau, pas une extension
  mineure de l'existant.

## 6. Variables d'environnement

- `OPENAI_API_KEY` — moteur `openai` (gpt-image-1), présente dans cet
  environnement.
- `GEMINI_API_KEY` — moteur `banana` (Nano Banana Pro), présente dans cet
  environnement.
- `GEMINI_IMAGE_MODEL` (optionnelle) — surcharge du modèle Banana si la
  facturation Gemini n'est pas activée sur la clé.

## 7. Structure actuelle de `public/art/`

```
public/art/
  image.png, planche-2.png, image1-5.png, reference-eluminia.png   # bible + concept
  eluminia_poc_assets/            # décor POC, héros/Lina v1, UI (fonds blancs)
  eluminia_sprint01_environment_fx/  # FX + UI v2 (fonds noirs à vignette)
  generated/                      # TOUT le contenu généré (décor, héros, UI, tuiles du prototype tileset)
  characters/hero/                # rig modulaire (parts, master, manifest)
```
`generated/` contient déjà ~90 fichiers non organisés par itération (décors
retirés, doublons de test, sorties du pipeline personnage). Le plan demandé
(`art/maps/{source,masters,chunks,masks,previews,qa,history}`) introduit une
convention de nommage séparée, propre à la map — cohérent avec l'existant
sans le perturber (rien à migrer).

## 8. Masque ou outpainting existant : AUCUN, avec un précédent négatif documenté

- `.claude/skills/eluminia/asset-rules.md` et l'historique du dépôt ne
  contiennent aucun pipeline de masque.
- **Précédent testé et documenté comme non concluant** (session précédente,
  voir `art/reviews/next-session-tileset-prototype.md:24-28`) : l'outpainting
  /inpainting avec masque via **l'API OpenAI** (`gpt-image-1`,
  `/v1/images/edits`) a été testé dans les deux conventions
  (transparent=zone à générer / transparent=zone protégée) et **ne préserve
  PAS les pixels sous le masque** — le modèle régénère toute la zone à chaque
  appel, y compris la partie censée être protégée.
- **Conséquence directe pour ce pipeline** : la §9 du plan anticipe
  correctement ce risque (recomposition locale systématique plutôt que
  confiance dans le masque de l'API). C'est la bonne réponse technique — à
  appliquer aussi bien pour Nano Banana que pour gpt-image-1, puisque Nano
  Banana n'a de toute façon **aucun mécanisme de masque natif** (§4) : il n'y
  a donc rien à « faire confiance » côté API, la protection des pixels doit
  être 100 % assurée par la recomposition locale (copier les pixels sources
  originaux par-dessus le résultat, jamais l'inverse).
- **Second précédent pertinent** : deux tentatives antérieures de composer le
  monde à partir de DEUX images générées séparément (`village-hub.png` +
  `bourg-nord.png`, puis leurs versions upscalées) ont été abandonnées pour
  raccord visible malgré même moteur et mesures précises (voir
  `art/generated/manifest.json`, entrées `RETIRÉ`). C'est exactement le
  problème que ce pipeline d'outpainting contrôlé cherche à résoudre en
  gardant TOUJOURS un unique fichier maître étendu progressivement, plutôt que
  deux fichiers recollés.

## 9. Dimensions exactes de la map actuelle

- **2544 × 3792 px**, PNG 8 bits, sans alpha (`village-world.png`).
- Zone praticable actuelle (collision monde, `VillageScene.ts:33`) :
  `x:[150, 2394], y:[150, 3642]` (marge de 150 px sur les 4 bords).
- **Les 4 bords sont actuellement FERMÉS par un mur de collision plein**
  (`VillageScene.ts:312-321`, `THICK = 60`), y compris haut et bas, malgré le
  commentaire de code indiquant ces deux bords comme « réservés » pour un
  futur voisin — l'art continue visuellement vers le haut/bas (chemin non
  refermé visuellement) mais le mur physique bloque déjà le passage. Une
  extension nord/sud n'aura donc PAS besoin de retravailler l'art de sortie
  (déjà « ouvert » visuellement) mais devra retirer/reculer le mur
  correspondant dans `VillageScene.ts` après approbation du nouveau chunk.
- Est/Ouest : fermeture par décor naturel (rivière à l'ouest, moulin/forêt à
  l'est) — extension possible mais demandera de faire percer un passage
  crédible dans un élément qui n'a pas été peint comme une sortie.

## 10. Éléments UI intégrés dans l'image de fond

**Aucun** — vérifié par inspection visuelle directe de `village-world.png`
(aperçu réduit) : bâtiments, chemins, rivière, fontaines, potager, forêt.
Aucun texte, titre, barre, icône ou cadre peint dans l'image. Tout le HUD
(XP, quêtes, inventaire, carte) est composé séparément par Phaser
(`src/game/ui/`) sur une caméra UI dédiée (`setupUiCamera`,
`VillageScene.ts:143`). **La procédure de nettoyage préalable prévue en
section 3 du plan n'est donc pas nécessaire** pour la map actuelle — à
revérifier seulement si une itération future réintègre un rendu Camille brut
non repassé par le pipeline de génération du projet.

## 11. Repères visuels mesurés (pour `map-generation-spec.json`)

Mesures fiables (mêmes coordonnées que les colliders `VillageScene.ts`,
repère monde = repère pixel de l'image, échelle 1:1) :
- Maison moyenne : ~390×570 à 450×570 px d'empreinte au sol.
- Grand bâtiment (moulin) : ~750×500 px.
- Fontaine : ~280×260 px.
- Héros en jeu : 145 px de hauteur logique affichée (échelle 1:1 avec l'image).

Mesures approximatives (lecture visuelle sur planche graduée, à recalibrer
avant génération réelle — voir `art/maps/qa/` une fois le premier test
produit) :
- Largeur du chemin central (dallage) : **~150-200 px**.
- Largeur de la rivière (côté ouest) : **~120-150 px**.

## 12. Deux carrefours, chemin central, bordure fermée par le décor

Confirmé visuellement et par le code (`VillageScene.ts:18-29`) : la map
actuelle est en réalité DEUX carrefours (Bourg-nord en haut, Place en bas)
reliés par un chemin central continu, entourés d'une forêt qui referme
visuellement les bords est/ouest. C'est un point de départ idéal pour un
premier test d'extension nord ou sud (le chemin sort déjà « dans le vide »
visuellement à ces deux bords) plutôt qu'est/ouest (sortie à percer dans la
forêt/rivière).

## Conclusion de l'audit

Le terrain est favorable : image maître unique (pas de tuiles), échelle 1:1
sans mise à l'échelle Phaser, aucune UI à nettoyer, sorties nord/sud déjà
« amorcées » visuellement. Le risque principal identifié et déjà documenté
par un échec antérieur est la fiabilité du masque côté API (aucune des deux
API disponibles ne protège réellement les pixels masqués) — le plan en
section 9 le contourne correctement par recomposition locale systématique,
condition sine qua non pour respecter le critère d'acceptation n°1 (« la map
existante reste pixel pour pixel identique »).

# Pipeline d'extension de map par outpainting contrôlé

Étend la map peinte d'Eluminia chunk par chunk, sans jamais retoucher les
pixels déjà approuvés. Voir `docs/map-extension-audit.md` pour le contexte
complet (pourquoi ce pipeline, précédents échecs, contraintes mesurées).

## Principe

```
carte existante (protégée)  →  ChatGPT (brief artistique, à partir des voisins)
                             →  canevas court (bande de contexte + zone vide)
                             →  Nano Banana génère UNIQUEMENT la zone vide
                             →  recomposition locale : pixels source réinjectés
                                tels quels, seule la zone générée est neuve
                             →  validation pixel exacte (bloquante, jamais contournée)
                             →  ChatGPT (revue notée /100 sur l'assemblage,
                                régénération si < 95, jusqu'à 3 tentatives)
                             →  approbation HUMAINE (map:approve, toujours manuelle)
                                → world.json mis à jour
```

"Generate Region (Dry Run)" = `npm run map:extend -- --source ... --direction ... --theme "..." --dry-run` :
affiche chunks/voisins, prompt Banana, prompt brief ChatGPT, coût combiné estimé
et la liste des fichiers qui seraient créés, **sans appeler aucune IA**.

La protection des pixels existants n'est PAS déléguée à un masque côté API
(aucune des deux API disponibles — OpenAI `/images/edits` ni Nano Banana — ne
garantit qu'un masque est respecté, voir audit §8). Elle est assurée
localement par `processors/canvas.mjs` : le master final est reconstruit en
copiant les pixels sources originaux + en n'ajoutant QUE la zone nouvellement
générée, jamais l'inverse. `validators/protected-pixels.mjs` vérifie ensuite
cette garantie octet par octet — testé sur les 4 directions avec un faux
résultat généré avant tout appel API réel (0 pixel protégé modifié sur
9,6M pixels vérifiés, dans les 4 cas).

## Commandes

```
npm run map:extend -- --source 0_0 --direction south --theme "sentier forestier vers un pont effondré" --dry-run
npm run map:extend -- --source 0_0 --direction south --theme "..."          # appel réel (1 brief + 1 à 3 génération(s)/revue(s))
npm run map:preview -- --chunk 0_1
npm run map:validate -- --chunk 0_1
npm run map:approve -- --chunk 0_1 --gen gen-0_0-south-<timestamp>
npm run map:split -- --source 0_0 --size 1024
npm run map:tiles -- --dry-run       # grille fixe dérivée — géométrie seule, aucun fichier écrit
npm run map:tiles                    # écrit la grille fixe (sharp local, aucun appel IA)
```

`--dry-run` (sur `map:extend` ou `map:tiles`) n'appelle jamais l'API et
n'écrit aucun fichier : il affiche la géométrie calculée, les connecteurs
détectés, les prompts (Banana + brief ChatGPT) et une estimation de coût.
Les deux dry-run sont indépendants : ni `map:extend` ni `map:tiles` ne
déclenche l'autre automatiquement.

Nécessite `GEMINI_API_KEY` (Nano Banana) **et** `OPENAI_API_KEY` (ChatGPT,
brief + revue) pour un `map:extend` réel — `map:tiles` n'a besoin d'aucune
clé (sharp local uniquement).

### Revue ChatGPT et régénération

À chaque `map:extend` réel : un appel ChatGPT texte produit un court brief
artistique (ajouté en annexe du prompt Nano Banana, sans modifier le gabarit
imposé), puis après recomposition un appel ChatGPT vision note l'assemblage
sur 100. Si la note est < 95 et qu'il reste des tentatives, le prompt est
réinjecté avec les constats ChatGPT et une nouvelle génération Banana est
lancée — **maximum 3 tentatives**. La validation pixel exacte (zone protégée
identique) reste un échec bloquant à **chaque** tentative, jamais contourné
par le score ChatGPT. `map:approve` reste un geste **100% humain** : le score
ChatGPT enrichit `art/maps/qa/<chunk>-visual-review.md`, il ne l'auto-remplit
jamais sur la ligne finale d'approbation.

### Grille fixe dérivée (`art/maps/tiles/`)

`map:tiles` reconstruit une grille de tuiles de taille **fixe** (2048x2048 par
défaut, configurable via `--tile-size`) à partir des masters organiques
approuvés de `world.json` — pour le futur chargement Phaser dynamique
(pas encore consommé par le jeu, comme `map:split`). La génération elle-même
reste **organique** (taille variable, voir plus haut) : la grille fixe est une
couche dérivée en lecture seule, jamais l'unité de génération elle-même —
forcer chaque appel Nano Banana à produire exactement 2048x2048 casserait
l'outpainting organique et la protection pixel-exacte déjà auditée.

Chaque chunk approuvé de `world.json` porte désormais `originPx` (position
absolue de son coin (0,0) dans l'espace-monde partagé) et `paintedRegionPx`
(rect absolu qu'il possède **exclusivement** — les masters organiques sont
cumulatifs, un chunk enfant contient toujours les pixels de son parent en
plus des siens, voir plus bas). Ces deux champs sont dérivés uniquement des
offsets déjà calculés par `planExtension()`, jamais d'une nouvelle géométrie.
`cmdApprove` refuse d'approuver un chunk dont le `paintedRegionPx` chevauche
celui d'un chunk déjà approuvé — nécessaire dès qu'une deuxième branche
d'extension existera, pas encore atteignable avec la seule chaîne linéaire
actuelle (0_0 → 0_1).

Par tuile (`art/maps/tiles/chunk_<gx>_<gy>/`) :

| Fichier | Contenu | Réécrit à chaque `map:tiles` ? |
|---|---|---|
| `background.png` | pixels réels composés depuis les masters organiques | oui, toujours |
| `meta.json` | position, `coveredRect`, `isPartial`, sources organiques | oui, toujours (100% dérivé) |
| `connectors.json` | connecteurs `world.json` projetés en coordonnées absolues | oui, toujours (dérivé) |
| `collisions.json` | `{ colliders: [] }` — **scaffold vide**, non dérivable d'un PNG peint sans vision dédiée | non — créé seulement si absent |
| `objects.json` | `{ objects: [] }` — idem | non — créé seulement si absent |
| `navigation.json` | `{ walkableRects: [] }` — idem | non — créé seulement si absent |
| `spawn.json` | non produit par cette itération (à l'intégration Phaser, hors périmètre ici) | — |

Tuile en bord de monde connu (bbox pas multiple de la taille de tuile) :
le PNG est **recadré exactement au contenu réellement peint**, jamais gonflé
de transparent jusqu'à 2048x2048 — respecte la règle "ne jamais étirer une
image" en n'introduisant aucune surface non peinte. `meta.json.isPartial`
et `pngOffsetInCell` documentent ce recadrage pour le futur code de
chargement Phaser.

**`map:split` vs `map:tiles`** — ne pas confondre malgré la même convention
de nommage `chunk_<gx>_<gy>` : `map:split` découpe naïvement **un seul**
master (`art/maps/chunks/`, aucune notion de position absolue ni de fichiers
compagnons) ; `map:tiles` compose la grille **multi-master** à position
absolue avec ses fichiers compagnons (`art/maps/tiles/`).

**Limite connue** : un chevauchement entre deux branches d'extension
distinctes n'est détecté qu'au moment de `map:approve` (rejet), pas résolu
automatiquement — non traité dans cette itération.

## Fichiers produits par une extension réelle

```
art/maps/history/<genId>/
  before.png                              # copie de la source au moment de la génération
  chatgpt-brief.txt                       # brief artistique ChatGPT, ajouté en annexe du prompt Banana
  chatgpt-brief-request.json
  canvas.png                              # ce qui est envoyé à Nano Banana (contexte + zone vide)
  mask.png                                # masque documentaire (convention : opaque = protégé)
  prompt.txt                              # prompt Banana final (brief ChatGPT inclus)
  params.json
  raw-generation.png                      # réponse brute de la tentative retenue, non fiable telle quelle
  extension-only.png                      # UNIQUEMENT la zone générée, extraite du brut
  assembled.png                           # source intacte + extension-only, jamais l'inverse (tentative retenue)
  chatgpt-review-attempt-{1..3}.json      # revue notée ChatGPT de chaque tentative
  chatgpt-review-summary.json             # { attempts, finalScore, passed, chosenAttempt }

art/maps/qa/<chunkId>-protected-area-report.json   # diff pixel exact (tentative retenue)
art/maps/qa/<chunkId>-seam-preview.png              # bande ±400px + ligne de couture
art/maps/qa/<chunkId>-visual-review.md              # constats ChatGPT + approbation humaine, toujours manuelle
```

Rien n'est écrit dans `art/maps/masters/` ni `world.json` avant
`map:approve` — un chunk généré peut être rejeté sans aucun impact sur la map
approuvée.

## Limites connues (voir audit pour le détail)

- Largeur de chemin/rivière dans `map-generation-spec.json` : estimations
  visuelles, à recalibrer avant une génération réelle en série.
- Extension **nord/ouest** : le repère (0,0) du nouveau master se décale —
  toute coordonnée de jeu existante (colliders, PNJ) devra être translatée
  lors de l'intégration Phaser. Extension **sud/est** : aucun décalage.
- La continuité SÉMANTIQUE de la couture (le chemin/la rivière se prolonge
  vraiment, pas juste une couleur cohérente) n'est PAS automatisable de façon
  fiable : `seam-preview.mjs` ne calcule qu'un écart de teinte grossier, la
  revue visuelle humaine/Claude (`*-visual-review.md`) reste seule autorité.
- `art/maps/chunks/` (découpage pour le chargement Phaser dynamique) n'est
  pas encore consommé par le jeu — `map:split` produit les fichiers, mais
  aucun chargement/déchargement dynamique n'existe dans `VillageScene.ts`
  (hors périmètre de cette tâche, cf. section 16 de la demande initiale).

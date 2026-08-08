# Règles assets — Eluminia (spike 3D)

## Principe : 100 % procédural

Le jeu ne charge AUCUNE image ni modèle 3D externe. Tout le rendu vient de
géométries Three.js primitives + matériaux toon + contours peints, générés
par code au chargement de la page. C'est un choix assumé (validé par
Camille), pas un pis-aller — ne propose pas de pipeline d'assets comme
solution par défaut.

## Recettes déjà en place (à réutiliser, ne pas dupliquer)

- `toon(geo, color, opts)` — matériau `MeshToonMaterial` + gradient map
  `warmGradient` + contour peint automatique (`addOutline`). Utiliser pour
  TOUT objet de décor visible.
- `addOutline(mesh, scale)` — contour peint par inverted-hull (couleur
  `OUTLINE = 0x3d2f52`, jamais noir pur).
- `addGlowOutline(mesh, scale, color)` — variante lumineuse (portails,
  éléments magiques), invisible par défaut, à activer via `.visible = true`.
- `applyCurvature(material)` — injecte la déformation « petite planète » dans
  le shader ; OBLIGATOIRE sur tout matériau de décor pour rester cohérent
  avec le sol lors du dézoom (vue système). `toonPlain()` (sans courbure) est
  réservé aux objets déjà sphériques (icônes de planète).
- `scatter(count, radiusMin, radiusMax, fn)` — dispersion aléatoire évitant le
  corridor du pont (`inBridgeCorridor`).
- `THREE.InstancedMesh` — OBLIGATOIRE dès qu'un même petit objet se répète en
  nombre (herbe, fleurs, champignons) : un objet individuel par instance
  coûte 1-2 draw calls + une ombre, source connue de chute de FPS.
- `makeSignSprite(text)` — panneau texte peint sur canvas, pour tout panneau
  directionnel/label 3D.
- `addObstacle(x, z, r)` — collision cercle-cercle simple avec le héros ;
  tout objet solide nouvellement ajouté doit y être enregistré.

## Palette bonbon Eluminia (référence)

Vert feuillage `0x7fd07a`/`0x5fb562`/`0x9adf8f`, menthe `0x8fe0d0`/`0x6fc7b8`,
rose `0xf3a6c9`/`0xe084b0`, sol `0x8fd66a`, bois `0x8a5a3a`/`0x9a6b46`, pierre
`0x9a978c`/`0x8a8478`, contour `0x3d2f52` (jamais noir pur), lumière dorée
`0xffdca0`/`0xffe9c4`.

## Génération d'images (dormant, non branché)

Un générateur EST connecté (serveur MCP local **eluminia-images**,
`.mcp.json` → `scripts/mcp-image-server.mjs`, moteur OpenAI gpt-image-1 via
`generate_image` ou `node scripts/generate-image.mjs --prompt "..."
--filename x.png [--transparent]`), mais **le jeu ne l'utilise actuellement
pas**. Ne le mobilise que sur besoin explicite de Camille (ex. une texture
qu'aucune primitive ne peut approcher). Sortie : `public/spike3d-generated/`
(à créer si besoin — n'existe pas encore). Après toute génération : vérifier
l'image (Read) avant intégration, ne jamais prétendre qu'un asset a été
généré si l'outil n'a pas effectivement tourné.

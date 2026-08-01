// Assemble les tuiles validées (tile-seam-check / tile-cross-check) en un
// seul atlas pour Phaser Tilemap, avec EXTRUSION des bords (répétition du
// pixel de bord dans la marge/l'espacement) — sans ça, le filtrage linéaire
// (illustration peinte, jamais nearest) lit les pixels transparents entre
// tuiles au rendu et affiche une grille sombre visible à chaque jointure,
// même si chaque tuile est individuellement seamless. Technique standard des
// atlas de tuiles (TexturePacker, Tiled --extrude-tiles).
import sharp from 'sharp';

const TILE = 128; // taille d'affichage en jeu
const PAD = 4;     // extrusion de chaque côté
const COLS = 3;
const G = 'public/art/generated';

// ordre = index de tuile dans la carte 2D de TileTestScene
const TILES = [
  `${G}/tile-herbe-test.png`,      // 0 herbe
  `${G}/tile-chemin-droit.png`,    // 1 chemin droit
  `${G}/tile-chemin-virage-v2.png`,// 2 chemin virage
  `${G}/tile-eau-v2.png`,          // 3 eau (bloquante)
  `${G}/tile-berge-v2.png`,        // 4 berge
  `${G}/tile-lisiere.png`,         // 5 lisière de forêt
];

async function extrude(file) {
  const img = sharp(file).resize(TILE, TILE).ensureAlpha();
  const { data, info } = await img.raw().toBuffer({ resolveWithObject: true });
  const w = info.width, h = info.height, c = info.channels;
  const ow = w + 2 * PAD, oh = h + 2 * PAD;
  const out = Buffer.alloc(ow * oh * c);

  const srcAt = (x, y) => {
    const cx = Math.min(w - 1, Math.max(0, x));
    const cy = Math.min(h - 1, Math.max(0, y));
    return (cy * w + cx) * c;
  };
  for (let y = 0; y < oh; y++) {
    for (let x = 0; x < ow; x++) {
      const s = srcAt(x - PAD, y - PAD); // clamp-to-edge : répète le pixel de bord
      const d = (y * ow + x) * c;
      for (let ch = 0; ch < c; ch++) out[d + ch] = data[s + ch];
    }
  }
  return sharp(out, { raw: { width: ow, height: oh, channels: c } }).png().toBuffer();
}

const cellStep = TILE + 2 * PAD; // les extrusions voisines se touchent exactement (pas de vide, pas de recouvrement)
const rows = Math.ceil(TILES.length / COLS);
const width = COLS * cellStep;
const height = rows * cellStep;

const composite = [];
for (let i = 0; i < TILES.length; i++) {
  const col = i % COLS;
  const row = Math.floor(i / COLS);
  const buf = await extrude(TILES[i]);
  composite.push({ input: buf, left: col * cellStep, top: row * cellStep });
}

const outPath = `${G}/tileset-prototype.png`;
await sharp({ create: { width, height, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } } })
  .composite(composite)
  .png()
  .toFile(outPath);

console.log(`Atlas écrit : ${outPath} (${width}x${height}, tuile ${TILE}px + extrusion ${PAD}px)`);
console.log(`addTilesetImage: tileWidth=${TILE} tileHeight=${TILE} margin=${PAD} spacing=${2 * PAD}`);
console.log('Index : 0 herbe · 1 chemin-droit · 2 chemin-virage · 3 eau · 4 berge · 5 lisière');

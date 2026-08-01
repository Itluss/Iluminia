// Découpe pure (aucune génération IA) de public/art/generated/image.png en
// deux moitiés verticales pour le prototype SeamTestScene (#seamtest).
// Usage : node scripts/art-qa/split-seam-image.mjs
import sharp from 'sharp';
import { resolve } from 'node:path';

const SRC = resolve('public/art/generated/image.png');
const OUT_WEST = resolve('public/art/generated/village-west.png');
const OUT_EAST = resolve('public/art/generated/village-east.png');

const meta = await sharp(SRC).metadata();
const half = Math.round(meta.width / 2);
console.log(`Source : ${meta.width}x${meta.height} — coupe à x=${half}`);

await sharp(SRC).extract({ left: 0, top: 0, width: half, height: meta.height }).png().toFile(OUT_WEST);
await sharp(SRC).extract({ left: half, top: 0, width: meta.width - half, height: meta.height }).png().toFile(OUT_EAST);
console.log(`Écrit : ${OUT_WEST} (${half}x${meta.height})`);
console.log(`Écrit : ${OUT_EAST} (${meta.width - half}x${meta.height})`);

// Sanity check : la colonne de droite de "west" et la colonne de gauche de
// "east" sont des colonnes ADJACENTES du même fichier source — la diff doit
// être quasi nulle par construction (pas un raccord de deux images distinctes).
const west = sharp(OUT_WEST).ensureAlpha();
const east = sharp(OUT_EAST).ensureAlpha();
const { data: wData, info: wInfo } = await west.raw().toBuffer({ resolveWithObject: true });
const { data: eData, info: eInfo } = await east.raw().toBuffer({ resolveWithObject: true });
const h = Math.min(wInfo.height, eInfo.height);
const wCol = wInfo.width - 1;
let sum = 0;
for (let y = 0; y < h; y++) {
  for (let ch = 0; ch < 3; ch++) {
    const a = wData[(y * wInfo.width + wCol) * wInfo.channels + ch];
    const b = eData[(y * eInfo.width + 0) * eInfo.channels + ch];
    sum += Math.abs(a - b);
  }
}
const meanDiff = sum / (h * 3);
console.log(`Diff moyenne bord droit(west) / bord gauche(east) : ${meanDiff.toFixed(2)} / 255 (attendu ~0, colonnes adjacentes de la même source).`);

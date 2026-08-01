// Test exploratoire : aligne les frames vidéo de la fontaine sur le décor
// (échelle + position calculées par détection du bleu de l'eau), masque en
// silhouette (ellipse adoucie) pour ne remplacer QUE la fontaine peinte,
// et compose un aperçu par frame dans art/reviews/fountain-test/composite/.
import sharp from 'sharp';
import { mkdirSync, readdirSync } from 'node:fs';
import { resolve } from 'node:path';

const DIORAMA = 'public/art/generated/village-diorama-B2-clean.png';
const RAW_DIR = resolve('art/reviews/fountain-test/raw-frames');
const OUT_DIR = resolve('art/reviews/fountain-test/composite');
mkdirSync(OUT_DIR, { recursive: true });

// mesuré par détection de bleu (voir historique de session) :
// bbox eau diorama (monde) : 1356,1006 -> 1548,1110 (w192 h104)
// bbox eau vidéo (frame)   : 182,252   -> 743,555   (w561 h303)
const SCALE = ((1548 - 1356) / (743 - 182) + (1110 - 1006) / (555 - 252)) / 2; // ~0.3427
const videoWaterCx = (182 + 743) / 2;
const videoWaterCy = (252 + 555) / 2;
const dioramaWaterCx = (1356 + 1548) / 2;
const dioramaWaterCy = (1006 + 1110) / 2;
const offsetX = Math.round(dioramaWaterCx - videoWaterCx * SCALE);
const offsetY = Math.round(dioramaWaterCy - videoWaterCy * SCALE);

console.log('scale', SCALE, 'offset', offsetX, offsetY);

const meta = await sharp(RAW_DIR + '/f00_t0.00.png').metadata();
const scaledW = Math.round(meta.width * SCALE);
const scaledH = Math.round(meta.height * SCALE);
const localCx = Math.round(videoWaterCx * SCALE);
const localCy = Math.round(videoWaterCy * SCALE);
const rx = 155, ry = 135; // silhouette de la fontaine (base+bassin), un peu plus large que le bbox d'eau

const maskSvg = Buffer.from(`
  <svg width="${scaledW}" height="${scaledH}">
    <defs><filter id="f" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="10"/></filter></defs>
    <ellipse cx="${localCx}" cy="${localCy - 10}" rx="${rx}" ry="${ry}" fill="white" filter="url(#f)"/>
  </svg>
`);
const maskBuf = await sharp(maskSvg).png().toBuffer();

const files = readdirSync(RAW_DIR).filter(f => f.endsWith('.png')).sort();
for (const f of files) {
  const resized = await sharp(RAW_DIR + '/' + f)
    .resize(scaledW, scaledH)
    .ensureAlpha()
    .composite([{ input: maskBuf, blend: 'dest-in' }])
    .png()
    .toBuffer();

  // NB : chaîner .composite().extract() dans UN seul pipeline sharp ignore
  // silencieusement le composite (constaté avec sharp@0.35.3) — on sépare
  // donc composite (vers buffer) et extract (aperçu recadré) en deux appels.
  const composited = await sharp(DIORAMA)
    .composite([{ input: resized, left: offsetX, top: offsetY }])
    .png()
    .toBuffer();
  await sharp(composited)
    .extract({ left: 1150, top: 750, width: 600, height: 600 })
    .png()
    .toFile(resolve(OUT_DIR, 'preview_' + f));
}
console.log('composites écrits pour', files.length, 'frames ->', OUT_DIR);

// Vérifie par calcul le raccord entre deux tuiles DIFFÉRENTES (contrairement
// à tile-seam-check.mjs qui vérifie l'auto-répétition d'une seule tuile).
// Compare le bord indiqué de A au bord indiqué de B (ce qui se toucherait si
// A était posée à côté de B dans la grille).
import sharp from 'sharp';

const [fileA, edgeA, fileB, edgeB, outMosaic] = process.argv.slice(2);
if (!fileA || !edgeA || !fileB || !edgeB) {
  console.error('Usage: node tile-cross-check.mjs <A.png> <top|bottom|left|right> <B.png> <top|bottom|left|right> [mosaique.png]');
  process.exit(1);
}

async function raw(file) {
  return sharp(file).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
}

function edgeLine({ data, info }, edge) {
  const { width: w, height: h, channels: c } = info;
  const line = [];
  if (edge === 'left' || edge === 'right') {
    const x = edge === 'left' ? 0 : w - 1;
    for (let y = 0; y < h; y++) line.push([0, 1, 2].map(ch => data[(y * w + x) * c + ch]));
  } else {
    const y = edge === 'top' ? 0 : h - 1;
    for (let x = 0; x < w; x++) line.push([0, 1, 2].map(ch => data[(y * w + x) * c + ch]));
  }
  return line;
}

const a = edgeLine(await raw(fileA), edgeA);
const b = edgeLine(await raw(fileB), edgeB);
const n = Math.min(a.length, b.length);
let sum = 0;
for (let i = 0; i < n; i++) for (let ch = 0; ch < 3; ch++) sum += Math.abs(a[i][ch] - b[i][ch]);
const avg = sum / (n * 3);

console.log(`${fileA} [${edgeA}]  vs  ${fileB} [${edgeB}]`);
console.log(`Diff moyenne : ${avg.toFixed(2)} / 255  (seuil indicatif < 12/255)`);
console.log(avg < 12 ? 'RESULTAT: raccord probable' : 'RESULTAT: raccord visible probable');

if (outMosaic) {
  const metaA = await sharp(fileA).metadata();
  const metaB = await sharp(fileB).metadata();
  const w = Math.max(metaA.width, metaB.width);
  const h = Math.max(metaA.height, metaB.height);
  const horizontal = edgeA === 'left' || edgeA === 'right';
  const canvas = horizontal
    ? { width: w * 2, height: h }
    : { width: w, height: h * 2 };
  const layout =
    edgeA === 'right' || edgeA === 'bottom'
      ? [{ input: fileA, left: 0, top: 0 }, { input: fileB, left: horizontal ? w : 0, top: horizontal ? 0 : h }]
      : [{ input: fileB, left: 0, top: 0 }, { input: fileA, left: horizontal ? w : 0, top: horizontal ? 0 : h }];
  await sharp({ create: { ...canvas, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 1 } } })
    .composite(layout)
    .png()
    .toFile(outMosaic);
  console.log(`Mosaïque écrite : ${outMosaic}`);
}

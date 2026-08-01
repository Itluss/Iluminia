// Vérifie par calcul la « tuilabilité » d'une image : diff moyenne entre le
// bord gauche/droit et haut/bas (ce qui se touche quand la tuile se répète),
// + génère une mosaïque 3x3 pour confirmation visuelle.
import sharp from 'sharp';

const src = process.argv[2];
const outMosaic = process.argv[3];
if (!src || !outMosaic) {
  console.error('Usage: node tile-seam-check.mjs <tuile.png> <mosaique-sortie.png>');
  process.exit(1);
}

const img = sharp(src).ensureAlpha();
const { data, info } = await img.raw().toBuffer({ resolveWithObject: true });
const { width: w, height: h, channels: c } = info;

function px(x, y, ch) {
  return data[(y * w + x) * c + ch];
}

function edgeDiff(colA, colB, count, axis) {
  let sum = 0;
  for (let i = 0; i < count; i++) {
    for (let ch = 0; ch < 3; ch++) {
      const a = axis === 'x' ? px(colA, i, ch) : px(i, colA, ch);
      const b = axis === 'x' ? px(colB, i, ch) : px(i, colB, ch);
      sum += Math.abs(a - b);
    }
  }
  return sum / (count * 3);
}

const leftRight = edgeDiff(0, w - 1, h, 'x');
const topBottom = edgeDiff(0, h - 1, w, 'y');

console.log(`Dimensions : ${w}x${h}`);
console.log(`Diff moyenne bord gauche/droit : ${leftRight.toFixed(2)} / 255`);
console.log(`Diff moyenne bord haut/bas     : ${topBottom.toFixed(2)} / 255`);
console.log(`Seuil indicatif « seamless » : < 8/255 sur les deux axes.`);
console.log(leftRight < 8 && topBottom < 8 ? 'RESULTAT: probablement seamless (a confirmer visuellement)' : 'RESULTAT: seam probable (raccord visible attendu)');

// mosaïque 3x3 pour confirmation visuelle
await sharp({
  create: { width: w * 3, height: h * 3, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 1 } },
})
  .composite(
    Array.from({ length: 9 }, (_, i) => ({
      input: src,
      left: (i % 3) * w,
      top: Math.floor(i / 3) * h,
    })),
  )
  .png()
  .toFile(outMosaic);
console.log(`Mosaïque écrite : ${outMosaic}`);

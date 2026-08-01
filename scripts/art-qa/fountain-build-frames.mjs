// Test exploratoire : construit les textures finales de la fontaine animée
// (frames masquées en silhouette, échelle/position calées sur le décor) et
// les écrit dans public/art/generated/fountain-anim-test/.
import sharp from 'sharp';
import { mkdirSync, readdirSync } from 'node:fs';
import { resolve } from 'node:path';

const RAW_DIR = resolve('art/reviews/fountain-test/raw-frames');
const OUT_DIR = resolve('public/art/generated/fountain-anim-test');
mkdirSync(OUT_DIR, { recursive: true });

const SCALE = 0.342740156368578;
const scaledW = 378, scaledH = 280;
const localCx = 159, localCy = 138;
const rx = 155, ry = 135;

const maskSvg = Buffer.from(`
  <svg width="${scaledW}" height="${scaledH}">
    <defs><filter id="f" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="10"/></filter></defs>
    <ellipse cx="${localCx}" cy="${localCy - 10}" rx="${rx}" ry="${ry}" fill="white" filter="url(#f)"/>
  </svg>
`);
const maskBuf = await sharp(maskSvg).png().toBuffer();

// correction demandée par la revue visuelle : l'eau I2V est trop saturée et
// trop froide comparée à la dominante dorée du décor peint — désaturation
// ~18 % + réchauffement ~7 % (overlay ambre léger).
const warmOverlay = Buffer.from(
  `<svg width="${scaledW}" height="${scaledH}"><rect width="100%" height="100%" fill="rgba(255,190,110,0.07)"/></svg>`,
);

const files = readdirSync(RAW_DIR).filter(f => f.endsWith('.png')).sort();
let i = 0;
for (const f of files) {
  await sharp(RAW_DIR + '/' + f)
    .resize(scaledW, scaledH)
    .modulate({ saturation: 0.82 })
    .composite([{ input: warmOverlay, blend: 'overlay' }])
    .ensureAlpha()
    .composite([{ input: maskBuf, blend: 'dest-in' }])
    .png()
    .toFile(resolve(OUT_DIR, `fountain-anim-${String(i).padStart(2, '0')}.png`));
  i++;
}
console.log(i, 'frames ->', OUT_DIR, `(${scaledW}x${scaledH}, offset monde 1293,920)`);

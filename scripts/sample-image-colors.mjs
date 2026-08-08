// Échantillonne des couleurs RÉELLES (calcul, pas à l'œil) sur une image de
// référence — même principe que la vérification d'alpha par canvas déjà
// utilisée pour les icônes (board-fidelity.md §4), étendu aux couleurs pour
// la construction d'assets 3D procéduraux fidèles à une planche.
//
// Usage :
//   node scripts/sample-image-colors.mjs --image chemin.png \
//     --points "obelisque_base:0.42,0.58;anneau_sol:0.50,0.63;orbe_lanterne:0.30,0.44"
//
// Coordonnées en fractions (0-1) de la largeur/hauteur de l'image. Moyenne
// sur un carré de quelques pixels autour du point (évite un pixel de bruit
// isolé). Sortie : hex + rgb par point nommé, prêt à coller dans le code.
import { chromium } from 'playwright';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

const args = process.argv.slice(2);
const opt = {};
for (let i = 0; i < args.length; i++) { if (args[i].startsWith('--')) opt[args[i].slice(2)] = args[++i]; }
if (!opt.image || !opt.points) {
  console.error('Usage : --image chemin.png --points "nom:xFrac,yFrac;nom2:xFrac,yFrac"');
  process.exit(1);
}
const points = opt.points.split(';').map(p => {
  const [name, coords] = p.split(':');
  const [xf, yf] = coords.split(',').map(Number);
  return { name, xf, yf };
});
const imagePath = resolve(opt.image);
const toHex = n => n.toString(16).padStart(2, '0');

const browser = await chromium.launch();
const page = await browser.newPage();
await page.goto(pathToFileURL(imagePath).href);
const results = await page.evaluate(async (pts) => {
  const img = document.images[0] || (() => { const i = new Image(); i.src = location.href; return i; })();
  await new Promise(res => { if (img.complete) res(); else img.onload = res; });
  const c = document.createElement('canvas'); c.width = img.naturalWidth; c.height = img.naturalHeight;
  const ctx = c.getContext('2d');
  ctx.drawImage(img, 0, 0);
  return pts.map(({ name, xf, yf }) => {
    const x = Math.round(xf * c.width), y = Math.round(yf * c.height);
    const size = 5;
    const data = ctx.getImageData(Math.max(0, x - size), Math.max(0, y - size), size * 2, size * 2).data;
    let r = 0, g = 0, b = 0, n = 0;
    for (let i = 0; i < data.length; i += 4) { r += data[i]; g += data[i + 1]; b += data[i + 2]; n++; }
    r = Math.round(r / n); g = Math.round(g / n); b = Math.round(b / n);
    return { name, x, y, r, g, b };
  });
}, points);
await browser.close();

for (const r of results) {
  const hex = `#${toHex(r.r)}${toHex(r.g)}${toHex(r.b)}`;
  console.log(`${r.name.padEnd(20)} (${r.x},${r.y})  rgb(${r.r},${r.g},${r.b})  ${hex}  0x${toHex(r.r)}${toHex(r.g)}${toHex(r.b)}`);
}

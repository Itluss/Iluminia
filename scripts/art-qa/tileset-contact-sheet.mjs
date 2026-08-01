// Planche de contrôle unique : réduit et assemble plusieurs images de
// vérification (mosaïques d'auto-répétition + raccords croisés + décor) en
// une seule grille, pour une revue visuelle en une lecture.
import sharp from 'sharp';

const THUMB = 340;
const items = [
  ['art/reviews/tile-mosaic-herbe.png', 'herbe (3x3)'],
  ['art/reviews/tile-mosaic-chemin-droit.png', 'chemin droit (3x3)'],
  ['art/reviews/tile-mosaic-eau.png', 'eau (3x3)'],
  ['art/reviews/tile-mosaic-lisiere.png', 'lisiere (3x3)'],
  ['public/art/generated/tile-berge.png', 'berge (seule)'],
  ['public/art/generated/tile-chemin-virage.png', 'chemin virage (seule)'],
  ['art/reviews/cross-herbe-cheminDroit-top.png', 'herbe/chemin (haut)'],
  ['art/reviews/cross-eau-berge-bottom.png', 'eau/berge (bas)'],
  ['public/art/generated/decor-arbre.png', 'decor arbre'],
  ['public/art/generated/decor-fontaine.png', 'decor fontaine'],
];

const cols = 4;
const rows = Math.ceil(items.length / cols);
const labelH = 30;
const cellW = THUMB;
const cellH = THUMB + labelH;

const composite = [];
for (let i = 0; i < items.length; i++) {
  const [file] = items[i];
  const col = i % cols;
  const row = Math.floor(i / cols);
  const buf = await sharp(file)
    .resize(THUMB, THUMB, { fit: 'contain', background: { r: 30, g: 30, b: 30, alpha: 1 } })
    .toBuffer();
  composite.push({ input: buf, left: col * cellW, top: row * cellH + labelH });
}

// labels via SVG text overlay
const labelsSvg = items
  .map(([, label], i) => {
    const col = i % cols;
    const row = Math.floor(i / cols);
    const x = col * cellW + 6;
    const y = row * cellH + 20;
    return `<text x="${x}" y="${y}" font-family="sans-serif" font-size="18" fill="white">${label}</text>`;
  })
  .join('');
const svg = `<svg width="${cols * cellW}" height="${rows * cellH}" xmlns="http://www.w3.org/2000/svg">
  <rect width="100%" height="100%" fill="#1e1e1e"/>
  ${labelsSvg}
</svg>`;

await sharp(Buffer.from(svg))
  .composite(composite)
  .png()
  .toFile('art/reviews/tileset-contact-sheet.png');
console.log('Écrit : art/reviews/tileset-contact-sheet.png');

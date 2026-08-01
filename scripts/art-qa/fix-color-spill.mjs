// Outil réutilisable : retire le liseré de couleur (spill de détourage
// magenta) sur des pièces PNG déjà keyées. Les pixels semi-transparents dont
// la couleur penche vers le fond magenta d'origine sont rendus entièrement
// transparents (pas de reflou : le bord légèrement plus dur est imperceptible
// à la taille de jeu). Utile après toute génération IA de pièce game-ready.
//
// Usage : node scripts/art-qa/fix-color-spill.mjs <fichier1.png> [fichier2.png ...]
import sharp from 'sharp';
import { resolve } from 'node:path';

const files = process.argv.slice(2);
if (!files.length) {
  console.error('Usage : node scripts/art-qa/fix-color-spill.mjs <fichier1.png> [...]');
  process.exit(1);
}

for (const f of files) {
  const path = resolve(f);
  const img = sharp(path);
  const { width, height } = await img.metadata();
  const raw = await img.raw().ensureAlpha().toBuffer();
  let fixed = 0;
  for (let i = 0; i < width * height; i++) {
    const o = i * 4;
    const a = raw[o + 3];
    if (a === 0 || a === 255) continue;
    const r = raw[o], g = raw[o + 1], b = raw[o + 2];
    const spillScore = (r + b) / 2 - g; // magenta ~ (254,3,250) : vert très faible
    if (spillScore > 55) {
      raw[o + 3] = 0;
      fixed++;
    }
  }
  await sharp(raw, { raw: { width, height, channels: 4 } }).png().toFile(path);
  console.log(`${f}: ${fixed} pixels de liseré retirés`);
}

// Banc de contrôle des textures d'animation : extrait du moteur les frames
// EXACTEMENT telles qu'elles ont été fabriquées au boot (détourage, rognage,
// réduction) et les écrit dans art/reviews/frames/. C'est la vérité terrain :
// si une frame est mauvaise ici, elle est mauvaise en jeu.
// Usage : node scripts/dump-frames.mjs   (GAME_URL surchargeable)
import { chromium } from 'playwright';
import { mkdirSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';

const GAME_URL = process.env.GAME_URL || 'http://localhost:5173';
const OUT_DIR = resolve('art/reviews/frames');
mkdirSync(OUT_DIR, { recursive: true });

let browser;
try {
  browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1600, height: 900 } });
  await page.goto(GAME_URL, { waitUntil: 'networkidle', timeout: 20000 });
  await page.waitForTimeout(2500); // boot + fabrication des textures

  const frames = await page.evaluate(() => {
    const game = window.__ELUMINIA_GAME;
    if (!game) return { error: 'jeu non exposé' };
    const out = [];
    const keys = game.textures.getTextureKeys().filter(k => /^walk-(side|front|back)-\d+$/.test(k));
    keys.sort();
    for (const key of keys) {
      const src = game.textures.get(key).getSourceImage();
      const c = document.createElement('canvas');
      c.width = src.width;
      c.height = src.height;
      c.getContext('2d').drawImage(src, 0, 0);
      out.push({ key, w: src.width, h: src.height, data: c.toDataURL('image/png') });
    }
    return { frames: out };
  });

  if (frames.error) throw new Error(frames.error);
  const summary = [];
  for (const f of frames.frames) {
    const b64 = f.data.replace(/^data:image\/png;base64,/, '');
    writeFileSync(resolve(OUT_DIR, `${f.key}.png`), Buffer.from(b64, 'base64'));
    summary.push(`${f.key} : ${f.w}x${f.h}`);
  }
  console.log(summary.join('\n'));
  console.log(`${frames.frames.length} frames extraites dans ${OUT_DIR}`);
} catch (err) {
  console.error(`Échec : ${err}`);
  process.exitCode = 1;
} finally {
  if (browser) await browser.close();
}

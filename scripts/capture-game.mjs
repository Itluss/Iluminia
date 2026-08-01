// Capture automatisée du jeu Eluminia (Playwright / Chromium).
// Usage : node scripts/capture-game.mjs   (GAME_URL surchargeable)
import { chromium } from 'playwright';
import { mkdirSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';

const GAME_URL = process.env.GAME_URL || 'http://localhost:5173';
const OUT_DIR = resolve('art/reviews');
const OUT_PNG = resolve(OUT_DIR, 'latest.png');
const OUT_ERRORS = resolve(OUT_DIR, 'browser-errors.json');

mkdirSync(OUT_DIR, { recursive: true });

const errors = [];
let browser;

try {
  browser = await chromium.launch();
  const page = await browser.newPage({
    viewport: { width: 1600, height: 900 },
    deviceScaleFactor: 1,
  });

  page.on('pageerror', err => errors.push({ type: 'pageerror', message: String(err) }));
  page.on('console', msg => {
    if (msg.type() === 'error') errors.push({ type: 'console.error', message: msg.text() });
  });

  await page.goto(GAME_URL, { waitUntil: 'networkidle', timeout: 20000 });
  // le temps que la scène s'installe : boot (détourage + découpe des planches
  // d'animation) puis fondu d'ouverture — capturer trop tôt rend tout terne
  await page.waitForTimeout(3400);

  // masquer d'éventuels outils de debug
  await page
    .evaluate(() => {
      for (const sel of ['#debug', '.debug', '#stats']) {
        document.querySelectorAll(sel).forEach(el => (el.style.display = 'none'));
      }
    })
    .catch(() => {});

  // capturer la zone de jeu la plus précise disponible
  let target = null;
  for (const sel of ['canvas', '#game', '#app']) {
    target = await page.$(sel);
    if (target) break;
  }
  if (target) {
    await target.screenshot({ path: OUT_PNG });
  } else {
    await page.screenshot({ path: OUT_PNG, fullPage: false });
  }

  writeFileSync(OUT_ERRORS, JSON.stringify(errors, null, 2));
  console.log(`Capture : ${OUT_PNG}`);
  console.log(`Erreurs navigateur : ${errors.length} (${OUT_ERRORS})`);
} catch (err) {
  writeFileSync(OUT_ERRORS, JSON.stringify([...errors, { type: 'fatal', message: String(err) }], null, 2));
  console.error(`Échec de capture : ${err}`);
  process.exitCode = 1;
} finally {
  if (browser) await browser.close();
}

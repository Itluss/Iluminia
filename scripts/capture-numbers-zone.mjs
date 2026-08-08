// Capture ciblée de la zone du défi des grands nombres (mécanique CUEILLETTE),
// non visible depuis le spawn par défaut : déplace le héros via le hook de
// debug avant la capture. Usage ponctuel pour cette itération (cf.
// scripts/capture-inventory.mjs pour le même principe sur l'inventaire).
import { chromium } from 'playwright';
import { mkdirSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';

const GAME_URL = process.env.GAME_URL || 'http://localhost:5173/spike3d-village.html';
const OUT_PNG = resolve('art/reviews/latest.png');
const OUT_ERRORS = resolve('art/reviews/browser-errors.json');
mkdirSync(resolve('art/reviews'), { recursive: true });

const errors = [];
let browser;
try {
  browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1600, height: 900 }, deviceScaleFactor: 1 });
  page.on('pageerror', err => errors.push({ type: 'pageerror', message: String(err) }));
  page.on('console', msg => { if (msg.type() === 'error') errors.push({ type: 'console.error', message: msg.text() }); });

  await page.goto(GAME_URL, { waitUntil: 'networkidle', timeout: 20000 });
  await page.waitForTimeout(3400);
  await page.evaluate(() => window.__spikeDebug.gotoNumbers());
  await page.waitForTimeout(2500);

  const target = await page.$('canvas');
  if (target) await target.screenshot({ path: OUT_PNG });
  else await page.screenshot({ path: OUT_PNG, fullPage: false });

  writeFileSync(OUT_ERRORS, JSON.stringify(errors, null, 2));
  console.log(`Capture : ${OUT_PNG}`);
  console.log(`Erreurs navigateur : ${errors.length}`);
} catch (err) {
  writeFileSync(OUT_ERRORS, JSON.stringify([...errors, { type: 'fatal', message: String(err) }], null, 2));
  console.error(`Échec de capture : ${err}`);
  process.exitCode = 1;
} finally {
  if (browser) await browser.close();
}

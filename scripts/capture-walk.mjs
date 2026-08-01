// Capture ANIMÉE du héros : simule la marche dans 4 directions et
// photographie une rafale de frames par direction. Sert de banc de contrôle
// des cycles d'animation (art/reviews/walk/<dir>-<n>.png).
// Usage : node scripts/capture-walk.mjs   (GAME_URL surchargeable)
import { chromium } from 'playwright';
import { mkdirSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';

const GAME_URL = process.env.GAME_URL || 'http://localhost:5173';
const OUT_DIR = resolve('art/reviews/walk');
const OUT_ERRORS = resolve(OUT_DIR, 'browser-errors.json');
const SHOTS = 6; // frames photographiées par direction
const SHOT_EVERY_MS = 110;

mkdirSync(OUT_DIR, { recursive: true });
const errors = [];
let browser;

try {
  browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1600, height: 900 }, deviceScaleFactor: 1 });
  page.on('pageerror', err => errors.push({ type: 'pageerror', message: String(err) }));
  page.on('console', msg => {
    if (msg.type() === 'error') errors.push({ type: 'console.error', message: msg.text() });
  });

  await page.goto(GAME_URL, { waitUntil: 'networkidle', timeout: 20000 });
  await page.waitForTimeout(3400); // boot (planches) + fondu + dézoom d'intro
  const canvas = await page.$('canvas');
  if (!canvas) throw new Error('canvas introuvable');
  await canvas.click(); // focus clavier

  // dégager le point de départ : on remonte un peu pour avoir du champ au
  // sud (clôture) comme au nord — les rafales down/up ont besoin de place
  await page.keyboard.down('ArrowUp');
  await page.waitForTimeout(600);
  await page.keyboard.up('ArrowUp');
  await page.waitForTimeout(400);

  const dirs = [
    ['right', 'ArrowRight'],
    ['left', 'ArrowLeft'],
    ['down', 'ArrowDown'],
    ['up', 'ArrowUp'],
  ];
  for (const [name, key] of dirs) {
    await page.keyboard.down(key);
    await page.waitForTimeout(260); // laisse le cycle s'installer
    for (let i = 0; i < SHOTS; i++) {
      await canvas.screenshot({ path: resolve(OUT_DIR, `${name}-${i}.png`) });
      await page.waitForTimeout(SHOT_EVERY_MS);
    }
    await page.keyboard.up(key);
    await page.waitForTimeout(350);
  }

  // transition brutale gauche → haut : la rafale démarre AVANT la bascule
  // pour photographier l'instant du retournement (le cas piège du miroir)
  await page.keyboard.down('ArrowLeft');
  await page.waitForTimeout(400);
  for (let i = 0; i < 8; i++) {
    if (i === 3) {
      await page.keyboard.up('ArrowLeft');
      await page.keyboard.down('ArrowUp');
    }
    await canvas.screenshot({ path: resolve(OUT_DIR, `trans-${i}.png`) });
    await page.waitForTimeout(70);
  }
  await page.keyboard.up('ArrowUp');

  writeFileSync(OUT_ERRORS, JSON.stringify(errors, null, 2));
  console.log(`Rafales : ${OUT_DIR} (${dirs.length} directions × ${SHOTS})`);
  console.log(`Erreurs navigateur : ${errors.length}`);
} catch (err) {
  writeFileSync(OUT_ERRORS, JSON.stringify([...errors, { type: 'fatal', message: String(err) }], null, 2));
  console.error(`Échec : ${err}`);
  process.exitCode = 1;
} finally {
  if (browser) await browser.close();
}

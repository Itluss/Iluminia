// Vérifie que le collider élargi de la maison nord-est bloque bien la marche
// AVANT le pied de l'appentis (avant : le joueur pouvait s'y tenir dessus).
import { chromium } from 'playwright';
import { mkdirSync } from 'node:fs';
import { resolve } from 'node:path';

const GAME_URL = process.env.GAME_URL || 'http://localhost:5173';
const OUT_DIR = resolve('art/reviews/fountain-test');
mkdirSync(OUT_DIR, { recursive: true });

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1600, height: 900 }, deviceScaleFactor: 1 });
await page.goto(GAME_URL, { waitUntil: 'networkidle', timeout: 20000 });
await page.waitForTimeout(3400);
const canvas = await page.$('canvas');
await canvas.click();

// point de départ au nord de l'appentis, hors collider
await page.evaluate(() => {
  const scene = window.__ELUMINIA_GAME.scene.getScene('village');
  scene.player.setPosition(2050, 650);
  scene.cameras.main.stopFollow();
  scene.cameras.main.centerOn(2050, 800);
});
await page.waitForTimeout(150);

await page.keyboard.down('ArrowDown');
await page.waitForTimeout(2500);
await page.keyboard.up('ArrowDown');
await page.waitForTimeout(200);

await canvas.screenshot({ path: resolve(OUT_DIR, 'verify-ne-house-after.png') });
const pos = await page.evaluate(() => {
  const scene = window.__ELUMINIA_GAME.scene.getScene('village');
  return { x: Math.round(scene.player.x), y: Math.round(scene.player.y) };
});
console.log('position finale', pos);

await browser.close();

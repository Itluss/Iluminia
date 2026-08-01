// Debug ponctuel : navigue vers la maison nord-est (rivière) pour reproduire
// le signalement de Camille (personnage qui semble marcher sur le décor) et
// inspecte les objets de scène (position joueur, doublons éventuels).
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

// téléportation directe pour le debug (pas de simulation clavier lente/bloquée
// par les colliders) : positionne le joueur près de la maison nord-est/rivière
await page.evaluate(() => {
  const game = window.__ELUMINIA_GAME;
  const scene = game.scene.getScene('village');
  scene.player.setPosition(2050, 900);
  scene.cameras.main.stopFollow();
  scene.cameras.main.centerOn(2050, 900);
});
await page.waitForTimeout(200);

await canvas.screenshot({ path: resolve(OUT_DIR, 'debug-ne-house.png') });

const info = await page.evaluate(() => {
  const game = window.__ELUMINIA_GAME;
  const scene = game.scene.getScene('village');
  const list = scene.children.list
    .filter(o => o.texture && /hero|walk|lina/i.test(o.texture.key))
    .map(o => ({ type: o.type, texKey: o.texture.key, x: Math.round(o.x), y: Math.round(o.y), visible: o.visible, alpha: o.alpha }));
  return { playerListLength: list.length, list };
});
console.log(JSON.stringify(info, null, 2));

await browser.close();

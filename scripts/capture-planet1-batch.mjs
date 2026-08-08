// Capture de plusieurs vues pour la revue visuelle groupée de l'itération
// "planète 1 : 6 nouvelles quêtes". Une capture par zone représentative +
// une capture par défaut (non-régression). Usage ponctuel (comme
// capture-numbers-zone.mjs), pas un remplacement de npm run capture.
import { chromium } from 'playwright';
import { mkdirSync } from 'node:fs';
import { resolve } from 'node:path';

const GAME_URL = process.env.GAME_URL || 'http://localhost:5173/spike3d-village.html';
const OUT_DIR = resolve('art/reviews');
mkdirSync(OUT_DIR, { recursive: true });

const shots = [
  { name: 'latest.png', teleport: null },
  { name: 'latest-numbers.png', teleport: [20, -15] },
  { name: 'latest-compass.png', teleport: [2, -24] },
  { name: 'latest-sort.png', teleport: [30, 18] },
  { name: 'latest-match.png', teleport: [-10, 18] },
  { name: 'latest-sam.png', teleport: [-8, -20] },
];

let browser;
try {
  browser = await chromium.launch();
  for (const shot of shots) {
    const page = await browser.newPage({ viewport: { width: 1600, height: 900 }, deviceScaleFactor: 1 });
    const errors = [];
    page.on('pageerror', e => errors.push(String(e)));
    page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
    await page.goto(GAME_URL, { waitUntil: 'networkidle', timeout: 20000 });
    await page.waitForTimeout(3400);
    if (shot.teleport) {
      await page.evaluate(([x, z]) => window.__spikeDebug.gotoZone(x, z), shot.teleport);
      await page.waitForTimeout(1200);
    }
    await page.locator('canvas').screenshot({ path: resolve(OUT_DIR, shot.name) });
    console.log(`${shot.name}: ${errors.length} erreur(s)`, errors);
    await page.close();
  }
} finally {
  if (browser) await browser.close();
}

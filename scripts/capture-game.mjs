// Capture automatisée du jeu Eluminia (Playwright / Chromium).
// Usage : node scripts/capture-game.mjs   (GAME_URL, VIEWPORT_W, VIEWPORT_H, OUT_NAME surchargeables)
import { chromium } from 'playwright';
import { mkdirSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';

const GAME_URL = process.env.GAME_URL || 'http://localhost:5173';
const VIEWPORT_W = Number(process.env.VIEWPORT_W) || 1600;
const VIEWPORT_H = Number(process.env.VIEWPORT_H) || 900;
const OUT_DIR = resolve('art/reviews');
const OUT_PNG = resolve(OUT_DIR, process.env.OUT_NAME || 'latest.png');
const OUT_ERRORS = resolve(OUT_DIR, 'browser-errors.json');

mkdirSync(OUT_DIR, { recursive: true });

const errors = [];
let browser;

try {
  // PW_EXECUTABLE_PATH : chemin d'un Chromium préinstallé (sessions cloud où
  // le téléchargement Playwright est indisponible) — sans effet en local.
  browser = await chromium.launch(
    process.env.PW_EXECUTABLE_PATH ? { executablePath: process.env.PW_EXECUTABLE_PATH } : {});
  const page = await browser.newPage({
    viewport: { width: VIEWPORT_W, height: VIEWPORT_H },
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

  // PRE_CAPTURE_JS : script optionnel évalué dans la page avant la capture —
  // permet de mettre en scène un état de jeu précis via les hooks de debug
  // (__spikeDebug/__arenaDebug). Une expression async (IIFE) est attendue
  // si des délais internes sont nécessaires.
  if (process.env.PRE_CAPTURE_JS) {
    await page.evaluate(process.env.PRE_CAPTURE_JS);
  }

  // capturer la zone de jeu la plus précise disponible — MAIS seulement si
  // le canvas trouvé occupe (quasi) tout le viewport (cas des scènes
  // Three.js plein écran, village/arène). Un <canvas> plus petit intégré
  // dans un HUD DOM (ex. le portrait 3D du personnage sur spike3d-menu.html,
  // 2026-08-07) ne doit PAS remplacer la capture pleine page — sinon on ne
  // voit plus que le canvas et tout le reste de l'écran est perdu.
  let target = null;
  for (const sel of ['canvas', '#game', '#app']) {
    const el = await page.$(sel);
    if (!el) continue;
    const box = await el.boundingBox();
    if (box && box.width >= VIEWPORT_W * 0.9 && box.height >= VIEWPORT_H * 0.9) {
      target = el;
      break;
    }
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

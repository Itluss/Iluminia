// Capture ponctuelle du panneau inventaire ouvert (le panneau est display:none
// par défaut, la capture standard ne le verrait pas sans ouverture explicite).
import { chromium } from 'playwright';
import { mkdirSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';

const GAME_URL = process.env.GAME_URL || 'http://localhost:5173/spike3d-village.html';
const OUT_PNG = resolve('art/reviews/latest.png');
const OUT_ERRORS = resolve('art/reviews/browser-errors.json');
mkdirSync(resolve('art/reviews'), { recursive: true });

const errors = [];
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1600, height: 900 }, deviceScaleFactor: 1 });
page.on('pageerror', err => errors.push({ type: 'pageerror', message: String(err) }));
page.on('console', msg => { if (msg.type() === 'error') errors.push({ type: 'console.error', message: msg.text() }); });

await page.goto(GAME_URL, { waitUntil: 'networkidle', timeout: 20000 });
await page.waitForTimeout(3400);
// L'ouverture du panneau joue une animation de pop-in (.35s) : sans neutraliser
// cette animation, une capture prise trop tôt fige le modal en plein zoom
// d'entrée, ce qui a faussé des revues précédentes.
await page.addStyleTag({ content: '#inventory-modal { animation: none !important; }' });
await page.evaluate(() => window.__spikeDebug.openInventory());
await page.waitForTimeout(150);
await page.screenshot({ path: OUT_PNG });
writeFileSync(OUT_ERRORS, JSON.stringify(errors, null, 2));
console.log(`Capture inventaire : ${OUT_PNG}`);
console.log(`Erreurs navigateur : ${errors.length}`);
await browser.close();

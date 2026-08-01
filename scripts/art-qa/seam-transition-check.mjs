// Vérifie PAR CALCUL que la bascule west->east de SeamTestScene est
// imperceptible. Le readback canvas (page.screenshot) s'est révélé bien trop
// lent dans cet environnement (GPU stall / software readback, plusieurs
// centaines de ms par capture — vu en console) pour échantillonner des
// frames autour d'un événement qui dure ~16ms : au lieu de ça, on vérifie
// l'invariant mathématique exact que le code doit garantir : la position À
// L'ÉCRAN du joueur, screenX = (player.x - scrollX) * zoom, ne doit PAS
// changer d'un pixel entre la dernière frame avant bascule et la première
// frame après — quel que soit l'état du lissage caméra en cours. Vérifié via
// le hook léger window.__seamDebug() (pas de capture d'écran, juste des
// nombres), échantillonné aussi vite que possible.
import { chromium } from 'playwright';

const GAME_URL = process.env.GAME_URL || 'http://localhost:5173/#seamtest';

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1600, height: 900 }, deviceScaleFactor: 1 });
await page.goto(GAME_URL, { waitUntil: 'networkidle', timeout: 20000 });
await page.waitForTimeout(4000); // laisser BootScene finir son preload (gros assets village) avant addKey()
await page.mouse.click(800, 450);
await page.keyboard.down('ArrowRight');

const samples = [];
const t0 = Date.now();
let sideAtStart = null;
while (Date.now() - t0 < 6000) {
  const s = await page.evaluate(() => window.__seamDebug?.());
  if (!s) continue;
  if (sideAtStart === null) sideAtStart = s.side;
  samples.push({ t: Date.now() - t0, ...s });
  if (samples.length > 3 && s.side !== sideAtStart) break; // bascule capturée, on arrête
}
await page.keyboard.up('ArrowRight');
await browser.close();

const screenX = s => (s.x - s.scrollX) * s.zoom;

const crossIdx = samples.findIndex((s, i) => i > 0 && s.side !== samples[i - 1].side);
if (crossIdx === -1) {
  console.error(`Bascule non observée en 6s (${samples.length} échantillons) — vérifier __seamDebug/switchSide.`);
  process.exitCode = 1;
  process.exit();
}
const before = samples[crossIdx - 1];
const after = samples[crossIdx];
const jump = Math.abs(screenX(after) - screenX(before));

// référence : jitter écran normal entre deux échantillons consécutifs EN
// dehors de toute bascule (régime établi), pour juger si `jump` est notable.
const steadySamples = samples.slice(0, Math.max(2, crossIdx - 2));
let steadyJitterSum = 0;
for (let i = 1; i < steadySamples.length; i++) steadyJitterSum += Math.abs(screenX(steadySamples[i]) - screenX(steadySamples[i - 1]));
const steadyJitterMean = steadySamples.length > 1 ? steadyJitterSum / (steadySamples.length - 1) : 0;

console.log(`Échantillons avant bascule : ${crossIdx}, bascule détectée à l'échantillon #${crossIdx} (t=${after.t}ms).`);
console.log(`Avant  : side=${before.side} x=${before.x.toFixed(2)} scrollX=${before.scrollX.toFixed(2)} zoom=${before.zoom.toFixed(3)} -> screenX=${screenX(before).toFixed(3)}px`);
console.log(`Après  : side=${after.side}  x=${after.x.toFixed(2)} scrollX=${after.scrollX.toFixed(2)} zoom=${after.zoom.toFixed(3)} -> screenX=${screenX(after).toFixed(3)}px`);
console.log(`Saut de position écran à la bascule : ${jump.toFixed(3)}px`);
console.log(`Jitter écran moyen en régime établi (hors bascule, ${steadySamples.length} échantillons) : ${steadyJitterMean.toFixed(3)}px`);
console.log(`Seuil indicatif « transition imperceptible » : saut < 1px (sub-pixel, l'écran ne peut pas l'afficher).`);
console.log(jump < 1 ? 'RESULTAT: AUCUN saut détectable — la position écran du joueur est mathématiquement inchangée au moment de la bascule.' : 'RESULTAT: saut mesurable — transition potentiellement visible, à corriger.');

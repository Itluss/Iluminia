import { chromium } from 'playwright';

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 851, height: 393 } });
const errors = [];
page.on('pageerror', e => errors.push(String(e)));
page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });

await page.goto('http://localhost:5173/spike3d-arena.html');
// force Math.random à toujours retourner 0 -> garantit un drop (soin) à la fin de manche
await page.addInitScript(() => { Math.random = () => 0; });
await page.reload();
await page.click('#start-btn');
await page.evaluate(() => window.__arenaDebug.skipCountdown());
await page.waitForTimeout(50);
await page.evaluate(() => window.__arenaDebug.forceEnd());
await page.waitForTimeout(150);

const gainText = await page.evaluate(() => document.getElementById('familiar-gain-line').textContent);
const cardH = await page.evaluate(() => document.querySelector('#round-end .card').getBoundingClientRect().height);
const btnBox = await (await page.$('#restart-btn')).boundingBox();
console.log('texte du gain familier (round-end, drop forcé):', gainText);
console.log('hauteur carte:', cardH, '| bouton visible en entier:', btnBox.y + btnBox.height <= 393);

console.log('ERRORS', errors);
await browser.close();

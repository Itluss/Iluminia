import { chromium } from 'playwright';

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1600, height: 900 } });
const errors = [];
page.on('pageerror', e => errors.push(String(e)));
page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
await page.goto('http://localhost:5173/spike3d-village.html', { waitUntil: 'networkidle' });
await page.waitForTimeout(1000);

const canvas = await page.$('canvas');
const box = await canvas.boundingBox();
await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2);

await page.screenshot({ path: 'tess-normal.png' });

for (let i = 0; i < 60; i++) {
  await page.mouse.wheel(0, 45);
  await page.waitForTimeout(90);
  if ([40, 50, 59].includes(i)) {
    await page.screenshot({ path: `tess-step${i}.png` });
  }
}

console.log('erreurs:', errors.length, errors.slice(0, 5));
await browser.close();

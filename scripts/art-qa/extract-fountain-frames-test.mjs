// Test exploratoire : extrait quelques frames de la vidéo fontaine pour inspection
// avant tentative d'intégration dans le décor. Usage : node scripts/art-qa/extract-fountain-frames-test.mjs
import { chromium } from 'playwright';
import { mkdirSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';

const OUT_DIR = resolve('art/reviews/fountain-test/raw-frames');
mkdirSync(OUT_DIR, { recursive: true });

const browser = await chromium.launch();
const page = await browser.newPage();
await page.goto('http://localhost:5173/_video-probe-tmp.html', { waitUntil: 'load' });
await page.waitForFunction(() => window.__ready);
const { duration, width, height } = await page.evaluate(() => window.__ready);
console.log('duration', duration, 'size', width, height);

await page.evaluate(({ width, height }) => {
  const v = document.getElementById('v');
  const c = document.createElement('canvas');
  c.id = 'c';
  c.width = width;
  c.height = height;
  document.body.appendChild(c);
  window.__grab = async t => {
    await new Promise(res => {
      const onSeeked = () => { v.removeEventListener('seeked', onSeeked); res(); };
      v.addEventListener('seeked', onSeeked);
      v.currentTime = t;
    });
    const ctx = c.getContext('2d');
    ctx.drawImage(v, 0, 0, width, height);
    return c.toDataURL('image/png');
  };
}, { width, height });

const N = 8;
for (let i = 0; i < N; i++) {
  const t = Math.min(duration - 0.05, (duration / N) * i);
  const dataUrl = await page.evaluate(t => window.__grab(t), t);
  const b64 = dataUrl.replace(/^data:image\/png;base64,/, '');
  writeFileSync(resolve(OUT_DIR, `f${String(i).padStart(2, '0')}_t${t.toFixed(2)}.png`), Buffer.from(b64, 'base64'));
}
console.log('frames extraites:', N, '->', OUT_DIR);
await browser.close();

import { chromium } from 'playwright';

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 851, height: 393 } });
const errors = [];
page.on('pageerror', e => errors.push(String(e)));
page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });

await page.goto('http://localhost:5173/spike3d-arena.html');
await page.addInitScript(() => {
  localStorage.setItem('eluminia-familiar-owned', JSON.stringify({ poussin: 3, loutre: 2, renardin: 1 }));
});
await page.reload();
await page.waitForTimeout(300);

// screenshot the start screen with pet picker
await page.screenshot({ path: 'art/reviews/latest-start.png' });

const pickerState = await page.evaluate(() => ({
  buttons: Array.from(document.querySelectorAll('.pet-pick-btn')).map(b => b.className),
  selected: window.__arenaDebug.getSelectedPet(),
  slotTypes: window.__arenaDebug.getSlotTypes(),
}));
console.log('PICKER AT START', JSON.stringify(pickerState, null, 2));

// click the 2nd pet (loutre) on the start screen
const btns = await page.$$('.pet-pick-btn');
await btns[1].click();
await page.waitForTimeout(100);
const afterPick = await page.evaluate(() => ({
  selected: window.__arenaDebug.getSelectedPet(),
  slotTypes: window.__arenaDebug.getSlotTypes(),
}));
console.log('AFTER CLICKING LOUTRE', JSON.stringify(afterPick, null, 2));

await page.click('#start-btn');
await page.evaluate(() => window.__arenaDebug.skipCountdown());
await page.evaluate(() => window.__arenaDebug.setEnergy && window.__arenaDebug.setEnergy(100));
await page.evaluate(() => window.__arenaDebug.setFamiliarGauge && window.__arenaDebug.setFamiliarGauge(2));
await page.waitForTimeout(300);

const geo = await page.evaluate(() => {
  const btns = Array.from(document.querySelectorAll('.ability-btn')).map(b => b.getBoundingClientRect());
  return { btnCount: btns.length, btns };
});
console.log('IN-ROUND BUTTONS', JSON.stringify(geo, null, 2));

await page.screenshot({ path: 'art/reviews/latest.png' });
console.log('ERRORS', errors);
await browser.close();

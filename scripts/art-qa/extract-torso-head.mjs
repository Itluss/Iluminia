// Découpe torso + tête directement depuis le master (même méthode que les
// jambes/bras). Le patch yeux/bouche est évidé du head_base (alpha=0) pour
// laisser les slots eyes_open/mouth_smile — eux aussi découpés du master à
// l'endroit exact — s'afficher par-dessus (le système d'expression a
// toujours besoin de calques séparés pour blink/talk).
import sharp from 'sharp';
import { readFileSync, writeFileSync, mkdirSync, copyFileSync } from 'node:fs';
import { resolve } from 'node:path';

const base = resolve('public/art/characters/hero');
const master = resolve(base, 'approved/master_front.png');
const rigPath = resolve(base, 'rig/hero.rig.json');
const rig = JSON.parse(readFileSync(rigPath, 'utf8').replace(/^﻿/, ''));
const W = rig.space.width, H = rig.space.height;
const boneAbs = id => {
  const b = rig.bones.find(b => b.id === id);
  return { x: b.pos[0] * W, y: b.pos[1] * H };
};
const archiveDir = resolve(base, 'parts/_archive');
mkdirSync(archiveDir, { recursive: true });

function updateSlot(part, bone, rect) {
  const [left, top, width, height] = rect;
  const pivotAbs = boneAbs(bone);
  const pivot = [
    Math.round(((pivotAbs.x - left) / width) * 1000) / 1000,
    Math.round(((pivotAbs.y - top) / height) * 1000) / 1000,
  ];
  const slot = rig.slots.find(s => s.part === part);
  slot.pivot = pivot;
  slot.scale = 1;
  delete slot.rotDeg;
  delete slot.offset;
  console.log(`${part}: pivot=${pivot} (${width}x${height})`);
}

function archive(part) {
  const p = resolve(base, 'parts', `${part}.png`);
  copyFileSync(p, resolve(archiveDir, `${part}.pre-master-crop.png`));
  return p;
}

// -- torso : rectangle généreux, tout excès est recouvert par les pièces
// dessinées après (bras z8-9, tête z12) --
{
  const rect = [150, 700, 850, 900];
  const outPath = archive('torso');
  await sharp(master).extract({ left: rect[0], top: rect[1], width: rect[2], height: rect[3] }).png().toFile(outPath);
  updateSlot('torso', 'torso', rect);
}

// -- head_base : rectangle généreux, yeux + bouche évidés (alpha=0) pour
// laisser passer les calques d'expression --
{
  const rect = [200, 0, 750, 900];
  const [left, top, width, height] = rect;
  const outPath = archive('head_base');
  const raw = await sharp(master).extract({ left, top, width, height }).ensureAlpha().raw().toBuffer();
  const holes = [
    { x0: 255 - left, y0: 390 - top, x1: 895 - left, y1: 600 - top }, // yeux
    { x0: 470 - left, y0: 630 - top, x1: 680 - left, y1: 720 - top }, // bouche
  ];
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const inHole = holes.some(h => x >= h.x0 && x < h.x1 && y >= h.y0 && y < h.y1);
      if (inHole) raw[(y * width + x) * 4 + 3] = 0;
    }
  }
  await sharp(raw, { raw: { width, height, channels: 4 } }).png().toFile(outPath);
  updateSlot('head_base', 'head', rect);
}

// -- eyes_open : découpe exacte de la zone yeux du master --
{
  const rect = [255, 390, 640, 210];
  const outPath = archive('eyes_open');
  await sharp(master).extract({ left: rect[0], top: rect[1], width: rect[2], height: rect[3] }).png().toFile(outPath);
  updateSlot('eyes_open', 'head', rect);
  // eyes_closed garde son propre calque (état absent du master) mais doit
  // s'aligner sur le même point d'ancrage désormais natif (scale=1 cassé
  // sinon) — on laisse son échelle/offset existants, gérés séparément.
}

// -- mouth_smile : découpe exacte de la zone bouche du master --
{
  const rect = [470, 630, 210, 90];
  const outPath = archive('mouth_smile');
  await sharp(master).extract({ left: rect[0], top: rect[1], width: rect[2], height: rect[3] }).png().toFile(outPath);
  updateSlot('mouth_smile', 'head', rect);
}

// -- eyes_closed / mouth_open / mouth_neutral : états absents du master
// (le master ne montre qu'une seule expression) — restent des pièces
// générées séparément, mais recalées pour tomber au même endroit à l'écran
// que leur pendant par défaut désormais natif (sinon le clignement « saute »).
async function realignAltState(part, siblingRectWorldCenter, siblingWidthPx) {
  const filePath = resolve(base, 'parts', `${part}.png`);
  const { width } = await sharp(filePath).metadata();
  const headAbs = boneAbs('head');
  const offset = [
    Math.round(((siblingRectWorldCenter[0] - headAbs.x) / W) * 1000) / 1000,
    Math.round(((siblingRectWorldCenter[1] - headAbs.y) / H) * 1000) / 1000,
  ];
  const scale = Math.round((siblingWidthPx / width) * 1000) / 1000;
  const slot = rig.slots.find(s => s.part === part);
  slot.bone = 'head';
  slot.pivot = [0.5, 0.5];
  slot.offset = offset;
  slot.scale = scale;
  delete slot.rotDeg;
  console.log(`${part}: recalé sur eyes_open/mouth_smile — offset=${offset} scale=${scale}`);
}

const eyesCenter = [255 + 640 / 2, 390 + 210 / 2];
await realignAltState('eyes_closed', eyesCenter, 640);
const mouthCenter = [470 + 210 / 2, 630 + 90 / 2];
await realignAltState('mouth_open', mouthCenter, 210);
await realignAltState('mouth_neutral', mouthCenter, 210);

writeFileSync(rigPath, JSON.stringify(rig, null, 2) + '\n');
console.log('rig.json mis à jour.');

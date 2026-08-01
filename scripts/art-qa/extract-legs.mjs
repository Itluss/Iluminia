// Découpe directe des jambes depuis le master (Étape 1 de la nouvelle
// méthode imposée : plus de génération IA indépendante par membre).
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

mkdirSync(resolve(base, 'parts/_archive'), { recursive: true });

const CUTS = [
  { part: 'left_thigh', bone: 'left_hip', rect: [195, 1450, 385, 400] },
  { part: 'left_lower_leg_boot', bone: 'left_knee', rect: [195, 1750, 385, 450] },
  { part: 'right_thigh', bone: 'right_hip', rect: [570, 1450, 385, 400] },
  { part: 'right_lower_leg_boot', bone: 'right_knee', rect: [570, 1750, 385, 450] },
];

for (const cut of CUTS) {
  const [left, top, width, height] = cut.rect;
  const outPath = resolve(base, 'parts', `${cut.part}.png`);
  copyFileSync(outPath, resolve(base, 'parts/_archive', `${cut.part}.pre-master-crop.png`));
  await sharp(master).extract({ left, top, width, height }).png().toFile(outPath);

  const bone = boneAbs(cut.bone);
  const pivot = [
    Math.round(((bone.x - left) / width) * 1000) / 1000,
    Math.round(((bone.y - top) / height) * 1000) / 1000,
  ];

  const slot = rig.slots.find(s => s.part === cut.part);
  slot.pivot = pivot;
  slot.scale = 1;
  delete slot.rotDeg;
  delete slot.offset;
  console.log(`${cut.part}: pivot=${pivot} (découpe ${width}x${height} depuis master)`);
}

writeFileSync(rigPath, JSON.stringify(rig, null, 2) + '\n');
console.log('rig.json mis à jour.');

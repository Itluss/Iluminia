// Banc de contrôle d'assemblage du puppet (Phase 9) — recompose la pose
// statique (angles à 0) depuis le rig et les pièces approuvées, SANS
// navigateur, et produit un triptyque : master | assemblage | superposition.
// Même géométrie que CharacterRig : pièce ancrée au pivot sur son os,
// offset en fractions d'espace, rotation de base rotDeg autour du pivot.
//
// Usage : node scripts/art-qa/assemble-check.mjs [--char hero]
//         [--eyes eyes_closed] [--mouth mouth_open] [--out assembly-check.png]
import sharp from 'sharp';
import { readFileSync, mkdirSync } from 'node:fs';
import { resolve } from 'node:path';

const args = process.argv.slice(2);
const opt = (name, def) => {
  const i = args.indexOf(`--${name}`);
  return i >= 0 ? args[i + 1] : def;
};
const CHAR = opt('char', 'hero');
const OUT = resolve('art/reviews', opt('out', 'assembly-check.png'));
const groupChoice = { eyes: opt('eyes', null), mouth: opt('mouth', null) };

const base = resolve('public/art/characters', CHAR);
const readJson = p => JSON.parse(readFileSync(p, 'utf8').replace(/^﻿/, ''));
const rig = readJson(resolve(base, 'rig', `${CHAR}.rig.json`));
const manifest = readJson(resolve(base, 'character.manifest.json'));
const fileByPart = new Map(manifest.parts.map(p => [p.id, resolve(base, p.filename)]));

const W = rig.space.width;
const H = rig.space.height;

// positions monde des os, angles à zéro : world = pos (l'espace du rig EST
// l'espace du master 1150×2207, unité 1)
const boneXY = new Map(rig.bones.map(b => [b.id, { x: b.pos[0] * W, y: b.pos[1] * H }]));

const deg = d => (d * Math.PI) / 180;

const only = opt('only', null)?.split(',');

const layers = [];
for (const slot of [...rig.slots].sort((a, b) => a.z - b.z)) {
  if (only && !only.includes(slot.part)) continue;
  if (slot.group) {
    const wanted = groupChoice[slot.group];
    if (wanted ? slot.part !== wanted : !slot.default) continue;
  }
  const file = fileByPart.get(slot.part);
  if (!file) {
    console.warn(`pièce absente du manifeste : ${slot.part}`);
    continue;
  }
  const meta = await sharp(file).metadata();
  console.log(
    `${slot.part.padEnd(22)} ${String(meta.width).padStart(5)}×${String(meta.height).padEnd(5)} ×${slot.scale} → ` +
      `${Math.round(meta.width * slot.scale)}×${Math.round(meta.height * slot.scale)} px maître`,
  );
  const w = Math.max(1, Math.round(meta.width * slot.scale));
  const h = Math.max(1, Math.round(meta.height * slot.scale));
  const scaled = await sharp(file).resize(w, h).png().toBuffer();

  const rot = slot.rotDeg ?? 0;
  const rotated = rot
    ? await sharp(scaled).rotate(rot, { background: { r: 0, g: 0, b: 0, alpha: 0 } }).png().toBuffer()
    : scaled;
  const rMeta = await sharp(rotated).metadata();

  // le pivot, exprimé dans l'image redimensionnée, tourne autour du CENTRE
  // lors du rotate de sharp ; on replace donc le pivot tourné sur l'os
  const px = slot.pivot[0] * w;
  const py = slot.pivot[1] * h;
  const cx = w / 2;
  const cy = h / 2;
  const cos = Math.cos(deg(rot));
  const sin = Math.sin(deg(rot));
  const prx = rMeta.width / 2 + (px - cx) * cos - (py - cy) * sin;
  const pry = rMeta.height / 2 + (px - cx) * sin + (py - cy) * cos;

  const bone = boneXY.get(slot.bone);
  if (!bone) {
    console.warn(`os inconnu : ${slot.bone} (slot ${slot.part})`);
    continue;
  }
  const tx = bone.x + (slot.offset?.[0] ?? 0) * W;
  const ty = bone.y + (slot.offset?.[1] ?? 0) * H;
  layers.push({ input: rotated, left: Math.round(tx - prx), top: Math.round(ty - pry) });
}

const blank = { create: { width: W, height: H, channels: 4, background: { r: 240, g: 234, b: 222, alpha: 1 } } };
const assembly = await sharp(blank).composite(layers).png().toBuffer();

const masterPath = resolve(base, 'approved', 'master_front.png');
const master = await sharp(masterPath).resize(W, H).png().toBuffer();
const masterFaint = await sharp(master).ensureAlpha(0.45).png().toBuffer();
const overlay = await sharp(blank)
  .composite([{ input: masterFaint, left: 0, top: 0 }, ...layers])
  .png()
  .toBuffer();

const GAP = 24;
const total = await sharp({
  create: { width: W * 3 + GAP * 2, height: H, channels: 4, background: { r: 255, g: 255, b: 255, alpha: 1 } },
})
  .composite([
    { input: master, left: 0, top: 0 },
    { input: assembly, left: W + GAP, top: 0 },
    { input: overlay, left: (W + GAP) * 2, top: 0 },
  ])
  .png()
  .toBuffer();

mkdirSync(resolve('art/reviews'), { recursive: true });
await sharp(total).resize({ height: 1100 }).toFile(OUT);
console.log(`Banc d'assemblage : ${OUT} (master | assemblage | superposition)`);

// Score de fidélité : compare l'assemblage courant (rig + pièces) au
// personnage maître complet (approved/master_front.png), pixel par pixel,
// UNIQUEMENT là où le master est opaque (silhouette). Produit :
//  - un pourcentage de similarité
//  - une carte thermique des zones qui divergent (rouge = écart fort)
// Usage : node scripts/art-qa/reconstruction-score.mjs [--char hero]
import sharp from 'sharp';
import { readFileSync, mkdirSync } from 'node:fs';
import { resolve } from 'node:path';

const args = process.argv.slice(2);
const opt = (name, def) => {
  const i = args.indexOf(`--${name}`);
  return i >= 0 ? args[i + 1] : def;
};
const CHAR = opt('char', 'hero');
const base = resolve('public/art/characters', CHAR);
const readJson = p => JSON.parse(readFileSync(p, 'utf8').replace(/^﻿/, ''));
const rig = readJson(resolve(base, 'rig', `${CHAR}.rig.json`));
const manifest = readJson(resolve(base, 'character.manifest.json'));
const fileByPart = new Map(manifest.parts.map(p => [p.id, resolve(base, p.filename)]));

const W = rig.space.width;
const H = rig.space.height;
const boneXY = new Map(rig.bones.map(b => [b.id, { x: b.pos[0] * W, y: b.pos[1] * H }]));
const deg = d => (d * Math.PI) / 180;

// -- reconstruit l'assemblage (identique à assemble-check.mjs, sans les faces
// de comparaison) --
const layers = [];
for (const slot of [...rig.slots].sort((a, b) => a.z - b.z)) {
  if (slot.group && !slot.default) continue;
  const file = fileByPart.get(slot.part);
  if (!file) continue;
  const meta = await sharp(file).metadata();
  const w = Math.max(1, Math.round(meta.width * slot.scale));
  const h = Math.max(1, Math.round(meta.height * slot.scale));
  const scaled = await sharp(file).resize(w, h).png().toBuffer();
  const rot = slot.rotDeg ?? 0;
  const rotated = rot
    ? await sharp(scaled).rotate(rot, { background: { r: 0, g: 0, b: 0, alpha: 0 } }).png().toBuffer()
    : scaled;
  const rMeta = await sharp(rotated).metadata();
  const px = slot.pivot[0] * w;
  const py = slot.pivot[1] * h;
  const cx = w / 2;
  const cy = h / 2;
  const cos = Math.cos(deg(rot));
  const sin = Math.sin(deg(rot));
  const prx = rMeta.width / 2 + (px - cx) * cos - (py - cy) * sin;
  const pry = rMeta.height / 2 + (px - cx) * sin + (py - cy) * cos;
  const bone = boneXY.get(slot.bone);
  if (!bone) continue;
  const tx = bone.x + (slot.offset?.[0] ?? 0) * W;
  const ty = bone.y + (slot.offset?.[1] ?? 0) * H;
  layers.push({ input: rotated, left: Math.round(tx - prx), top: Math.round(ty - pry) });
}
const blank = { create: { width: W, height: H, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } } };
const reconstructedBuf = await sharp(blank).composite(layers).png().toBuffer();

const masterPath = resolve(base, 'approved', 'master_front.png');
const masterRaw = await sharp(masterPath).ensureAlpha().raw().toBuffer();
const reconRaw = await sharp(reconstructedBuf).ensureAlpha().raw().toBuffer();

let opaqueCount = 0;
let diffSum = 0;
const heat = Buffer.alloc(W * H * 4);
for (let i = 0; i < W * H; i++) {
  const o = i * 4;
  const ma = masterRaw[o + 3];
  if (ma < 40) continue; // hors silhouette master : pas jugé
  opaqueCount++;
  const ra = reconRaw[o + 3];
  const dr = masterRaw[o] - reconRaw[o];
  const dg = masterRaw[o + 1] - reconRaw[o + 1];
  const db = masterRaw[o + 2] - reconRaw[o + 2];
  const da = ma - ra;
  // écart couleur (si les deux sont couverts) + pénalité si la reconstruction est absente/transparente ici
  const colorDist = Math.sqrt(dr * dr + dg * dg + db * db) / 441.7; // normalisé 0..1
  const missing = ra < 40 ? 1 : 0;
  const score = Math.max(colorDist, missing * 1);
  diffSum += score;
  const heatVal = Math.round(Math.min(1, score) * 255);
  heat[o] = heatVal;
  heat[o + 1] = 0;
  heat[o + 2] = 255 - heatVal;
  heat[o + 3] = ma;
}
const similarity = 100 * (1 - diffSum / Math.max(1, opaqueCount));

const heatImg = await sharp(heat, { raw: { width: W, height: H, channels: 4 } }).png().toBuffer();
const master = await sharp(masterPath).resize(W, H).png().toBuffer();
const GAP = 24;
const total = await sharp({
  create: { width: W * 3 + GAP * 2, height: H, channels: 4, background: { r: 255, g: 255, b: 255, alpha: 1 } },
})
  .composite([
    { input: master, left: 0, top: 0 },
    { input: reconstructedBuf, left: W + GAP, top: 0 },
    { input: heatImg, left: (W + GAP) * 2, top: 0 },
  ])
  .png()
  .toBuffer();

mkdirSync(resolve('art/reviews'), { recursive: true });
const OUT = resolve('art/reviews', 'reconstruction-score.png');
await sharp(total).resize({ height: 1100 }).toFile(OUT);
console.log(`Similarité (silhouette master) : ${similarity.toFixed(1)}%`);
console.log(`Comparatif : ${OUT} (master | reconstruction | carte des écarts)`);

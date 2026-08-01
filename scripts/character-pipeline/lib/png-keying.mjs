// Détourage flood-fill côté Node — portage de l'algorithme éprouvé du jeu
// (src/game/utils/keying.ts) : fond médian du pourtour, BFS depuis les
// bords, adoucissement du contour, plus grande composante connexe, rognage.
// I/O via sharp (libvips) : robuste à toutes les variantes de PNG.
import sharp from 'sharp';
import { statSync } from 'node:fs';

/** Détoure un PNG (fond uni type magenta/gris) et rogne sur la boîte d'alpha.
 *  Écrit le résultat et retourne un rapport { w, h, bbox, bgColor, opaqueRatio }. */
export async function keyAndTrim(inPath, outPath, { tolerance = 140, margin = 8, alphaBox = 100 } = {}) {
  const { data: px, info } = await sharp(inPath).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  const w = info.width;
  const h = info.height;

  // fond = médiane d'échantillons du pourtour (résiste aux lignes parasites)
  const samples = [];
  const take = (x, y) => {
    const i = (y * w + x) * 4;
    samples.push([px[i], px[i + 1], px[i + 2]]);
  };
  for (let t = 0; t < 6; t++) {
    const fx = Math.round(((t + 0.5) / 6) * (w - 1));
    const fy = Math.round(((t + 0.5) / 6) * (h - 1));
    take(fx, 0); take(fx, h - 1); take(0, fy); take(w - 1, fy);
  }
  const med = ch => samples.map(s => s[ch]).sort((a, b) => a - b)[Math.floor(samples.length / 2)];
  const bg = [med(0), med(1), med(2)];
  const isBg = i => {
    const dr = px[i] - bg[0], dg = px[i + 1] - bg[1], db = px[i + 2] - bg[2];
    return dr * dr + dg * dg + db * db < tolerance * tolerance;
  };

  // BFS depuis les bords
  const visited = new Uint8Array(w * h);
  const queue = [];
  const push = (x, y) => {
    if (x < 0 || y < 0 || x >= w || y >= h) return;
    const idx = y * w + x;
    if (visited[idx]) return;
    visited[idx] = 1;
    if (isBg(idx * 4)) { px[idx * 4 + 3] = 0; queue.push(idx); }
  };
  for (let x = 0; x < w; x++) { push(x, 0); push(x, h - 1); }
  for (let y = 0; y < h; y++) { push(0, y); push(w - 1, y); }
  while (queue.length) {
    const idx = queue.pop();
    const x = idx % w, y = (idx - x) / w;
    push(x - 1, y); push(x + 1, y); push(x, y - 1); push(x, y + 1);
  }

  // adoucissement du contour
  for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
    const i = (y * w + x) * 4;
    if (px[i + 3] === 0) continue;
    const empty = (x > 0 && px[i - 4 + 3] === 0) || (x < w - 1 && px[i + 4 + 3] === 0) ||
      (y > 0 && px[i - w * 4 + 3] === 0) || (y < h - 1 && px[i + w * 4 + 3] === 0);
    if (empty) px[i + 3] = Math.min(px[i + 3], 140);
  }

  // plus grande composante connexe (fragments parasites effacés)
  const label = new Int32Array(w * h).fill(-1);
  let best = -1, bestCount = 0, cur = 0;
  const stack = [];
  for (let i = 0; i < w * h; i++) {
    if (label[i] !== -1 || px[i * 4 + 3] <= 8) continue;
    let count = 0;
    stack.push(i); label[i] = cur;
    while (stack.length) {
      const j = stack.pop(); count++;
      const jx = j % w, jy = (j - jx) / w;
      for (const [nx, ny] of [[jx - 1, jy], [jx + 1, jy], [jx, jy - 1], [jx, jy + 1]]) {
        if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
        const n = ny * w + nx;
        if (label[n] === -1 && px[n * 4 + 3] > 8) { label[n] = cur; stack.push(n); }
      }
    }
    if (count > bestCount) { bestCount = count; best = cur; }
    cur++;
  }
  let minX = w, minY = h, maxX = -1, maxY = -1, opaque = 0;
  for (let i = 0; i < w * h; i++) {
    if (px[i * 4 + 3] <= 8) continue;
    if (label[i] !== best) { px[i * 4 + 3] = 0; continue; }
    opaque++;
    if (px[i * 4 + 3] < alphaBox) continue;
    const x = i % w, y = (i - x) / w;
    if (x < minX) minX = x; if (x > maxX) maxX = x;
    if (y < minY) minY = y; if (y > maxY) maxY = y;
  }
  if (maxX < 0) throw new Error('détourage : aucune forme trouvée');

  // purge du « magenta fantôme » : les pixels transparents proches du bord
  // héritent du RGB du voisin opaque (anti-liseré au filtrage GPU), le reste
  // devient gris neutre
  for (let iter = 0; iter < 3; iter++) {
    const snap = Buffer.from(px);
    for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
      const i = (y * w + x) * 4;
      if (px[i + 3] >= 1) continue; // opaque ou déjà teinté
      for (const [nx, ny] of [[x - 1, y], [x + 1, y], [x, y - 1], [x, y + 1]]) {
        if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
        const n = (ny * w + nx) * 4;
        if (snap[n + 3] >= 1) { px[i] = snap[n]; px[i + 1] = snap[n + 1]; px[i + 2] = snap[n + 2]; px[i + 3] = 1; break; }
      }
    }
  }
  for (let i = 0; i < w * h * 4; i += 4) {
    if (px[i + 3] === 1) { px[i + 3] = 0; continue; } // marqueur : redevient transparent
    if (px[i + 3] === 0) { px[i] = 128; px[i + 1] = 128; px[i + 2] = 128; }
  }

  // rognage + marge de sécurité
  minX = Math.max(0, minX - margin); minY = Math.max(0, minY - margin);
  const bw = Math.min(w, maxX + margin + 1) - minX;
  const bh = Math.min(h, maxY + margin + 1) - minY;
  const out = Buffer.alloc(bw * bh * 4);
  for (let y = 0; y < bh; y++) {
    for (let x = 0; x < bw; x++) {
      const s = ((y + minY) * w + (x + minX)) * 4;
      const d = (y * bw + x) * 4;
      out[d] = px[s]; out[d + 1] = px[s + 1];
      out[d + 2] = px[s + 2]; out[d + 3] = px[s + 3];
    }
  }
  await sharp(out, { raw: { width: bw, height: bh, channels: 4 } }).png().toFile(outPath);
  return {
    w: bw, h: bh,
    bbox: { x: minX, y: minY, w: bw, h: bh },
    bgColor: bg,
    opaqueRatio: opaque / (w * h),
  };
}

/** Contrôles automatiques d'une pièce détourée (Phase 7, socle). */
export async function validatePart(path, { minH = 120, maxBytes = 6_000_000 } = {}) {
  const { data: px, info } = await sharp(path).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  const w = info.width;
  const h = info.height;
  const checks = [];
  const corners = [0, (w - 1) * 4, (h - 1) * w * 4, ((h - 1) * w + w - 1) * 4];
  checks.push({ name: 'fond transparent (coins)', ok: corners.every(i => px[i + 3] === 0) });
  let opaque = 0, edgeTouch = 0;
  for (let i = 3; i < px.length; i += 4) if (px[i] > 8) opaque++;
  for (let x = 0; x < w; x++) {
    if (px[x * 4 + 3] > 8) edgeTouch++;
    if (px[((h - 1) * w + x) * 4 + 3] > 8) edgeTouch++;
  }
  for (let y = 0; y < h; y++) {
    if (px[y * w * 4 + 3] > 8) edgeTouch++;
    if (px[(y * w + w - 1) * 4 + 3] > 8) edgeTouch++;
  }
  checks.push({ name: 'pièce non coupée (bords libres)', ok: edgeTouch === 0, detail: `${edgeTouch} px au bord` });
  checks.push({ name: 'résolution suffisante', ok: h >= minH, detail: `${w}x${h}` });
  checks.push({ name: 'contenu présent', ok: opaque > 400, detail: `${opaque} px opaques` });
  const bytes = statSync(path).size;
  checks.push({ name: 'poids acceptable', ok: bytes <= maxBytes, detail: `${Math.round(bytes / 1024)} Ko` });
  const fails = checks.filter(c => !c.ok).length;
  return { status: fails === 0 ? 'PASS' : fails === 1 ? 'WARNING' : 'FAIL', checks, w, h, bytes };
}

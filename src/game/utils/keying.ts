import Phaser from 'phaser';

// Détourage à l'exécution : retire le fond clair d'un asset en partant des
// bords (remplissage), sans toucher aux zones claires INTERNES (yeux, reflets).
// Les fichiers sources ne sont jamais modifiés.
export function addKeyedTexture(scene: Phaser.Scene, srcKey: string, outKey: string, tolerance = 34) {
  const source = scene.textures.get(srcKey).getSourceImage() as HTMLImageElement;
  const w = source.width;
  const h = source.height;

  const canvas = document.createElement('canvas');
  canvas.width = w;
  canvas.height = h;
  const ctx = canvas.getContext('2d')!;
  ctx.drawImage(source, 0, 0);
  const imageData = ctx.getImageData(0, 0, w, h);
  const px = imageData.data;

  // couleur de fond : moyenne des quatre coins
  const corner = (x: number, y: number) => {
    const i = (y * w + x) * 4;
    return [px[i], px[i + 1], px[i + 2]];
  };
  const corners = [corner(0, 0), corner(w - 1, 0), corner(0, h - 1), corner(w - 1, h - 1)];
  const bg = [0, 1, 2].map(c => corners.reduce((s, k) => s + k[c], 0) / 4);

  const isBg = (i: number) => {
    const dr = px[i] - bg[0];
    const dg = px[i + 1] - bg[1];
    const db = px[i + 2] - bg[2];
    return dr * dr + dg * dg + db * db < tolerance * tolerance;
  };

  // BFS depuis tous les pixels de bord ressemblant au fond
  const visited = new Uint8Array(w * h);
  const queue: number[] = [];
  const push = (x: number, y: number) => {
    if (x < 0 || y < 0 || x >= w || y >= h) return;
    const idx = y * w + x;
    if (visited[idx]) return;
    visited[idx] = 1;
    if (isBg(idx * 4)) {
      px[idx * 4 + 3] = 0;
      queue.push(idx);
    }
  };
  for (let x = 0; x < w; x++) {
    push(x, 0);
    push(x, h - 1);
  }
  for (let y = 0; y < h; y++) {
    push(0, y);
    push(w - 1, y);
  }
  while (queue.length) {
    const idx = queue.pop()!;
    const x = idx % w;
    const y = Math.floor(idx / w);
    push(x - 1, y);
    push(x + 1, y);
    push(x, y - 1);
    push(x, y + 1);
  }

  // adoucissement du contour : les pixels opaques qui touchent le vide
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      const i = (y * w + x) * 4;
      if (px[i + 3] === 0) continue;
      const emptyNeighbour =
        (x > 0 && px[i - 4 + 3] === 0) ||
        (x < w - 1 && px[i + 4 + 3] === 0) ||
        (y > 0 && px[i - w * 4 + 3] === 0) ||
        (y < h - 1 && px[i + w * 4 + 3] === 0);
      if (emptyNeighbour) px[i + 3] = Math.min(px[i + 3], 140);
    }
  }

  ctx.putImageData(imageData, 0, 0);
  scene.textures.addCanvas(outKey, canvas);
}

// Découpe une région d'une texture PUIS la détoure (fond uniforme → alpha).
// Utilisé pour extraire les éléments des planches à fond sombre du sprint FX.
export function addKeyedRegionTexture(
  scene: Phaser.Scene,
  srcKey: string,
  outKey: string,
  x: number,
  y: number,
  w: number,
  h: number,
  tolerance = 40,
) {
  const source = scene.textures.get(srcKey).getSourceImage() as HTMLImageElement;
  const c = document.createElement('canvas');
  c.width = w;
  c.height = h;
  const ctx = c.getContext('2d')!;
  ctx.drawImage(source, x, y, w, h, 0, 0, w, h);
  floodKeyCanvas(ctx, w, h, tolerance);
  scene.textures.addCanvas(outKey, c);
}

function floodKeyCanvas(
  ctx: CanvasRenderingContext2D,
  w: number,
  h: number,
  tolerance: number,
  bgOverride?: [number, number, number],
) {
  const imageData = ctx.getImageData(0, 0, w, h);
  const px = imageData.data;
  const corner = (x: number, y: number) => {
    const i = (y * w + x) * 4;
    return [px[i], px[i + 1], px[i + 2]];
  };
  const corners = [corner(0, 0), corner(w - 1, 0), corner(0, h - 1), corner(w - 1, h - 1)];
  const bg = bgOverride ?? [0, 1, 2].map(c2 => corners.reduce((s, k) => s + k[c2], 0) / 4);
  const isBg = (i: number) => {
    const dr = px[i] - bg[0];
    const dg = px[i + 1] - bg[1];
    const db = px[i + 2] - bg[2];
    return dr * dr + dg * dg + db * db < tolerance * tolerance;
  };
  const visited = new Uint8Array(w * h);
  const queue: number[] = [];
  const push = (x: number, y: number) => {
    if (x < 0 || y < 0 || x >= w || y >= h) return;
    const idx = y * w + x;
    if (visited[idx]) return;
    visited[idx] = 1;
    if (isBg(idx * 4)) {
      px[idx * 4 + 3] = 0;
      queue.push(idx);
    }
  };
  for (let x = 0; x < w; x++) {
    push(x, 0);
    push(x, h - 1);
  }
  for (let y = 0; y < h; y++) {
    push(0, y);
    push(w - 1, y);
  }
  while (queue.length) {
    const idx = queue.pop()!;
    const x = idx % w;
    const y = Math.floor(idx / w);
    push(x - 1, y);
    push(x + 1, y);
    push(x, y - 1);
    push(x, y + 1);
  }
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      const i = (y * w + x) * 4;
      if (px[i + 3] === 0) continue;
      const emptyNeighbour =
        (x > 0 && px[i - 4 + 3] === 0) ||
        (x < w - 1 && px[i + 4 + 3] === 0) ||
        (y > 0 && px[i - w * 4 + 3] === 0) ||
        (y < h - 1 && px[i + w * 4 + 3] === 0);
      if (emptyNeighbour) px[i + 3] = Math.min(px[i + 3], 140);
    }
  }
  ctx.putImageData(imageData, 0, 0);
}

// Découpe une planche d'animation en frames : chaque cellule est détourée,
// réduite à sa PLUS GRANDE composante connexe (élimine lignes de cadre et
// fragments des cellules voisines), recadrée sur sa boîte d'alpha, puis
// réduite avec un FACTEUR COMMUN à toute la planche — sinon l'échelle du
// personnage « pulserait » d'une frame à l'autre.
export function addAnimSet(
  scene: Phaser.Scene,
  srcKey: string,
  prefix: string,
  cells: Array<[number, number, number, number]>,
  tolerance: number,
  targetH: number,
): number {
  const source = scene.textures.get(srcKey).getSourceImage() as HTMLImageElement;
  const frames: Array<{ c: HTMLCanvasElement; bx: number; by: number; bw: number; bh: number }> = [];

  for (const [x, y, w, h] of cells) {
    const c = document.createElement('canvas');
    c.width = w;
    c.height = h;
    const ctx = c.getContext('2d')!;
    ctx.drawImage(source, x, y, w, h, 0, 0, w, h);
    // fond = MÉDIANE d'échantillons du pourtour : un coin qui tombe sur une
    // ligne de cadre sombre ne peut plus fausser la couleur de fond (cause
    // du bug « héros sur fond blanc, rétréci, coupé »)
    const border = ctx.getImageData(0, 0, w, h).data;
    const samples: Array<[number, number, number]> = [];
    const sample = (sx: number, sy: number) => {
      const i = (sy * w + sx) * 4;
      samples.push([border[i], border[i + 1], border[i + 2]]);
    };
    for (let t = 0; t < 4; t++) {
      const fx = Math.round(((t + 0.5) / 4) * (w - 1));
      const fy = Math.round(((t + 0.5) / 4) * (h - 1));
      sample(fx, 0);
      sample(fx, h - 1);
      sample(0, fy);
      sample(w - 1, fy);
    }
    const median = (ch: number) => {
      const v = samples.map(s => s[ch]).sort((a, b) => a - b);
      return v[Math.floor(v.length / 2)];
    };
    floodKeyCanvas(ctx, w, h, tolerance, [median(0), median(1), median(2)]);

    // composantes connexes des pixels visibles ; on ne garde que la plus grande
    const id = ctx.getImageData(0, 0, w, h);
    const px = id.data;
    const label = new Int32Array(w * h).fill(-1);
    let best = -1;
    let bestCount = 0;
    let current = 0;
    const stack: number[] = [];
    for (let i = 0; i < w * h; i++) {
      if (label[i] !== -1 || px[i * 4 + 3] <= 8) continue;
      let count = 0;
      stack.push(i);
      label[i] = current;
      while (stack.length) {
        const j = stack.pop()!;
        count++;
        const jx = j % w;
        const jy = (j - jx) / w;
        for (const [nx, ny] of [[jx - 1, jy], [jx + 1, jy], [jx, jy - 1], [jx, jy + 1]] as const) {
          if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
          const n = ny * w + nx;
          if (label[n] === -1 && px[n * 4 + 3] > 8) {
            label[n] = current;
            stack.push(n);
          }
        }
      }
      if (count > bestCount) {
        bestCount = count;
        best = current;
      }
      current++;
    }
    if (best === -1) continue;
    // boîte calculée sur les pixels FRANCS (alpha ≥ 100) : des chaînes de
    // pixels fantômes quasi transparents ne peuvent plus étirer la frame
    let minX = w, minY = h, maxX = -1, maxY = -1;
    for (let i = 0; i < w * h; i++) {
      if (px[i * 4 + 3] <= 8) continue;
      if (label[i] !== best) {
        px[i * 4 + 3] = 0; // fragments parasites effacés
        continue;
      }
      if (px[i * 4 + 3] < 100) continue;
      const ix = i % w;
      const iy = (i - ix) / w;
      if (ix < minX) minX = ix;
      if (ix > maxX) maxX = ix;
      if (iy < minY) minY = iy;
      if (iy > maxY) maxY = iy;
    }
    if (maxX < 0) continue;
    ctx.putImageData(id, 0, 0);
    frames.push({ c, bx: minX, by: minY, bw: maxX - minX + 1, bh: maxY - minY + 1 });
  }

  if (!frames.length) return 0;
  // normalisation par la MÉDIANE des hauteurs : une cellule anormale
  // (personnage plus petit, résidu) ne rétrécit plus toute la planche
  const sorted = frames.map(f => f.bh).sort((a, b) => a - b);
  const medianH = sorted[Math.floor(sorted.length / 2)];
  const scale = targetH / medianH;
  frames.forEach((f, i) => {
    let cur = document.createElement('canvas');
    cur.width = f.bw;
    cur.height = f.bh;
    cur.getContext('2d')!.drawImage(f.c, f.bx, f.by, f.bw, f.bh, 0, 0, f.bw, f.bh);
    let s = scale;
    while (s <= 0.5) {
      const half = document.createElement('canvas');
      half.width = Math.max(1, Math.round(cur.width / 2));
      half.height = Math.max(1, Math.round(cur.height / 2));
      const hc = half.getContext('2d')!;
      hc.imageSmoothingQuality = 'high';
      hc.drawImage(cur, 0, 0, half.width, half.height);
      cur = half;
      s *= 2;
    }
    const out = document.createElement('canvas');
    out.width = Math.max(1, Math.round(cur.width * s));
    out.height = Math.max(1, Math.round(cur.height * s));
    const oc = out.getContext('2d')!;
    oc.imageSmoothingQuality = 'high';
    oc.drawImage(cur, 0, 0, out.width, out.height);
    scene.textures.addCanvas(`${prefix}-${i}`, out);
  });
  return frames.length;
}

// Ombre douce réutilisable (dégradé radial — aucun asset requis, invisible en tant que « forme »)
export function addSoftShadowTexture(scene: Phaser.Scene, key = 'soft-shadow') {
  const w = 128;
  const h = 48;
  const canvas = document.createElement('canvas');
  canvas.width = w;
  canvas.height = h;
  const ctx = canvas.getContext('2d')!;
  const g = ctx.createRadialGradient(w / 2, h / 2, 4, w / 2, h / 2, w / 2);
  g.addColorStop(0, 'rgba(20,16,10,0.42)');
  g.addColorStop(0.6, 'rgba(20,16,10,0.18)');
  g.addColorStop(1, 'rgba(20,16,10,0)');
  ctx.fillStyle = g;
  ctx.save();
  ctx.scale(1, h / w);
  ctx.beginPath();
  ctx.arc(w / 2, (h / 2) * (w / h), w / 2, 0, Math.PI * 2);
  ctx.fill();
  ctx.restore();
  scene.textures.addCanvas(key, canvas);
}

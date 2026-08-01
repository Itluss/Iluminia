import Phaser from 'phaser';

// Halo lumineux doux (lucioles, étincelles, poussières).
export function addGlowTexture(scene: Phaser.Scene, key: string, size: number, rgb: string) {
  const c = document.createElement('canvas');
  c.width = size;
  c.height = size;
  const ctx = c.getContext('2d')!;
  const g = ctx.createRadialGradient(size / 2, size / 2, 1, size / 2, size / 2, size / 2);
  g.addColorStop(0, `rgba(${rgb},0.9)`);
  g.addColorStop(0.4, `rgba(${rgb},0.35)`);
  g.addColorStop(1, `rgba(${rgb},0)`);
  ctx.fillStyle = g;
  ctx.fillRect(0, 0, size, size);
  scene.textures.addCanvas(key, c);
}

// Traînée horizontale douce (reflets sur l'eau).
export function addStreakTexture(scene: Phaser.Scene, key: string) {
  const w = 96;
  const h = 14;
  const c = document.createElement('canvas');
  c.width = w;
  c.height = h;
  const ctx = c.getContext('2d')!;
  const g = ctx.createRadialGradient(w / 2, h / 2, 1, w / 2, h / 2, w / 2);
  g.addColorStop(0, 'rgba(255,255,255,0.75)');
  g.addColorStop(1, 'rgba(255,255,255,0)');
  ctx.save();
  ctx.scale(1, h / w);
  ctx.fillStyle = g;
  ctx.beginPath();
  ctx.arc(w / 2, (h / 2) * (w / h), w / 2, 0, Math.PI * 2);
  ctx.fill();
  ctx.restore();
  scene.textures.addCanvas(key, c);
}

// Copie une région d'une texture en la réduisant (pour les NineSlice d'UI :
// les bords sculptés doivent rester plus fins que la hauteur d'affichage).
export function addScaledRegionTexture(
  scene: Phaser.Scene,
  srcKey: string,
  outKey: string,
  x: number,
  y: number,
  w: number,
  h: number,
  scale: number,
) {
  const source = scene.textures.get(srcKey).getSourceImage() as HTMLImageElement;
  const c = document.createElement('canvas');
  c.width = Math.round(w * scale);
  c.height = Math.round(h * scale);
  const ctx = c.getContext('2d')!;
  ctx.imageSmoothingQuality = 'high';
  ctx.drawImage(source, x, y, w, h, 0, 0, c.width, c.height);
  scene.textures.addCanvas(outKey, c);
}

// Réduction propre par moitiés successives. Nos textures ne sont pas des
// puissances de deux : WebGL ne peut pas générer de mipmaps, et réduire ~20×
// d'un coup recrée du crénelage (rendu « pixelisé »). On divise par 2 jusqu'à
// approcher la hauteur cible, puis on ajuste exactement.
export function downscaleTexture(scene: Phaser.Scene, srcKey: string, outKey: string, targetH: number) {
  let src: CanvasImageSource & { width: number; height: number } = scene.textures
    .get(srcKey)
    .getSourceImage() as HTMLCanvasElement;
  let w = src.width;
  let h = src.height;
  while (h / 2 >= targetH) {
    const half = document.createElement('canvas');
    half.width = Math.max(1, Math.round(w / 2));
    half.height = Math.max(1, Math.round(h / 2));
    const hctx = half.getContext('2d')!;
    hctx.imageSmoothingQuality = 'high';
    hctx.drawImage(src, 0, 0, half.width, half.height);
    src = half;
    w = half.width;
    h = half.height;
  }
  const c = document.createElement('canvas');
  c.width = Math.max(1, Math.round((w * targetH) / h));
  c.height = targetH;
  const ctx = c.getContext('2d')!;
  ctx.imageSmoothingQuality = 'high';
  ctx.drawImage(src, 0, 0, c.width, c.height);
  scene.textures.addCanvas(outKey, c);
}

// Rogne les marges transparentes d'une texture (après détourage) puis la
// réduit proprement : la taille affichée devient prévisible, sans marges mortes.
export function trimAndDownscaleTexture(scene: Phaser.Scene, srcKey: string, outKey: string, targetH: number) {
  const src = scene.textures.get(srcKey).getSourceImage() as HTMLCanvasElement;
  const w = src.width;
  const h = src.height;
  const c = document.createElement('canvas');
  c.width = w;
  c.height = h;
  const ctx = c.getContext('2d')!;
  ctx.drawImage(src, 0, 0);
  const data = ctx.getImageData(0, 0, w, h).data;
  let minX = w, minY = h, maxX = -1, maxY = -1;
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      if (data[(y * w + x) * 4 + 3] > 8) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }
  if (maxX < 0) return; // texture vide : ne rien créer
  const pad = 2;
  minX = Math.max(0, minX - pad);
  minY = Math.max(0, minY - pad);
  const tw = Math.min(w, maxX + pad + 1) - minX;
  const th = Math.min(h, maxY + pad + 1) - minY;
  const trimmed = document.createElement('canvas');
  trimmed.width = tw;
  trimmed.height = th;
  trimmed.getContext('2d')!.drawImage(c, minX, minY, tw, th, 0, 0, tw, th);
  const tmpKey = `${outKey}-trim-tmp`;
  scene.textures.addCanvas(tmpKey, trimmed);
  downscaleTexture(scene, tmpKey, outKey, targetH);
  scene.textures.remove(tmpKey);
}

// Nettoie un PNG « transparent » dont le fond est en réalité un halo
// semi-transparent (défaut récurrent des générations) : tout pixel sous le
// seuil d'alpha devient totalement transparent, puis réduction propre.
export function addAlphaCutTexture(
  scene: Phaser.Scene,
  srcKey: string,
  outKey: string,
  minAlpha: number,
  targetH: number,
) {
  const source = scene.textures.get(srcKey).getSourceImage() as HTMLImageElement;
  const c = document.createElement('canvas');
  c.width = source.width;
  c.height = source.height;
  const ctx = c.getContext('2d')!;
  ctx.drawImage(source, 0, 0);
  const id = ctx.getImageData(0, 0, c.width, c.height);
  const px = id.data;
  for (let i = 3; i < px.length; i += 4) {
    if (px[i] < minAlpha) px[i] = 0;
  }
  ctx.putImageData(id, 0, 0);
  const tmpKey = `${outKey}-cut-tmp`;
  scene.textures.addCanvas(tmpKey, c);
  downscaleTexture(scene, tmpKey, outKey, targetH);
  scene.textures.remove(tmpKey);
}

// Région du décor masquée en rectangle arrondi (capsule) : pour l'occlusion,
// un rectangle nu emporte le sol autour de l'objet — on le voit dès qu'un
// personnage passe derrière. Le masque garde l'objet, adoucit les coins.
export function addMaskedRegionTexture(
  scene: Phaser.Scene,
  srcKey: string,
  outKey: string,
  x: number,
  y: number,
  w: number,
  h: number,
  radius: number,
) {
  const source = scene.textures.get(srcKey).getSourceImage() as HTMLImageElement;
  const c = document.createElement('canvas');
  c.width = w;
  c.height = h;
  const ctx = c.getContext('2d')!;
  ctx.drawImage(source, x, y, w, h, 0, 0, w, h);
  ctx.globalCompositeOperation = 'destination-in';
  ctx.beginPath();
  ctx.roundRect(0, 0, w, h, radius);
  ctx.fill();
  scene.textures.addCanvas(outKey, c);
}

// Copie une région d'une texture existante (permet l'occlusion : le héros
// passe DERRIÈRE des morceaux du décor, découpés depuis l'illustration même).
export function addRegionTexture(
  scene: Phaser.Scene,
  srcKey: string,
  outKey: string,
  x: number,
  y: number,
  w: number,
  h: number,
) {
  const source = scene.textures.get(srcKey).getSourceImage() as HTMLImageElement;
  const c = document.createElement('canvas');
  c.width = w;
  c.height = h;
  const ctx = c.getContext('2d')!;
  ctx.drawImage(source, x, y, w, h, 0, 0, w, h);
  scene.textures.addCanvas(outKey, c);
}

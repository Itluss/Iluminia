import Phaser from 'phaser';
import { downscaleTexture } from '../utils/textures';

// Les pièces du héros modulaire sont des découpes du master (jusqu'à ~900 px
// de haut) affichées minuscules en jeu (~30-60 px) : sans réduction propre
// au préalable, la minification WebGL (pas de mipmaps sur nos tailles) les
// rend crénelées/pixelisées (même défaut que documenté dans BootScene pour
// l'ancien sprite). On les réduit à ~28 % — assez pour rester net dans le
// Lab en ×4,2 tout en évitant l'aliasing en jeu — puis on compense le
// `scale` du rig pour que l'assemblage reste identique au pixel près.
const DOWNSCALE_RATIO = 0.28;

interface ManifestPart {
  id: string;
  filename: string;
  status: string;
}

/** Charge (si nécessaire) les pièces approuvées du héros, les réduit
 *  proprement, compense les échelles du rig, puis appelle `onReady`.
 *  Idempotent : si les textures existent déjà (scène précédente dans la même
 *  session), n'effectue aucun rechargement ni recalcul de rig. */
export function loadHeroParts(
  scene: Phaser.Scene,
  manifest: { parts: ManifestPart[] },
  rigData: { slots: Array<{ part: string; scale: number }> },
  onReady: () => void,
) {
  const toLoad = manifest.parts.filter(
    p => p.status === 'approved' && !scene.textures.exists(`char-hero-${p.id}`),
  );
  if (toLoad.length === 0) {
    onReady();
    return;
  }
  for (const p of toLoad) {
    scene.load.image(`char-hero-${p.id}-src`, `art/characters/hero/${p.filename}`);
  }
  scene.load.once(Phaser.Loader.Events.COMPLETE, () => {
    for (const p of toLoad) {
      const srcKey = `char-hero-${p.id}-src`;
      const raw = scene.textures.get(srcKey).getSourceImage() as HTMLImageElement;
      const targetH = Math.max(1, Math.round(raw.height * DOWNSCALE_RATIO));
      downscaleTexture(scene, srcKey, `char-hero-${p.id}`, targetH);
      scene.textures.remove(srcKey);
      const actualRatio = targetH / raw.height;
      const slot = rigData.slots.find(s => s.part === p.id);
      if (slot) slot.scale = slot.scale / actualRatio;
    }
    onReady();
  });
  scene.load.start();
}

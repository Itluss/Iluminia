import Phaser from 'phaser';
import { addRegionTexture } from '../utils/textures';
import { addKeyedRegionTexture } from '../utils/keying';

// ============================================================
// Sprint 01 — le décor prend vie.
// Découpes validées sur planche de contrôle (scripts/art-qa/).
// Positions monde calées sur le décor diorama 2528×1696 (natif ×1).
// ============================================================

const FX = 'art/eluminia_sprint01_environment_fx';

export function preloadEnvironment(load: Phaser.Loader.LoaderPlugin) {
  load.image('fx-ripple', `${FX}/fx/water-ripple-strip.png`);
  load.image('fx-splash', `${FX}/fx/fountain-splash-strip.png`);
  load.image('fx-rays', `${FX}/fx/god-rays.png`);
  load.image('fx-caustics', `${FX}/fx/water-caustics.png`);
  load.image('fx-fparts', `${FX}/fx/fountain-particles.png`);
  load.image('fx-leaf', `${FX}/fx/leaf-particles.png`);
  load.image('fx-petal', `${FX}/fx/petal-particles.png`);
  load.image('fx-fireflies', `${FX}/fx/fireflies.png`);
  load.image('fx-ambient', `${FX}/fx/ambient-light-overlay.png`);
  load.image('fx-darken', `${FX}/fx/darken-overlay.png`);
  load.image('fx-bannerwave', `${FX}/fx/banner-wave-strip.png`);
  load.image('fx-magic', `${FX}/fx/magic-sparkles.png`);
  load.image('env-flowers', `${FX}/environment/flowers-grass.png`);
  load.image('env-ground', `${FX}/environment/ground-details.png`);
  load.image('env-fallen', `${FX}/environment/fallen-leaves.png`);
  load.image('ui2-btnxp', `${FX}/ui/button-background.png`);
  load.image('ui2-panel', `${FX}/ui/dialogue-panel.png`);
  load.image('ui2-bag', `${FX}/ui/quest-icon.png`);   // noms inversés par le générateur :
  load.image('ui2-quest', `${FX}/ui/xp-icon.png`);    // quest-icon = sac, xp-icon = quête
}

/** Découpes validées sur planche de contrôle. */
export function registerEnvironmentTextures(scene: Phaser.Scene) {
  // — séquences additives (fond noir → fusion ADD, pas de détourage)
  [6, 75, 144, 213, 282, 351, 420].forEach((x, i) => addRegionTexture(scene, 'fx-ripple', `ripple-${i}`, x, 5, 58, 48));
  [7, 77, 147, 217, 287, 357, 427].forEach((x, i) => addRegionTexture(scene, 'fx-splash', `splash-${i}`, x, 5, 56, 55));
  [3, 77, 151, 225, 299, 373, 447].forEach((x, i) => addRegionTexture(scene, 'fx-rays', `rays-${i}`, x, 4, 68, 122));
  addRegionTexture(scene, 'fx-caustics', 'caustics', 10, 8, 240, 96);
  addRegionTexture(scene, 'fx-fparts', 'droplet', 14, 4, 30, 38);
  addRegionTexture(scene, 'fx-fparts', 'glint', 12, 72, 34, 34);
  addRegionTexture(scene, 'fx-ambient', 'ambient', 12, 8, 346, 112);
  addRegionTexture(scene, 'fx-darken', 'vignette', 10, 8, 250, 112);
  addRegionTexture(scene, 'fx-magic', 'magic-circle', 28, 66, 134, 120);

  // — éléments détourés (fond sombre à vignette → tolérance 72)
  [[6, 0, 58, 104], [76, 2, 56, 100], [140, 0, 60, 104], [208, 0, 60, 104]].forEach(([x, y, w, h], i) =>
    addKeyedRegionTexture(scene, 'fx-bannerwave', `banner-${i}`, x, y, w, h, 72),
  );
  [[14, 30, 84, 66], [98, 32, 70, 64], [170, 30, 78, 66], [248, 32, 72, 64], [292, 98, 46, 52]].forEach(
    ([x, y, w, h], i) => addKeyedRegionTexture(scene, 'env-flowers', `clump-${i}`, x, y, w, h, 72),
  );
  [[12, 6, 40, 38], [58, 10, 46, 34], [114, 10, 42, 36], [154, 12, 48, 32], [214, 14, 48, 30], [286, 2, 48, 44]].forEach(
    ([x, y, w, h], i) => addKeyedRegionTexture(scene, 'env-ground', `gdetail-${i}`, x, y, w, h, 72),
  );
  [[8, 46, 32, 30], [54, 32, 52, 36], [10, 86, 36, 30]].forEach(([x, y, w, h], i) =>
    addKeyedRegionTexture(scene, 'env-fallen', `fallen-${i}`, x, y, w, h, 72),
  );
  [[14, 16, 26, 22], [58, 58, 26, 20], [108, 26, 22, 20]].forEach(([x, y, w, h], i) =>
    addKeyedRegionTexture(scene, 'fx-leaf', `leaf-${i}`, x, y, w, h, 72),
  );
  [[8, 12, 26, 22], [34, 54, 22, 20]].forEach(([x, y, w, h], i) =>
    addKeyedRegionTexture(scene, 'fx-petal', `petal-${i}`, x, y, w, h, 72),
  );
  addKeyedRegionTexture(scene, 'fx-fireflies', 'butterfly', 100, 56, 76, 86, 60);

  // — interface (contenu ≠ nom de fichier, mapping validé visuellement)
  addKeyedRegionTexture(scene, 'ui2-btnxp', 'button2', 6, 32, 138, 56, 60);
  addKeyedRegionTexture(scene, 'ui2-btnxp', 'icon-xp2', 134, 24, 80, 76, 60);
  addKeyedRegionTexture(scene, 'ui2-quest', 'icon-quest2', 6, 18, 88, 92, 60);
  addKeyedRegionTexture(scene, 'ui2-bag', 'icon-bag2', 10, 20, 80, 92, 60);
  addKeyedRegionTexture(scene, 'ui2-panel', 'panel2', 2, 10, 332, 78, 60);
  addKeyedRegionTexture(scene, 'ui2-panel', 'dlg-arrow', 336, 26, 46, 42, 60);
}

/** Un sprite qui joue une séquence de textures en boucle, sans coupure brutale. */
function cycler(
  scene: Phaser.Scene,
  x: number,
  y: number,
  prefix: string,
  frames: number,
  ms: number,
  opts: { scale?: number; alpha?: number; depth?: number; blend?: Phaser.BlendModes; yoyo?: boolean } = {},
) {
  const img = scene.add
    .image(x, y, `${prefix}-0`)
    .setScale(opts.scale ?? 1)
    .setAlpha(opts.alpha ?? 1)
    .setDepth(opts.depth ?? 5)
    .setBlendMode(opts.blend ?? Phaser.BlendModes.NORMAL);
  let i = 0;
  let dir = 1;
  scene.time.addEvent({
    delay: ms,
    loop: true,
    callback: () => {
      if (opts.yoyo) {
        i += dir;
        if (i >= frames - 1 || i <= 0) dir *= -1;
      } else {
        i = (i + 1) % frames;
      }
      img.setTexture(`${prefix}-${i}`);
      if (!opts.yoyo) img.setAlpha((opts.alpha ?? 1) * (i === 0 ? 0.35 : i === frames - 1 ? 0.75 : 1));
    },
  });
  return img;
}

/** Construit toute la vie du décor. Coordonnées : pixels du décor diorama 2528×1696. */
export function buildEnvironmentFx(scene: Phaser.Scene) {
  // ---------- EAU ----------
  cycler(scene, 300, 1460, 'ripple', 7, 130, { scale: 1.1, alpha: 0.5, depth: 4, blend: Phaser.BlendModes.ADD });
  cycler(scene, 2130, 1510, 'ripple', 7, 150, { scale: 0.9, alpha: 0.4, depth: 4, blend: Phaser.BlendModes.ADD });
  // alpha réduit : sur l'orbe clair du décor diorama, le fond de la planche
  // splash (pas tout à fait noir) devient une boîte visible au-delà de ~0,6
  cycler(scene, 1471, 962, 'splash', 7, 105, { scale: 0.95, alpha: 0.5, depth: 1111, blend: Phaser.BlendModes.ADD });

  for (const [x, y, w, h, dur] of [[90, 1350, 380, 300, 9000], [1830, 60, 200, 250, 7000]] as const) {
    const t = scene.add.tileSprite(x, y, w, h, 'caustics').setOrigin(0);
    t.setAlpha(0.13).setDepth(3).setBlendMode(Phaser.BlendModes.SCREEN);
    scene.tweens.add({ targets: t, tilePositionX: 60, tilePositionY: 24, duration: dur, yoyo: true, repeat: -1, ease: 'Sine.inOut' });
  }

  const droplets = Array.from({ length: 6 }, () =>
    scene.add.image(0, 0, 'droplet').setVisible(false).setDepth(1111).setBlendMode(Phaser.BlendModes.ADD),
  );
  let dropIdx = 0;
  scene.time.addEvent({
    delay: 200,
    loop: true,
    callback: () => {
      const d = droplets[dropIdx++ % droplets.length];
      const x0 = 1471 + Phaser.Math.Between(-10, 10);
      d.setPosition(x0, 975).setVisible(true).setAlpha(0.9).setScale(Phaser.Math.FloatBetween(0.35, 0.6));
      scene.tweens.add({
        targets: d,
        x: x0 + Phaser.Math.Between(-34, 34),
        y: 1075,
        alpha: 0,
        duration: Phaser.Math.Between(550, 750),
        ease: 'Quad.in',
        onComplete: () => d.setVisible(false),
      });
    },
  });

  const glints = Array.from({ length: 4 }, () =>
    scene.add.image(0, 0, 'glint').setVisible(false).setDepth(1111).setBlendMode(Phaser.BlendModes.ADD),
  );
  let glintIdx = 0;
  scene.time.addEvent({
    delay: 640,
    loop: true,
    callback: () => {
      const g = glints[glintIdx++ % glints.length];
      g.setPosition(1471 + Phaser.Math.Between(-90, 90), 1090 + Phaser.Math.Between(-12, 14));
      g.setVisible(true).setAlpha(0).setScale(0.2).clearTint();
      scene.tweens.add({
        targets: g,
        alpha: { from: 0, to: 0.75 },
        scale: 0.5,
        duration: 260,
        yoyo: true,
        ease: 'Sine.out',
        onComplete: () => g.setVisible(false),
      });
    },
  });

  // le cercle magique animé se superpose au cercle PEINT du décor (eau, bas-droite)
  const circle = scene.add
    .image(2310, 1537, 'magic-circle')
    .setDepth(4)
    .setBlendMode(Phaser.BlendModes.ADD)
    .setAlpha(0.16)
    .setScale(1.7, 0.9);
  scene.tweens.add({ targets: circle, alpha: 0.2, duration: 2600, yoyo: true, repeat: -1, ease: 'Sine.inOut' });
  scene.tweens.add({ targets: circle, rotation: Math.PI * 2, duration: 26000, repeat: -1 });

  // étincelles bleues : glint teinté (l'asset dédié était trop diffus)
  const sparks = Array.from({ length: 3 }, () =>
    scene.add.image(0, 0, 'glint').setVisible(false).setDepth(1000).setBlendMode(Phaser.BlendModes.ADD).setTint(0x7ad4ff),
  );
  let sparkIdx = 0;
  scene.time.addEvent({
    delay: 1100,
    loop: true,
    callback: () => {
      const s = sparks[sparkIdx++ % sparks.length];
      s.setPosition(2310 + Phaser.Math.Between(-100, 100), 1530 + Phaser.Math.Between(-18, 16));
      s.setVisible(true).setAlpha(0).setScale(0.25).setAngle(Phaser.Math.Between(0, 90));
      scene.tweens.add({
        targets: s,
        alpha: { from: 0, to: 0.7 },
        scale: 0.5,
        angle: s.angle + 40,
        duration: 340,
        yoyo: true,
        ease: 'Sine.out',
        onComplete: () => s.setVisible(false),
      });
    },
  });

  // ---------- VÉGÉTATION ----------
  const decor: Array<[string, number, number, number]> = [
    ['clump-0', 560, 870, 0.95], ['clump-1', 860, 620, 0.9], ['clump-2', 1560, 700, 0.95],
    ['clump-3', 1850, 990, 0.9], ['clump-4', 700, 1230, 0.95], ['clump-1', 1660, 1240, 0.9],
    ['clump-3', 500, 800, 0.85], ['clump-0', 2140, 1010, 0.9],
    ['gdetail-0', 960, 950, 1], ['gdetail-2', 1420, 900, 1], ['gdetail-5', 780, 760, 1],
    ['gdetail-1', 1760, 950, 1], ['gdetail-3', 1240, 1270, 1], ['gdetail-4', 560, 750, 0.9],
    ['fallen-0', 450, 845, 1], ['fallen-1', 1890, 720, 1], ['fallen-2', 820, 1260, 0.9], ['fallen-1', 1470, 610, 0.9],
  ];
  for (const [key, x, y, s] of decor) {
    scene.add.image(x, y, key).setScale(s).setDepth(y).setOrigin(0.5, 1);
  }

  const leaves = Array.from({ length: 4 }, (_, i) =>
    scene.add.image(0, 0, `leaf-${i % 3}`).setVisible(false).setDepth(930),
  );
  let leafIdx = 0;
  scene.time.addEvent({
    delay: 3200,
    loop: true,
    callback: () => {
      const l = leaves[leafIdx++ % leaves.length];
      const x0 = Math.random() < 0.5 ? Phaser.Math.Between(450, 820) : Phaser.Math.Between(1700, 2240);
      l.setPosition(x0, Phaser.Math.Between(500, 620)).setVisible(true).setAlpha(0.95).setScale(0.9);
      const dur = Phaser.Math.Between(3400, 4600);
      scene.tweens.add({ targets: l, y: l.y + 300, alpha: 0, duration: dur, ease: 'Sine.in', onComplete: () => l.setVisible(false) });
      scene.tweens.add({ targets: l, x: x0 + 40, duration: dur / 3, yoyo: true, repeat: 2, ease: 'Sine.inOut' });
      scene.tweens.add({ targets: l, angle: Phaser.Math.Between(120, 240), duration: dur, ease: 'Sine.inOut' });
    },
  });

  const petals = Array.from({ length: 3 }, (_, i) =>
    scene.add.image(0, 0, `petal-${i % 2}`).setVisible(false).setDepth(930),
  );
  let petalIdx = 0;
  scene.time.addEvent({
    delay: 5200,
    loop: true,
    callback: () => {
      const p = petals[petalIdx++ % petals.length];
      const x0 = Phaser.Math.Between(900, 1450);
      p.setPosition(x0, Phaser.Math.Between(520, 640)).setVisible(true).setAlpha(0.9).setScale(0.85);
      const dur = Phaser.Math.Between(4200, 5400);
      scene.tweens.add({ targets: p, y: p.y + 280, alpha: 0, duration: dur, ease: 'Sine.in', onComplete: () => p.setVisible(false) });
      scene.tweens.add({ targets: p, x: x0 + 60, duration: dur / 2, yoyo: true, repeat: 1, ease: 'Sine.inOut' });
      scene.tweens.add({ targets: p, angle: 200, duration: dur });
    },
  });

  const butterfly = scene.add.image(860, 610, 'butterfly').setScale(0.5).setDepth(935);
  scene.tweens.add({ targets: butterfly, scaleX: 0.28, duration: 130, yoyo: true, repeat: -1, ease: 'Sine.inOut' });
  const flowerSpots: Array<[number, number]> = [
    [560, 865], [860, 615], [1560, 695], [1850, 985], [700, 1225], [2140, 1005],
  ];
  const flyNext = () => {
    const [tx, ty] = flowerSpots[Phaser.Math.Between(0, flowerSpots.length - 1)];
    scene.tweens.add({
      targets: butterfly,
      x: tx + Phaser.Math.Between(-14, 14),
      y: ty - Phaser.Math.Between(16, 40),
      duration: Phaser.Math.Between(3600, 5200),
      ease: 'Sine.inOut',
      onComplete: () => scene.time.delayedCall(Phaser.Math.Between(800, 2200), flyNext),
    });
  };
  flyNext();

  // (bannières animées supprimées : l'alternance de poses générées était
  //  saccadée et se superposait mal aux bannières peintes du décor HD —
  //  les bannières peintes, immobiles, sont plus justes)

  // ---------- LUMIÈRE ----------
  // Vignette MULTIPLY et voile ambiant SCREEN SUPPRIMÉS : ils rendaient tout
  // le rendu terne et olive (le décor HD est vif par lui-même — on ne le
  // salit plus avec des voiles plein écran). Seul un rai de lumière discret
  // et localisé subsiste, près de la fontaine.
  // depth > occlusion fontaine (1110) : sinon la découpe bloque la lumière
  // additive et son pourtour apparaît comme une couture rectangulaire
  const rays = cycler(scene, 1450, 940, 'rays', 7, 320, { alpha: 0.07, depth: 1150, blend: Phaser.BlendModes.ADD });
  rays.setDisplaySize(560, 470);
  scene.tweens.add({ targets: rays, alpha: 0.11, duration: 5200, yoyo: true, repeat: -1, ease: 'Sine.inOut' });

  // lucioles : glint doré, petit
  const ffSpots: Array<[number, number]> = [
    [500, 950], [820, 830], [1380, 900], [1800, 950], [680, 1260], [1560, 1250], [440, 760], [2050, 1060],
  ];
  ffSpots.forEach(([x, y], i) => {
    const m = scene.add.image(x, y, 'glint').setBlendMode(Phaser.BlendModes.ADD).setDepth(950).setTint(0xffd27a);
    m.setScale(0.28 + (i % 3) * 0.08).setAlpha(0);
    scene.tweens.add({ targets: m, alpha: 0.55, duration: 1200 + i * 160, yoyo: true, repeat: -1, ease: 'Sine.inOut', delay: i * 300 });
    scene.tweens.add({ targets: m, x: x + 26 + (i % 4) * 8, duration: 2600 + i * 340, yoyo: true, repeat: -1, ease: 'Sine.inOut' });
    scene.tweens.add({ targets: m, y: y - 18 - (i % 3) * 7, duration: 2100 + i * 270, yoyo: true, repeat: -1, ease: 'Sine.inOut', delay: 150 * i });
  });
}

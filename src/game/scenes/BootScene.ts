import Phaser from 'phaser';
import { addKeyedTexture, addKeyedRegionTexture, addSoftShadowTexture, addAnimSet } from '../utils/keying';
import {
  addScaledRegionTexture,
  addRegionTexture,
  downscaleTexture,
  addAlphaCutTexture,
  trimAndDownscaleTexture,
} from '../utils/textures';
import { preloadEnvironment, registerEnvironmentTextures } from '../fx/environment';

const ART = 'art/eluminia_poc_assets';

// Charge les assets définitifs puis prépare les versions détourées.
export class BootScene extends Phaser.Scene {
  constructor() {
    super('boot');
  }

  preload() {
    // monde ouvert : une seule image continue (Banana, 2544×3792, affichée ×1)
    this.load.image('village', 'art/generated/village-world.png');
    // personnages HD peints v2 — poses vivantes, lumière dorée du village
    // (Banana, fond gris uni détouré à l'exécution)
    this.load.image('hero-src', 'art/generated/hero-hd2.png');
    this.load.image('lina-src', 'art/generated/lina-hd2.png');
    this.load.image('hero-walk-src', 'art/generated/hero-walk-hd2.png');
    // planches du cycle de marche (Banana : profil 6, face 8, dos 6)
    // profil : cycle de course extrait d'une vidéo I2V (Tencent HY Video 1.5,
    // 2026-07-31) — 8 frames propres, bien plus fluides que l'ancienne
    // planche générée image par image (voir scripts/art-qa/extract-video-frames.mjs).
    this.load.image('walk-side-sheet', 'art/generated/hero-walk-side-i2v-sheet.png');
    this.load.image('walk-front-sheet', 'art/generated/hero-walk-front-sheet.png');
    this.load.image('walk-back-sheet', 'art/generated/hero-walk-back-sheet.png');
    this.load.image('portrait-src', `${ART}/portraits/lina-portrait.png`);
    this.load.image('panel-src', `${ART}/ui/dialogue-panel.png`);
    this.load.image('button-src', `${ART}/ui/button-green.png`);
    this.load.image('plank-src', `${ART}/ui/enchanted-plank.png`);
    this.load.image('inventory-src', `${ART}/ui/inventory-icon.png`);
    this.load.image('quest-src', `${ART}/ui/quest-icon.png`);
    this.load.image('xp-src', `${ART}/ui/xp-icon.png`);
    this.load.image('fox', 'art/generated/renard-magique.png'); // alpha natif, pas de détourage
    this.load.image('ui-plaque-src', 'art/generated/ui-plaque.png'); // bois d'UI générés (alpha natif)
    this.load.image('ui-frame', 'art/generated/ui-frame-map-cut.png');
    this.load.image('ui-board', 'art/image1.png'); // planche interface (portrait, icônes, monnaies)
    this.load.image('icon-exclaim-src', 'art/generated/icon-exclaim.png'); // marqueur de quête (halo à nettoyer)
    // manifeste + rig du héros modulaire (Character Lab / futur composant)
    this.load.json('hero-manifest', 'art/characters/hero/character.manifest.json');
    this.load.json('hero-rig', 'art/characters/hero/rig/hero.rig.json');
    this.load.image('icon-coin2-src', 'art/generated/icon-coin-hd.png');   // monnaies HD (alpha natif)
    this.load.image('icon-gem2-src', 'art/generated/icon-gem-hd.png');
    this.load.image('icon-star2-src', 'art/generated/icon-star-hd.png');
    // interface style parchemin/or (assets Camille retravaillés Banana,
    // fond magenta détouré à l'exécution)
    this.load.image('ui-title-src', 'art/generated/ui-title-deco-mg.png');
    this.load.image('ui-xpbar-src', 'art/generated/ui-xpbar-v2.png');
    this.load.image('ui-quests-src', 'art/generated/ui-icon-quests-hd.png');
    this.load.image('ui-pack-src', 'art/generated/ui-icon-pack-hd.png');
    this.load.image('ui-map-src', 'art/generated/ui-icon-map-hd.png');
    preloadEnvironment(this.load);
  }

  create() {
    // tolérance large pour les personnages : leur contour encré protège l'intérieur,
    // et les fonds générés contiennent parfois un damier clair de « fausse transparence »
    // détourage plein format puis réduction par moitiés vers ~2× la taille
    // d'affichage : sans cette étape, la réduction ~20× de WebGL (pas de
    // mipmaps sur nos tailles) recrée un rendu crénelé/« pixelisé »
    addKeyedTexture(this, 'hero-src', 'hero-full', 62);
    downscaleTexture(this, 'hero-full', 'hero', 240);
    this.textures.remove('hero-full');
    addKeyedTexture(this, 'lina-src', 'lina-full', 62);
    downscaleTexture(this, 'lina-full', 'lina', 230);
    this.textures.remove('lina-full');
    addKeyedTexture(this, 'hero-walk-src', 'hero-walk-full', 62);
    downscaleTexture(this, 'hero-walk-full', 'hero-walk', 240);
    this.textures.remove('hero-walk-full');
    // cycles de marche : cellules généreuses, la plus grande composante
    // connexe isole le personnage (lignes de cadre et voisins éliminés)
    addAnimSet(this, 'walk-side-sheet', 'walk-side', [
      [0, 0, 784, 1168], [784, 0, 784, 1168], [1568, 0, 784, 1168], [2352, 0, 784, 1168],
      [0, 1168, 784, 1168], [784, 1168, 784, 1168], [1568, 1168, 784, 1168], [2352, 1168, 784, 1168],
    ], 45, 240);
    addAnimSet(this, 'walk-front-sheet', 'walk-front', [
      [80, 90, 520, 760], [700, 90, 520, 760], [1350, 90, 510, 760], [1980, 90, 490, 760],
      [80, 900, 520, 770], [700, 900, 520, 770], [1350, 900, 510, 770], [1980, 900, 490, 770],
    ], 62, 240);
    addAnimSet(this, 'walk-back-sheet', 'walk-back', [
      [10, 430, 494, 1260], [504, 430, 366, 1260], [870, 430, 396, 1260],
      [1266, 430, 350, 1260], [1616, 430, 381, 1260], [1997, 430, 520, 1260],
    ], 62, 240);
    // marqueur de quête + monnaies : halo éventuel supprimé + réduction propre
    addAlphaCutTexture(this, 'icon-exclaim-src', 'icon-exclaim', 215, 96);
    addAlphaCutTexture(this, 'icon-coin2-src', 'icon-coin2', 215, 96);
    addAlphaCutTexture(this, 'icon-gem2-src', 'icon-gem2', 215, 96);
    addAlphaCutTexture(this, 'icon-star2-src', 'icon-star2', 215, 96);
    // plaque de titre (lettrage peint) : fond magenta, découpe au-dessus du
    // dégradé parasite du bas de canevas, détourage large (magenta ≠ tout)
    // tolérance 140 : mange les pixels de transition rosés (la palette
    // parchemin/or/bleu est à distance > 240 du magenta, aucun risque)
    addKeyedRegionTexture(this, 'ui-title-src', 'ui-title-keyed', 0, 0, 2528, 1300, 140);
    trimAndDownscaleTexture(this, 'ui-title-keyed', 'ui-sign', 150);
    this.textures.remove('ui-title-keyed');
    // barre de statut : découpe FIXE (pas de rognage) pour garder des
    // coordonnées déterministes — les valeurs dynamiques (niveau, XP,
    // monnaies) sont écrites par le moteur aux emplacements mesurés
    addKeyedRegionTexture(this, 'ui-xpbar-src', 'ui-xpbar-keyed', 140, 660, 2280, 380, 140);
    downscaleTexture(this, 'ui-xpbar-keyed', 'ui-xpbar', 160);
    this.textures.remove('ui-xpbar-keyed');
    for (const [src, out] of [
      ['ui-quests-src', 'icon-scroll2'],
      ['ui-pack-src', 'icon-pack2'],
      ['ui-map-src', 'icon-map2'],
    ] as const) {
      addKeyedTexture(this, src, `${out}-keyed`, 40);
      trimAndDownscaleTexture(this, `${out}-keyed`, out, 128);
      this.textures.remove(`${out}-keyed`);
    }
    addKeyedTexture(this, 'portrait-src', 'portrait', 62);
    addKeyedTexture(this, 'panel-src', 'panel');
    addKeyedTexture(this, 'button-src', 'button');
    addKeyedTexture(this, 'plank-src', 'plank');
    addKeyedTexture(this, 'inventory-src', 'icon-inventory');
    addKeyedTexture(this, 'quest-src', 'icon-quest');
    addKeyedTexture(this, 'xp-src', 'icon-xp');
    addSoftShadowTexture(this);
    registerEnvironmentTextures(this);
    // plaques de bois pour NineSlice : bords réduits pour les petites hauteurs
    addScaledRegionTexture(this, 'ui-plaque-src', 'plaque-sm', 240, 225, 1060, 550, 0.25); // 265×138
    addScaledRegionTexture(this, 'ui-plaque-src', 'plaque-md', 240, 225, 1060, 550, 0.5);  // 530×275
    // interface : découpes validées au banc (scripts/art-qa/crops-qa-ui.ps1)
    addKeyedRegionTexture(this, 'ui-board', 'ui-portrait', 1082, 449, 62, 62, 46);
    addKeyedRegionTexture(this, 'ui-board', 'icon-scroll', 1094, 508, 64, 56, 46);
    addKeyedRegionTexture(this, 'ui-board', 'icon-pack', 1176, 506, 66, 58, 46);
    addKeyedRegionTexture(this, 'ui-board', 'icon-map3', 1264, 508, 66, 55, 46);
    addKeyedRegionTexture(this, 'ui-board', 'icon-coin', 1316, 460, 28, 32, 46);
    addKeyedRegionTexture(this, 'ui-board', 'icon-gem', 1398, 461, 26, 29, 46);
    addKeyedRegionTexture(this, 'ui-board', 'icon-star', 1460, 459, 27, 31, 46);
    // vue carte du panneau Carte (carré autour de la fontaine de la Place, 1696×1696)
    addRegionTexture(this, 'village', 'village-mini', 152, 1972, 1696, 1696);
    // ancres : #lab (Character Lab) · #tiletest (prototype monde en tuiles)
    // · #seamtest (prototype monde en deux images invisibles)
    const hash = window.location.hash;
    if (hash === '#lab') this.scene.start('lab');
    else if (hash === '#tiletest') this.scene.start('tiletest');
    else if (hash === '#seamtest') this.scene.start('seamtest');
    else this.scene.start('village');
  }
}

import Phaser from 'phaser';
import { UI_DEPTH } from './widgets';
import { uiTag } from './uiLayer';
import { addRegionTexture } from '../utils/textures';

const FRAME = 190;      // cadre de bois généré
const MAP = 150;        // carte visible à l'intérieur
const MARGIN = 14;
const CROP_X = 256;     // découpe carrée du décor (1024×1024 centrée)

// Mini-carte dans son cadre de bois sculpté (généré) : positions temps réel.
export class Minimap {
  private playerDot: Phaser.GameObjects.Arc;
  private linaDot: Phaser.GameObjects.Arc;
  private cx: number;
  private cy: number;

  constructor(scene: Phaser.Scene) {
    this.cx = scene.scale.width - MARGIN - FRAME / 2;
    this.cy = scene.scale.height - MARGIN - FRAME / 2;

    if (!scene.textures.exists('village-mini')) {
      addRegionTexture(scene, 'village', 'village-mini', CROP_X, 0, 1024, 1024);
    }

    const map = scene.add
      .image(this.cx, this.cy, 'village-mini')
      .setDisplaySize(MAP, MAP)
      .setDepth(UI_DEPTH)
      .setScrollFactor(0);

    const maskShape = scene.make.graphics({}, false);
    maskShape.fillStyle(0xffffff);
    maskShape.fillRoundedRect(this.cx - MAP / 2, this.cy - MAP / 2, MAP, MAP, 22);
    map.setMask(maskShape.createGeometryMask());

    const frame = scene.add
      .image(this.cx, this.cy, 'ui-frame')
      .setDisplaySize(FRAME, FRAME)
      .setDepth(UI_DEPTH + 1)
      .setScrollFactor(0);

    this.linaDot = scene.add.circle(0, 0, 3.4, 0x7ee08a).setDepth(UI_DEPTH + 2).setScrollFactor(0);
    this.playerDot = scene.add.circle(0, 0, 4, 0xffd94a).setDepth(UI_DEPTH + 2).setScrollFactor(0);
    this.playerDot.setStrokeStyle(1.4, 0x3c2c16);
    this.linaDot.setStrokeStyle(1.2, 0x1c3c22);

    const all = [map, frame, this.playerDot, this.linaDot];
    uiTag(...all);
    all.forEach(o => o.setAlpha(0));
    scene.tweens.add({ targets: all, alpha: 1, duration: 700, delay: 900 });
  }

  update(playerX: number, playerY: number, linaX: number, linaY: number) {
    const toMap = (wx: number, wy: number): [number, number] => [
      this.cx - MAP / 2 + Phaser.Math.Clamp(((wx - CROP_X) / 1024) * MAP, 4, MAP - 4),
      this.cy - MAP / 2 + Phaser.Math.Clamp((wy / 1024) * MAP, 4, MAP - 4),
    ];
    const [px, py] = toMap(playerX, playerY);
    this.playerDot.setPosition(px, py);
    const [lx, ly] = toMap(linaX, linaY);
    this.linaDot.setPosition(lx, ly);
  }
}

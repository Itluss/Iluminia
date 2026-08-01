import Phaser from 'phaser';
import { ImageButton, UI_DEPTH, popIn, fadeOutAndDestroy, Scrim } from './widgets';
import { uiTag } from './uiLayer';
import { GAME_FONT } from './Hud';

const VIEW = 380;   // carte visible
const FRAME = 470;  // cadre de bois

// Panneau Carte : le village dans son cadre de bois, positions au moment
// de l'ouverture (héros en doré, Lina en vert).
export class MapPanel {
  private scene: Phaser.Scene;
  private container: Phaser.GameObjects.Container;
  private button: ImageButton;
  private scrim: Scrim;
  private mask: Phaser.Display.Masks.GeometryMask;

  constructor(
    scene: Phaser.Scene,
    positions: { playerX: number; playerY: number; linaX: number; linaY: number },
    onClose: () => void,
  ) {
    this.scene = scene;
    this.scrim = new Scrim(scene);

    const cx = scene.scale.width / 2;
    const cy = scene.scale.height / 2;

    const map = scene.add.image(0, 0, 'village-mini').setDisplaySize(VIEW, VIEW);
    const maskShape = scene.make.graphics({}, false);
    maskShape.fillStyle(0xffffff);
    maskShape.fillRoundedRect(cx - VIEW / 2, cy - VIEW / 2, VIEW, VIEW, 40);
    this.mask = maskShape.createGeometryMask();
    map.setMask(this.mask);

    const frame = scene.add.image(0, 0, 'ui-frame').setDisplaySize(FRAME, FRAME);

    const toMap = (wx: number, wy: number): [number, number] => [
      -VIEW / 2 + Phaser.Math.Clamp(((wx - 152) / 1696) * VIEW, 10, VIEW - 10),
      -VIEW / 2 + Phaser.Math.Clamp(((wy - 1972) / 1696) * VIEW, 10, VIEW - 10),
    ];
    const [px, py] = toMap(positions.playerX, positions.playerY);
    const playerDot = scene.add.circle(px, py, 7, 0xffd94a).setStrokeStyle(2, 0x3c2c16);
    const [lx, ly] = toMap(positions.linaX, positions.linaY);
    const linaDot = scene.add.circle(lx, ly, 6, 0x7ee08a).setStrokeStyle(2, 0x1c3c22);

    const titlePlaque = scene.add.nineslice(0, -FRAME / 2 - 6, 'plaque-sm', undefined, 220, 50, 24, 24, 20, 20);
    const title = scene.add
      .text(0, -FRAME / 2 - 6, 'Carte', {
        fontFamily: GAME_FONT,
        fontSize: '18px',
        fontStyle: 'bold',
        color: '#fff4d8',
      })
      .setOrigin(0.5)
      .setShadow(0, 2, 'rgba(58,36,10,0.95)', 3);

    this.container = scene.add.container(cx, cy, [map, playerDot, linaDot, frame, titlePlaque, title]);
    this.container.setDepth(UI_DEPTH).setScrollFactor(0);
    uiTag(this.container);
    popIn(scene, this.container);

    this.button = new ImageButton(scene, cx, cy + FRAME / 2 + 16, 150, 'Fermer', onClose);
    this.button.container.setAlpha(0);
    scene.tweens.add({ targets: this.button.container, alpha: 1, duration: 300, delay: 120 });
  }

  close(onDone?: () => void) {
    this.scrim.close();
    this.scene.tweens.add({ targets: this.button.container, alpha: 0, duration: 160 });
    fadeOutAndDestroy(this.scene, this.container, () => {
      this.mask.destroy();
      this.button.destroy();
      onDone?.();
    });
  }
}

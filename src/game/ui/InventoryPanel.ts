import Phaser from 'phaser';
import { gameState } from '../state';
import { ImageButton, UI_DEPTH, popIn, fadeOutAndDestroy, Scrim } from './widgets';
import { uiTag } from './uiLayer';

// Inventaire : panneau illustré, la Planche enchantée en icône réelle.
export class InventoryPanel {
  private scene: Phaser.Scene;
  private container: Phaser.GameObjects.Container;
  private button: ImageButton;

  private scrim: Scrim;

  constructor(scene: Phaser.Scene, onClose: () => void) {
    this.scene = scene;
    this.scrim = new Scrim(scene);

    const panel = scene.add.image(0, 0, scene.textures.exists('panel2') ? 'panel2' : 'panel');
    panel.setScale(560 / panel.width);

    const title = scene.add
      .text(0, -46, 'Inventaire', {
        fontFamily: "'Baloo2', 'Segoe UI', sans-serif",
        fontSize: '22px',
        fontStyle: 'bold',
        color: '#3c2c16',
      })
      .setOrigin(0.5);

    const plank = scene.add.image(-170, 8, 'plank');
    plank.setScale(72 / plank.height);
    plank.setAlpha(gameState.planches > 0 ? 1 : 0.32);

    const label = scene.add
      .text(-120, 8, `Planche enchantée   ×  ${gameState.planches}`, {
        fontFamily: "'Baloo2', 'Segoe UI', sans-serif",
        fontSize: '19px',
        color: gameState.planches > 0 ? '#3c2c16' : '#8a7146',
      })
      .setOrigin(0, 0.5);

    const cx = scene.scale.width / 2;
    this.container = scene.add.container(cx, 250, [panel, title, plank, label]);
    this.container.setDepth(UI_DEPTH).setScrollFactor(0);
    uiTag(this.container);
    popIn(scene, this.container);

    this.button = new ImageButton(scene, cx, 356, 150, 'Fermer', onClose);
    this.button.container.setAlpha(0);
    scene.tweens.add({ targets: this.button.container, alpha: 1, duration: 300, delay: 120 });
  }

  close(onDone?: () => void) {
    this.scrim.close();
    this.scene.tweens.add({ targets: this.button.container, alpha: 0, duration: 160 });
    fadeOutAndDestroy(this.scene, this.container, () => {
      this.button.destroy();
      onDone?.();
    });
  }
}


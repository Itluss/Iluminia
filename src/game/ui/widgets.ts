import Phaser from 'phaser';
import { uiTag } from './uiLayer';

export const UI_DEPTH = 2000;

// Voile sombre derrière les panneaux : le décor s'efface, le dialogue respire.
export class Scrim {
  private g: Phaser.GameObjects.Graphics;
  private scene: Phaser.Scene;

  constructor(scene: Phaser.Scene) {
    this.scene = scene;
    this.g = scene.add.graphics().setDepth(UI_DEPTH - 2).setScrollFactor(0);
    this.g.fillStyle(0x0c0f16, 1);
    this.g.fillRect(0, 0, scene.scale.width, scene.scale.height);
    this.g.setAlpha(0);
    uiTag(this.g);
    scene.tweens.add({ targets: this.g, alpha: 0.32, duration: 300, ease: 'Sine.out' });
  }

  close() {
    this.scene.tweens.add({
      targets: this.g,
      alpha: 0,
      duration: 240,
      ease: 'Sine.in',
      onComplete: () => this.g.destroy(),
    });
  }
}

// Bouton basé sur l'asset button-green : survol et clic animés en douceur.
export class ImageButton {
  readonly container: Phaser.GameObjects.Container;
  private scene: Phaser.Scene;
  private enabled = true;

  constructor(
    scene: Phaser.Scene,
    x: number,
    y: number,
    width: number,
    label: string,
    onClick: () => void,
  ) {
    this.scene = scene;
    // le bouton du sprint FX s'il est disponible, sinon l'ancien
    const img = scene.add.image(0, 0, scene.textures.exists('button2') ? 'button2' : 'button');
    const scale = width / img.width;
    img.setScale(scale);

    // ombre portée sous le bouton
    const shadow = scene.add
      .image(0, img.height * scale * 0.34, 'soft-shadow')
      .setScale((width / 128) * 0.95, 0.32)
      .setAlpha(0.5);

    const text = scene.add
      .text(0, -2, label, {
        fontFamily: "'Baloo2', 'Segoe UI', sans-serif",
        fontSize: `${Math.round(img.height * scale * 0.34)}px`,
        fontStyle: 'bold',
        color: '#ffffff',
      })
      .setOrigin(0.5)
      .setShadow(0, 2, 'rgba(20,30,10,0.55)', 2);

    this.container = scene.add.container(x, y, [shadow, img, text]);
    this.container.setDepth(UI_DEPTH + 2).setScrollFactor(0);
    uiTag(this.container);

    img.setInteractive({ useHandCursor: true });
    img.on('pointerover', () => this.enabled && this.tweenScale(1.06));
    img.on('pointerout', () => this.enabled && this.tweenScale(1));
    img.on('pointerdown', () => {
      if (!this.enabled) return;
      this.tweenScale(0.95);
      scene.time.delayedCall(90, () => this.tweenScale(1));
      onClick();
    });
  }

  private tweenScale(s: number) {
    this.scene.tweens.add({ targets: this.container, scale: s, duration: 120, ease: 'Sine.out' });
  }

  disable() {
    this.enabled = false;
    this.container.setAlpha(0.65);
  }

  destroy() {
    this.container.destroy();
  }
}

// Fondu d'apparition standard d'un panneau d'interface.
export function popIn(scene: Phaser.Scene, target: Phaser.GameObjects.Container) {
  target.setAlpha(0).setScale(0.94);
  scene.tweens.add({ targets: target, alpha: 1, scale: 1, duration: 260, ease: 'Back.out' });
}

// Fondu de fermeture, puis destruction.
export function fadeOutAndDestroy(
  scene: Phaser.Scene,
  target: Phaser.GameObjects.Container,
  onDone?: () => void,
) {
  scene.tweens.add({
    targets: target,
    alpha: 0,
    scale: 0.96,
    duration: 220,
    ease: 'Sine.in',
    onComplete: () => {
      target.destroy();
      onDone?.();
    },
  });
}

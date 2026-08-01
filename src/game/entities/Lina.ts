import Phaser from 'phaser';
import { perspScale } from '../utils/depth';

export const LINA_INTERACT_RADIUS = 104;
const LINA_HEIGHT = 110;

export class Lina {
  readonly x: number;
  readonly y: number;
  private sprite: Phaser.GameObjects.Image;
  private exclaim: Phaser.GameObjects.Image;

  constructor(scene: Phaser.Scene, x: number, y: number) {
    this.x = x;
    this.y = y;

    scene.add.image(x, y - 2, 'soft-shadow').setScale(0.5, 0.46).setDepth(y - 1);

    this.sprite = scene.add.image(x, y, 'lina').setOrigin(0.5, 1);
    this.sprite.setScale((LINA_HEIGHT / this.sprite.height) * perspScale(y));
    this.sprite.setDepth(y);

    // léger flottement : Lina est vivante, pas posée
    scene.tweens.add({
      targets: this.sprite,
      y: y - 3,
      duration: 1900,
      yoyo: true,
      repeat: -1,
      ease: 'Sine.inOut',
    });

    // le marqueur de quête au-dessus d'elle tant que la question n'est pas réussie
    const questKey = scene.textures.exists('icon-exclaim')
      ? 'icon-exclaim'
      : scene.textures.exists('icon-quest2')
        ? 'icon-quest2'
        : 'icon-quest';
    this.exclaim = scene.add.image(x, y - LINA_HEIGHT - 30, questKey).setDepth(y + 1);
    this.exclaim.setScale(48 / this.exclaim.height);
    scene.tweens.add({
      targets: this.exclaim,
      y: this.exclaim.y - 8,
      duration: 700,
      yoyo: true,
      repeat: -1,
      ease: 'Sine.inOut',
    });
  }

  questCompleted() {
    this.exclaim.scene.tweens.add({
      targets: this.exclaim,
      alpha: 0,
      scale: 0.05,
      duration: 400,
      ease: 'Sine.in',
      onComplete: () => this.exclaim.destroy(),
    });
  }

  isPlayerClose(p: { x: number; y: number }): boolean {
    return Phaser.Math.Distance.Between(this.x, this.y - 30, p.x, p.y) < LINA_INTERACT_RADIUS;
  }
}


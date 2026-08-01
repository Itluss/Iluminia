import Phaser from 'phaser';
import { perspScale } from '../utils/depth';

const FOX_HEIGHT = 64;       // nettement plus petit que le héros (116)
const FOLLOW_DISTANCE = 60;  // distance de confort derrière le héros
const FOLLOW_SPEED = 4.2;    // lissage du suivi (par seconde)

// Le compagnon renard : suit le héros en trottinant, respire à l'arrêt.
// Sprite généré par le pipeline (public/art/generated/renard-magique.png).
export class Fox {
  private sprite: Phaser.GameObjects.Image;
  private shadow: Phaser.GameObjects.Image;
  private baseScale: number;
  private t = 0;
  private facing = 1;

  constructor(scene: Phaser.Scene, x: number, y: number) {
    this.shadow = scene.add.image(x, y - 2, 'soft-shadow').setScale(0.34, 0.3).setAlpha(0.8);
    this.sprite = scene.add.image(x, y, 'fox').setOrigin(0.5, 0.97);
    this.baseScale = FOX_HEIGHT / this.sprite.height;
    this.sprite.setScale(this.baseScale);
    this.sprite.setDepth(y);
  }

  update(dt: number, heroX: number, heroY: number, heroDirX: number) {
    this.t += dt;

    // point de confort : derrière le héros (côté opposé à sa direction)
    const behind = heroDirX !== 0 ? -Math.sign(heroDirX) : -this.facing;
    const targetX = heroX + behind * FOLLOW_DISTANCE;
    const targetY = heroY + 6;

    const dx = targetX - this.sprite.x;
    const dy = targetY - this.sprite.y;
    const dist = Math.hypot(dx, dy);
    const k = Math.min(1, dt * FOLLOW_SPEED);
    this.sprite.x += dx * k;
    this.sprite.y += dy * k;

    const moving = dist > 10;
    if (Math.abs(dx) > 4) this.facing = dx > 0 ? 1 : -1;

    // trot (rebond rapide) en mouvement, respiration lente à l'arrêt + perspective
    const bob = moving ? Math.abs(Math.sin(this.t * 10)) * 0.05 : Math.sin(this.t * 2.2) * 0.015;
    const base = this.baseScale * perspScale(this.sprite.y);
    this.sprite.setScale(base * this.facing, base * (1 + bob));
    this.sprite.setRotation(moving ? Math.sin(this.t * 10) * 0.04 : 0);
    this.sprite.setDepth(this.sprite.y);

    this.shadow
      .setPosition(this.sprite.x, this.sprite.y - 1)
      .setScale(0.34 * (1 + bob * 2), 0.3)
      .setAlpha(moving ? 0.65 : 0.8)
      .setDepth(this.sprite.y - 1);
  }
}

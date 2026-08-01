import Phaser from 'phaser';
import { gameState } from '../state';
import { ImageButton, UI_DEPTH, popIn, fadeOutAndDestroy, Scrim } from './widgets';
import { uiTag } from './uiLayer';
import { GAME_FONT } from './Hud';

// Journal de quêtes (ouvert par le bouton Quêtes).
export class QuestPanel {
  private scene: Phaser.Scene;
  private container: Phaser.GameObjects.Container;
  private button: ImageButton;
  private scrim: Scrim;

  constructor(scene: Phaser.Scene, onClose: () => void) {
    this.scene = scene;
    this.scrim = new Scrim(scene);

    const panel = scene.add.image(0, 0, scene.textures.exists('panel2') ? 'panel2' : 'panel');
    panel.setScale(600 / panel.width);

    const title = scene.add
      .text(0, -48, 'Quêtes', {
        fontFamily: GAME_FONT,
        fontSize: '24px',
        fontStyle: 'bold',
        color: '#3c2c16',
      })
      .setOrigin(0.5);

    const icon = scene.add.image(-240, 8, 'icon-scroll');
    icon.setScale(52 / icon.height);

    const bullet = scene.add
      .text(-196, -12, gameState.questionDone ? '✓' : '●', {
        fontFamily: GAME_FONT,
        fontSize: '17px',
        fontStyle: 'bold',
        color: gameState.questionDone ? '#3f8f37' : '#b8860b',
      });

    const text = scene.add.text(
      -172,
      -14,
      gameState.questionDone
        ? 'La question de Lina — terminée !\nRetourne la voir près de la fontaine.'
        : 'La question de Lina\nParle à Lina près de la fontaine (E).',
      {
        fontFamily: GAME_FONT,
        fontSize: '16px',
        color: '#3c2c16',
        lineSpacing: 5,
        wordWrap: { width: 400 },
      },
    );

    const cx = scene.scale.width / 2;
    this.container = scene.add.container(cx, 250, [panel, title, icon, bullet, text]);
    this.container.setDepth(UI_DEPTH).setScrollFactor(0);
    uiTag(this.container);
    popIn(scene, this.container);

    this.button = new ImageButton(scene, cx, 360, 150, 'Fermer', onClose);
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

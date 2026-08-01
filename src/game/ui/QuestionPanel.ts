import Phaser from 'phaser';
import { ImageButton, UI_DEPTH, popIn, fadeOutAndDestroy, Scrim } from './widgets';
import { uiTag } from './uiLayer';

export interface QuestionCallbacks {
  onCorrectRewards: () => void;
  onClose: () => void;
}

const ANSWERS = ['A.  1/2', 'B.  1/3', 'C.  2/3'];
const CORRECT_INDEX = 0;

// Question : mêmes règles que la version précédente, habillée avec les assets.
export class QuestionPanel {
  private scene: Phaser.Scene;
  private container: Phaser.GameObjects.Container;
  private feedback: Phaser.GameObjects.Text;
  private answerButtons: ImageButton[] = [];
  private endButton: ImageButton | null = null;
  private callbacks: QuestionCallbacks;
  private answered = false;
  private keyHandlers: Array<{ event: string; fn: () => void }> = [];

  private scrim: Scrim;

  constructor(scene: Phaser.Scene, callbacks: QuestionCallbacks) {
    this.scene = scene;
    this.callbacks = callbacks;
    this.scrim = new Scrim(scene);

    const panel = scene.add.image(0, 0, 'panel');
    panel.setScale(760 / panel.width);

    const title = scene.add
      .text(0, -26, 'Quelle fraction représente la moitié ?', {
        fontFamily: "'Baloo2', 'Segoe UI', sans-serif",
        fontSize: '22px',
        fontStyle: 'bold',
        color: '#3c2c16',
      })
      .setOrigin(0.5);

    const tip = scene.add
      .text(0, 14, 'Réponds avec les boutons ou les touches 1, 2 et 3', {
        fontFamily: "'Baloo2', 'Segoe UI', sans-serif",
        fontSize: '13px',
        color: '#8a7146',
      })
      .setOrigin(0.5);

    this.feedback = scene.add
      .text(0, 64, '', {
        fontFamily: "'Baloo2', 'Segoe UI', sans-serif",
        fontSize: '16px',
        color: '#3c2c16',
        align: 'center',
        wordWrap: { width: 640 },
        lineSpacing: 4,
      })
      .setOrigin(0.5);

    const cx = scene.scale.width / 2;
    this.container = scene.add.container(cx, 168, [panel, title, tip, this.feedback]);
    this.container.setDepth(UI_DEPTH).setScrollFactor(0);
    uiTag(this.container);
    popIn(scene, this.container);

    ANSWERS.forEach((label, i) => {
      const b = new ImageButton(scene, cx + (i - 1) * 184, 300, 158, label, () => this.answer(i));
      b.container.setAlpha(0);
      scene.tweens.add({ targets: b.container, alpha: 1, duration: 300, delay: 140 + i * 90 });
      this.answerButtons.push(b);
    });

    (['keydown-ONE', 'keydown-TWO', 'keydown-THREE'] as const).forEach((event, i) => {
      const fn = () => this.answer(i);
      scene.input.keyboard?.on(event, fn);
      this.keyHandlers.push({ event, fn });
    });
  }

  private answer(index: number) {
    if (this.answered) return;

    if (index === CORRECT_INDEX) {
      this.answered = true;
      this.answerButtons.forEach(b => b.disable());
      this.feedback.setColor('#2e7d32');
      this.feedback.setText('Bravo ! 1/2 représente bien une moitié.');
      this.callbacks.onCorrectRewards();

      this.scene.time.delayedCall(1100, () => {
        this.feedback.setText(
          'Bravo ! 1/2 représente bien une moitié.\nTu as obtenu une Planche enchantée.',
        );
        this.endButton = new ImageButton(this.scene, this.scene.scale.width / 2, 386, 170, 'Terminer', () => this.close());
        this.endButton.container.setAlpha(0);
        this.scene.tweens.add({ targets: this.endButton.container, alpha: 1, duration: 300 });
      });
    } else {
      this.feedback.setColor('#a33a28');
      this.feedback.setText(
        'Ce n’est pas encore la bonne réponse.\nRegarde : une moitié correspond à une part sur deux parts égales.',
      );
      this.scene.cameras.main.shake(110, 0.0022);
    }
  }

  private close() {
    this.scrim.close();
    this.keyHandlers.forEach(({ event, fn }) => this.scene.input.keyboard?.off(event, fn));
    this.answerButtons.forEach(b => {
      this.scene.tweens.add({ targets: b.container, alpha: 0, duration: 180 });
    });
    if (this.endButton) this.scene.tweens.add({ targets: this.endButton.container, alpha: 0, duration: 180 });
    fadeOutAndDestroy(this.scene, this.container, () => {
      this.answerButtons.forEach(b => b.destroy());
      this.endButton?.destroy();
      this.callbacks.onClose();
    });
  }

  /** Fermeture directe (sécurité). */
  destroy() {
    this.keyHandlers.forEach(({ event, fn }) => this.scene.input.keyboard?.off(event, fn));
    this.answerButtons.forEach(b => b.destroy());
    this.endButton?.destroy();
    this.container.destroy();
  }
}


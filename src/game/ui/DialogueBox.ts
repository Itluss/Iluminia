import Phaser from 'phaser';
import { ImageButton, UI_DEPTH, popIn, fadeOutAndDestroy, Scrim } from './widgets';
import { uiTag } from './uiLayer';

export interface DialogueOptions {
  name: string;
  text: string;
  buttonLabel: string;
  onButton: () => void;
}

// Dialogue : panneau illustré, portrait de Lina, texte progressif, bouton animé.
export class DialogueBox {
  private scene: Phaser.Scene;
  private container: Phaser.GameObjects.Container;
  private button: ImageButton;
  private scrim: Scrim;
  private typing?: Phaser.Time.TimerEvent;

  constructor(scene: Phaser.Scene, opts: DialogueOptions) {
    this.scene = scene;
    this.scrim = new Scrim(scene);

    const cx = scene.scale.width / 2;
    const cy = scene.scale.height - 112;

    const panel = scene.add.image(0, 0, 'panel');
    panel.setScale(840 / panel.width); // ≈ 840 × 203, ratio conservé

    const portrait = scene.add.image(-330, 88, 'portrait').setOrigin(0.5, 1);
    portrait.setScale(168 / portrait.height);
    // le portrait vit très légèrement
    scene.tweens.add({
      targets: portrait,
      y: 85,
      duration: 2100,
      yoyo: true,
      repeat: -1,
      ease: 'Sine.inOut',
    });

    const name = scene.add
      .text(-240, -62, opts.name, {
        fontFamily: "'Baloo2', 'Segoe UI', sans-serif",
        fontSize: '20px',
        fontStyle: 'bold',
        color: '#7a4a12',
      })
      .setShadow(0, 1, 'rgba(255,244,214,0.8)', 0);

    const text = scene.add.text(-240, -30, '', {
      fontFamily: "'Baloo2', 'Segoe UI', sans-serif",
      fontSize: '18px',
      color: '#3c2c16',
      wordWrap: { width: 480 },
      lineSpacing: 6,
    });

    this.container = scene.add.container(cx, cy, [panel, portrait, name, text]);
    // la petite flèche de dialogue des RPG, qui rebondit doucement
    if (scene.textures.exists('dlg-arrow')) {
      const arrow = scene.add.image(378, 74, 'dlg-arrow').setScale(0.7);
      this.container.add(arrow);
      scene.tweens.add({ targets: arrow, y: 80, duration: 520, yoyo: true, repeat: -1, ease: 'Sine.inOut' });
    }
    this.container.setDepth(UI_DEPTH).setScrollFactor(0);
    uiTag(this.container);
    popIn(scene, this.container);

    // texte progressif, lettre par lettre
    let shown = 0;
    this.typing = scene.time.addEvent({
      delay: 16,
      repeat: opts.text.length - 1,
      callback: () => {
        shown++;
        text.setText(opts.text.slice(0, shown));
      },
    });

    this.button = new ImageButton(scene, cx + 300, cy + 62, 160, opts.buttonLabel, opts.onButton);
    this.button.container.setAlpha(0);
    scene.tweens.add({ targets: this.button.container, alpha: 1, duration: 350, delay: 250 });
  }

  /** Fermeture en fondu, puis callback. */
  close(onDone?: () => void) {
    this.typing?.remove();
    this.scrim.close();
    this.scene.tweens.add({ targets: this.button.container, alpha: 0, duration: 180 });
    fadeOutAndDestroy(this.scene, this.container, () => {
      this.button.destroy();
      onDone?.();
    });
  }
}


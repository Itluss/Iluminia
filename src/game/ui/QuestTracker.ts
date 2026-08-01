import Phaser from 'phaser';
import { gameState } from '../state';
import { UI_DEPTH } from './widgets';
import { uiTag } from './uiLayer';
import { GAME_FONT } from './Hud';

const W = 236;
const H = 138;

// Suivi de quête sur plaque de bois — chaleureux, lisible, compact.
export class QuestTracker {
  private objective: Phaser.GameObjects.Text;
  private bullet: Phaser.GameObjects.Text;

  constructor(scene: Phaser.Scene) {
    // sous la plaque du nom du lieu, dans la colonne haut-gauche (Hud.ts)
    const x0 = 14;
    const y0 = 170;

    const plaque = scene.add.nineslice(0, 0, 'plaque-md', undefined, W, H, 42, 42, 42, 42).setOrigin(0);

    const title = scene.add
      .text(W / 2, 24, 'Quêtes', {
        fontFamily: GAME_FONT,
        fontSize: '17px',
        fontStyle: 'bold',
        color: '#fff4d8',
      })
      .setOrigin(0.5, 0)
      .setShadow(0, 2, 'rgba(58,36,10,0.95)', 3);

    this.bullet = scene.add
      .text(30, 56, '', {
        fontFamily: GAME_FONT,
        fontSize: '14px',
        fontStyle: 'bold',
        color: '#ffd94a',
      })
      .setShadow(0, 1, 'rgba(58,36,10,0.95)', 2);

    this.objective = scene.add
      .text(46, 56, '', {
        fontFamily: GAME_FONT,
        fontSize: '13px',
        color: '#fff4d8',
        wordWrap: { width: W - 82 },
        lineSpacing: 3,
      })
      .setShadow(0, 1, 'rgba(58,36,10,0.95)', 2);

    const box = scene.add.container(x0, y0, [plaque, title, this.bullet, this.objective]);
    box.setDepth(UI_DEPTH).setScrollFactor(0).setAlpha(0);
    uiTag(box);
    scene.tweens.add({ targets: box, alpha: 1, duration: 700, delay: 800 });

    this.refresh();
  }

  refresh() {
    if (gameState.questionDone) {
      this.bullet.setText('✓').setColor('#3f8f37');
      this.objective.setText('La question de Lina — terminée !\nRetourne la voir près de la fontaine.');
    } else {
      this.bullet.setText('●').setColor('#b8860b');
      this.objective.setText('La question de Lina\nParle à Lina près de la fontaine (E).');
    }
  }
}

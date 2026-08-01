import Phaser from 'phaser';
import { CharacterRig } from '../characters/CharacterRig';
import { loadHeroParts } from '../characters/loadHeroParts';
import { GAME_FONT } from '../ui/Hud';

// Character Lab (Phase 14) : banc d'inspection des personnages riggés.
// Accès : http://localhost:5173/#lab
// Touches : B os · P pause idle · S ralenti 0,25× · E expressions ·
//           D fond (atelier neutre ↔ décor du village)
export class LabScene extends Phaser.Scene {
  private rig: CharacterRig | null = null;
  private rigBig: CharacterRig | null = null;
  private exprIdx = 0;
  private info!: Phaser.GameObjects.Text;
  private bgVillage!: Phaser.GameObjects.Image;

  constructor() {
    super('lab');
  }

  create() {
    const W = this.scale.width;
    const H = this.scale.height;

    // fonds : neutre clair (atelier) et décor du village (touche D)
    this.cameras.main.setBackgroundColor('#efe9dd');
    this.bgVillage = this.add.image(0, 0, 'village').setOrigin(0).setVisible(false).setDepth(-1);
    this.bgVillage.setPosition(-700, -600);

    const manifest = this.cache.json.get('hero-manifest');
    const rigData = this.cache.json.get('hero-rig');

    // chargement différé des pièces approuvées puis construction
    loadHeroParts(this, manifest, rigData, () => {
      const gameH = manifest.gameHeightPx ?? 116;
      // ombres de contact : repère de sol pour juger l'ancrage des figures
      this.add.image(W * 0.24, H * 0.62 - 2, 'soft-shadow').setScale(0.6, 0.5).setAlpha(0.55);
      this.add.image(W * 0.5, H * 0.62 - 2, 'soft-shadow').setScale(0.6, 0.5).setAlpha(0.55);
      this.add.image(W * 0.76, H * 0.88 - 4, 'soft-shadow').setScale(2.5, 2.0).setAlpha(0.45);
      this.rig = new CharacterRig(this, W * 0.5, H * 0.62, rigData, gameH);
      this.rigBig = new CharacterRig(this, W * 0.76, H * 0.88, rigData, gameH * 4.2);

      // l'ancien héros (texture d'animation actuelle) à taille de jeu
      const old = this.add.image(W * 0.24, H * 0.62, 'hero').setOrigin(0.5, 1);
      old.setScale(gameH / old.height);

      this.label(W * 0.24, H * 0.66, 'ANCIEN (sprite)');
      this.label(W * 0.5, H * 0.66, 'NOUVEAU (taille jeu)');
      this.label(W * 0.76, H * 0.92, 'NOUVEAU ×4,2');
    });

    this.info = this.add
      .text(16, 14, 'CHARACTER LAB — B : os · P : pause idle · S : ralenti 0,25× · E : expressions · D : fond', {
        fontFamily: GAME_FONT,
        fontSize: '15px',
        color: '#4a3a20',
      })
      .setDepth(10);

    let bones = false;
    let slow = false;
    let idle = true;
    const kb = this.input.keyboard!;
    kb.on('keydown-B', () => {
      bones = !bones;
      this.rig?.setDebug(bones);
      this.rigBig?.setDebug(bones);
    });
    kb.on('keydown-S', () => {
      slow = !slow;
      const ts = slow ? 0.25 : 1;
      this.rig?.setTimeScale(ts);
      this.rigBig?.setTimeScale(ts);
      this.note(slow ? 'ralenti 0,25×' : 'vitesse normale');
    });
    kb.on('keydown-P', () => {
      idle = !idle;
      this.rig?.setIdle(idle);
      this.rigBig?.setIdle(idle);
      this.note(idle ? 'idle actif' : 'idle en pause');
    });
    kb.on('keydown-E', () => {
      const states = manifest.expressionStates ?? {};
      const names = Object.keys(states);
      if (!names.length) return;
      this.exprIdx = (this.exprIdx + 1) % names.length;
      const name = names[this.exprIdx];
      this.rig?.setExpression(states, name);
      this.rigBig?.setExpression(states, name);
      this.note(`expression : ${name}`);
    });
    kb.on('keydown-D', () => {
      this.bgVillage.setVisible(!this.bgVillage.visible);
      this.cameras.main.setBackgroundColor(this.bgVillage.visible ? '#000000' : '#efe9dd');
    });
  }

  private label(x: number, y: number, text: string) {
    this.add
      .text(x, y, text, { fontFamily: GAME_FONT, fontSize: '13px', fontStyle: 'bold', color: '#6a5a3a' })
      .setOrigin(0.5, 0)
      .setDepth(10);
  }

  private note(text: string) {
    this.info.setText(`CHARACTER LAB — ${text}`);
  }

  update(_t: number, delta: number) {
    const dt = delta / 1000;
    this.rig?.update(dt);
    this.rigBig?.update(dt);
  }
}

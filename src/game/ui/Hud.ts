import Phaser from 'phaser';
import { gameState } from '../state';
import { UI_DEPTH } from './widgets';
import { uiTag } from './uiLayer';

export const GAME_FONT = "'Baloo2', 'Segoe UI', sans-serif";

export interface HudCallbacks {
  onQuests: () => void;
  onInventory: () => void;
  onMap: () => void;
}

// Interface reproduite depuis la planche de référence :
// - plaque du nom du lieu (haut-gauche) + colonne Quêtes / Inventaire / Carte ;
// - bandeau sombre (haut-droit) : portrait, niveau, barre d'XP verte, monnaies.
export class Hud {
  private levelText: Phaser.GameObjects.Text;
  private xpValue: Phaser.GameObjects.Text;
  private xpBar: Phaser.GameObjects.Graphics;
  private coinText: Phaser.GameObjects.Text;
  private gemText: Phaser.GameObjects.Text;
  private starText: Phaser.GameObjects.Text;
  private xpTrack!: { x1: number; y1: number; x2: number; y2: number };

  constructor(scene: Phaser.Scene, cb: HudCallbacks) {
    // ---- plaque du nom du lieu : le panneau de bois peint de la maquette
    const signTex = scene.textures.get('ui-sign').getSourceImage();
    const SIGN_W = 330;
    const SIGN_H = Math.round((SIGN_W * signTex.height) / signTex.width);
    const nameShadow = scene.add
      .image(SIGN_W / 2 + 4, SIGN_H / 2 + 6, 'ui-sign')
      .setDisplaySize(SIGN_W, SIGN_H)
      .setTint(0x000000)
      .setAlpha(0.32);
    // le lettrage « LE VILLAGE DES FRACTIONS » est peint dans l'asset
    const namePlaque = scene.add.image(SIGN_W / 2, SIGN_H / 2, 'ui-sign').setDisplaySize(SIGN_W, SIGN_H);
    const nameBox = scene.add.container(14, 12, [nameShadow, namePlaque]);
    nameBox.setDepth(UI_DEPTH).setScrollFactor(0).setAlpha(0);
    uiTag(nameBox);
    scene.tweens.add({ targets: nameBox, alpha: 1, duration: 700, delay: 600 });

    // ---- barre d'action (bas d'écran) : mêmes actions que la maquette
    // v1 (colonne haut-gauche), reprises en slots horizontaux façon
    // barre d'outils — aucune nouvelle mécanique (pas d'objets à équiper).
    const slots: Array<[string, string, () => void]> = [
      ['icon-scroll2', 'Quêtes', cb.onQuests],
      ['icon-pack2', 'Inventaire', cb.onInventory],
      ['icon-map2', 'Carte', cb.onMap],
    ];
    const SLOT_W = 88;
    const SLOT_H = 96;
    const barW2 = slots.length * SLOT_W;
    const barX = (scene.scale.width - barW2) / 2;
    const barY = scene.scale.height - SLOT_H - 26;

    const actionBar = scene.add.container(barX, barY);
    actionBar.setDepth(UI_DEPTH).setScrollFactor(0).setAlpha(0);
    uiTag(actionBar);
    scene.tweens.add({ targets: actionBar, alpha: 1, duration: 700, delay: 700 });

    // un seul bandeau continu sous les 3 icônes (au lieu d'un cadre par slot)
    const plank = scene.add.nineslice(barW2 / 2, SLOT_H / 2, 'plaque-sm', undefined, barW2 - 8, SLOT_H - 8, 24, 24, 20, 20);
    actionBar.add(plank);

    slots.forEach(([key, label, onClick], i) => {
      const cx = i * SLOT_W + SLOT_W / 2;
      const cy = SLOT_H / 2;
      const hitZone = scene.add
        .rectangle(cx, cy, SLOT_W - 6, SLOT_H - 8, 0, 0)
        .setInteractive({ useHandCursor: true });
      const icon = scene.add.image(cx, cy - 10, key);
      const iconScale = 46 / icon.height;
      icon.setScale(iconScale);
      const text = scene.add
        .text(cx, cy + 26, label, {
          fontFamily: GAME_FONT,
          fontSize: '11px',
          fontStyle: 'bold',
          color: '#3c2c16',
        })
        .setOrigin(0.5, 0);
      actionBar.add([hitZone, icon, text]);

      hitZone.on('pointerover', () =>
        scene.tweens.add({ targets: icon, scale: iconScale * 1.14, duration: 130, ease: 'Sine.out' }),
      );
      hitZone.on('pointerout', () =>
        scene.tweens.add({ targets: icon, scale: iconScale, duration: 130, ease: 'Sine.out' }),
      );
      hitZone.on('pointerdown', onClick);
    });

    // ---- barre de statut parchemin/or (asset Camille, valeurs dynamiques).
    // La texture 'ui-xpbar' est préparée au boot par découpe FIXE (2508×540
    // réduite à H=160) : les positions ci-dessous sont des pixels de CETTE
    // texture, convertis à l'écran par le facteur k.
    const BAR_TEX_W = 960;
    const BAR_TEX_H = 160;
    const BAR_H = 100; // même hauteur que la plaque du nom (alignement demandé)
    const k = BAR_H / BAR_TEX_H;
    const barW = Math.round(BAR_TEX_W * k);
    this.xpTrack = { x1: 190 * k, y1: 84 * k, x2: 527 * k, y2: 105 * k };

    const barShadow = scene.add.image(3, 6, 'ui-xpbar').setOrigin(0).setScale(k).setTint(0x000000).setAlpha(0.3);
    const barImg = scene.add.image(0, 0, 'ui-xpbar').setOrigin(0).setScale(k);

    this.levelText = scene.add.text(135 * k, 45 * k, '', {
      fontFamily: GAME_FONT,
      fontSize: '15px',
      fontStyle: 'bold',
      color: '#5a3a16',
    }).setOrigin(0, 0.5);

    this.xpBar = scene.add.graphics();
    this.xpValue = scene.add
      .text((this.xpTrack.x1 + this.xpTrack.x2) / 2, (this.xpTrack.y1 + this.xpTrack.y2) / 2, '', {
        fontFamily: GAME_FONT,
        fontSize: '10px',
        fontStyle: 'bold',
        color: '#ffffff',
      })
      .setOrigin(0.5)
      .setShadow(0, 1, 'rgba(10,12,18,0.9)', 2);

    const currency = (x: number): Phaser.GameObjects.Text => {
      const t = scene.add
        .text(x * k, 109 * k, '0', {
          fontFamily: GAME_FONT,
          fontSize: '13px',
          fontStyle: 'bold',
          color: '#fff4d8',
        })
        .setOrigin(0.5)
        .setShadow(0, 1, 'rgba(30,18,6,0.95)', 2);
      bar.add(t);
      return t;
    };

    const bar = scene.add.container(scene.scale.width - 14 - barW, 12, [barShadow, barImg, this.levelText, this.xpBar, this.xpValue]);
    bar.setDepth(UI_DEPTH).setScrollFactor(0).setAlpha(0);
    uiTag(bar);
    this.coinText = currency(709);
    this.gemText = currency(810);
    this.starText = currency(910);
    scene.tweens.add({ targets: bar, alpha: 1, duration: 700, delay: 650 });

    this.refresh();
  }

  refresh() {
    this.levelText.setText(`Niv. ${gameState.level}`);
    const ratio = Phaser.Math.Clamp(gameState.xp / gameState.xpNextLevel, 0, 1);
    const t = this.xpTrack;
    const tw = t.x2 - t.x1;
    const th = t.y2 - t.y1;
    this.xpBar.clear();
    if (ratio > 0) {
      // remplissage bleu lumineux dans la piste peinte de l'asset
      const fw = Math.max(th, tw * ratio);
      const r = th / 2 - 1;
      this.xpBar.fillStyle(0x1e9fd4, 1);
      this.xpBar.fillRoundedRect(t.x1 + 1, t.y1 + 1, fw, th - 2, r);
      this.xpBar.fillStyle(0x8fe4ff, 0.75); // reflet haut
      this.xpBar.fillRoundedRect(t.x1 + 3, t.y1 + 2, Math.max(th, fw - 5), Math.max(2, th * 0.32), r * 0.6);
      this.xpBar.fillStyle(0x0e6e9c, 0.55); // assise sombre
      this.xpBar.fillRoundedRect(t.x1 + 3, t.y2 - 4, Math.max(th, fw - 5), 2.5, 1.2);
    }
    this.xpValue.setText(`${gameState.xp} / ${gameState.xpNextLevel}`);
    this.coinText.setText(String(gameState.coins));
    this.gemText.setText(String(gameState.crystals));
    this.starText.setText(String(gameState.stars));
  }
}

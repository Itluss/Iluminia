import Phaser from 'phaser';
import { save } from '../progress';

const PLAYER_SPEED = 220; // pixels par seconde
const T = 64; // taille d'une tuile à l'écran (16 px × 4)
const COLS = 15;
const ROWS = 10;

interface DialogContent {
  text: string;
  action?: { label: string; scene: string };
}

interface Npc {
  name: string;
  sprite: Phaser.GameObjects.Container;
  getDialog: () => DialogContent;
}

const TILE_KEYS = [
  'grass1', 'grass2', 'grass3', 'grass-stones', 'water', 'bank-left',
  'dirt-nw', 'dirt-n', 'dirt-ne', 'dirt-w', 'dirt-c', 'dirt-e', 'dirt-sw', 'dirt-s', 'dirt-se',
  'tree-green-bot', 'tree-orange-bot', 'tree-small-green', 'tree-small-orange', 'mushrooms',
  'roof-red-nw', 'roof-red-n', 'roof-red-ne', 'roof-red-sw', 'roof-red-s', 'roof-red-se',
  'roof-blue-nw', 'roof-blue-n', 'roof-blue-ne', 'roof-blue-sw', 'roof-blue-s', 'roof-blue-se',
  'wall-stone-window', 'wall-stone-door', 'wall-brown-window', 'wall-brown-door',
  'beam-l', 'beam-m', 'beam-r', 'sign', 'well', 'crate', 'pot', 'beehive',
  'char-player', 'char-marta', 'char-bram', 'char-lior',
];

// Fondvallon en pixel art (packs Kenney « Tiny », CC0).
// Toutes les interactions sont au pointeur (souris ou doigt) — jamais de clavier requis.
export class VillageScene extends Phaser.Scene {
  private player!: Phaser.GameObjects.Container;
  private moveTween?: Phaser.Tweens.Tween;
  private npcs: Npc[] = [];
  private dialogBox?: Phaser.GameObjects.Container;
  // Zones où l'on ne marche pas : maisons et rivière.
  private blocked: Phaser.Geom.Rectangle[] = [];

  constructor() {
    super('village');
  }

  preload() {
    for (const key of TILE_KEYS) this.load.image(key, `assets/${key}.png`);
  }

  create() {
    this.drawGround();
    this.drawRiverAndBridge();
    this.drawBuildingsAndProps();

    this.player = this.makeCharacter(1.5 * T, 6.5 * T, 'char-player', 'Toi');

    this.npcs = [
      {
        name: 'Marta',
        sprite: this.makeCharacter(3.5 * T, 4.2 * T, 'char-marta', 'Marta'),
        getDialog: () =>
          save.missions.bakery === 0
            ? {
                text: 'Bienvenue à Fondvallon ! Le grand pont s’est effondré… Les ouvriers ont faim, tu veux bien m’aider à livrer mes tartes ?',
                action: { label: 'Aider Marta', scene: 'bakery' },
              }
            : {
                text: 'Les ouvriers se régalent grâce à toi ! Une nouvelle fournée est prête, tu veux encore m’aider ?',
                action: { label: 'Encore des tartes !', scene: 'bakery' },
              },
      },
      {
        name: 'Bram',
        sprite: this.makeCharacter(11.5 * T, 4.3 * T, 'char-bram', 'Bram'),
        getDialog: () =>
          save.missions.bakery === 0
            ? { text: 'Regarde-moi ce chantier. Sans planches bien posées, personne ne traversera. Reviens me voir quand Marta n’aura plus besoin de toi.' }
            : { text: 'Les ouvriers ont repris des forces, le chantier peut commencer ! Je prépare la première travée — reviens me voir bientôt.' },
      },
      {
        name: 'Lior',
        sprite: this.makeCharacter(11.3 * T, 7.5 * T, 'char-lior', 'Lior'),
        getDialog: () => ({ text: 'Ma barque fait la traversée en attendant le pont. Mais mal chargée, elle chavire !' }),
      },
    ];

    for (const npc of this.npcs) {
      npc.sprite.setInteractive(new Phaser.Geom.Circle(0, 0, 36), Phaser.Geom.Circle.Contains);
      npc.sprite.on('pointerdown', (_pointer: Phaser.Input.Pointer, _x: number, _y: number, event: Phaser.Types.Input.EventData) => {
        event.stopPropagation();
        this.walkTo(npc.sprite.x - 40, npc.sprite.y + 30, () => this.showDialog(npc));
      });
    }

    this.input.on('pointerdown', (pointer: Phaser.Input.Pointer) => {
      if (this.dialogBox) {
        this.closeDialog();
        return;
      }
      this.walkTo(pointer.worldX, pointer.worldY);
    });
  }

  private tileAt(key: string, col: number, row: number, depth = 0) {
    return this.add.image(col * T + T / 2, row * T + T / 2, key).setScale(4).setDepth(depth);
  }

  private drawGround() {
    // Herbe avec variations pseudo-aléatoires mais stables (pas de Math.random : rendu identique à chaque visite).
    for (let row = 0; row < ROWS; row++) {
      for (let col = 0; col < COLS; col++) {
        const n = (col * 7 + row * 13) % 11;
        const key = n === 0 ? 'grass2' : n === 5 ? 'grass3' : 'grass1';
        this.tileAt(key, col, row);
      }
    }
    // La place du village en terre battue (cols 2-9, rows 4-6).
    for (let row = 4; row <= 6; row++) {
      for (let col = 2; col <= 9; col++) {
        const v = row === 4 ? 'n' : row === 6 ? 's' : '';
        const h = col === 2 ? 'w' : col === 9 ? 'e' : '';
        const key = v || h ? `dirt-${v}${h}` : 'dirt-c';
        this.tileAt(key, col, row, 1);
      }
    }
  }

  private drawRiverAndBridge() {
    for (let row = 0; row < ROWS; row++) {
      this.tileAt('bank-left', 12, row, 1);
      this.tileAt('water', 13, row, 1);
      this.tileAt('water', 14, row, 1);
    }
    this.blocked.push(new Phaser.Geom.Rectangle(12.4 * T, 0, COLS * T - 12.4 * T, ROWS * T));

    // Le pont effondré : deux moignons de chaque côté, un trou au milieu.
    this.tileAt('beam-l', 12, 4, 2);
    this.tileAt('beam-r', 14, 4, 2);
    this.add.text(12.7 * T, 3.1 * T, 'Pont effondré', {
      fontSize: '15px', color: '#ffffff', backgroundColor: '#2d3436', padding: { x: 6, y: 3 },
    });

    // Le ponton de Lior, en contrebas.
    this.tileAt('beam-l', 12, 7, 2);
    this.tileAt('beam-m', 13, 7, 2);
  }

  private drawBuildingsAndProps() {
    // La boulangerie de Marta (toit rouge, murs de pierre), cols 2-4 rows 1-3.
    const bakery: Array<[string, number, number]> = [
      ['roof-red-nw', 2, 1], ['roof-red-n', 3, 1], ['roof-red-ne', 4, 1],
      ['roof-red-sw', 2, 2], ['roof-red-s', 3, 2], ['roof-red-se', 4, 2],
      ['wall-stone-window', 2, 3], ['wall-stone-door', 3, 3], ['wall-stone-window', 4, 3],
    ];
    // La maison des ouvriers (toit bleu, murs de bois), cols 7-9 rows 1-3.
    const house: Array<[string, number, number]> = [
      ['roof-blue-nw', 7, 1], ['roof-blue-n', 8, 1], ['roof-blue-ne', 9, 1],
      ['roof-blue-sw', 7, 2], ['roof-blue-s', 8, 2], ['roof-blue-se', 9, 2],
      ['wall-brown-window', 7, 3], ['wall-brown-door', 8, 3], ['wall-brown-window', 9, 3],
    ];
    for (const [key, col, row] of [...bakery, ...house]) this.tileAt(key, col, row, 3);
    this.blocked.push(new Phaser.Geom.Rectangle(2 * T, 1 * T, 3 * T, 3 * T));
    this.blocked.push(new Phaser.Geom.Rectangle(7 * T, 1 * T, 3 * T, 3 * T));

    // Décor : arbres en lisière, panneaux et petits objets.
    const decor: Array<[string, number, number]> = [
      ['tree-green-bot', 0, 0], ['tree-orange-bot', 1, 0], ['tree-green-bot', 5, 0], ['tree-orange-bot', 6, 0],
      ['tree-green-bot', 10, 0], ['tree-small-orange', 11, 0], ['tree-orange-bot', 0, 2], ['tree-small-green', 0, 4],
      ['tree-green-bot', 0, 8], ['tree-orange-bot', 1, 9], ['tree-small-green', 4, 9], ['tree-green-bot', 7, 9],
      ['tree-small-orange', 10, 9], ['mushrooms', 2, 8], ['sign', 5, 4], ['well', 6, 5],
      ['crate', 5, 3], ['pot', 10, 3], ['beehive', 11, 1],
    ];
    for (const [key, col, row] of decor) this.tileAt(key, col, row, row * T + T);
  }

  private makeCharacter(x: number, y: number, textureKey: string, label: string): Phaser.GameObjects.Container {
    const body = this.add.image(0, 0, textureKey).setScale(4);
    const name = this.add.text(0, -48, label, {
      fontSize: '15px', color: '#ffffff', fontStyle: 'bold', backgroundColor: '#2d3436', padding: { x: 5, y: 1 },
    }).setOrigin(0.5);
    const container = this.add.container(x, y, [body, name]);
    container.setDepth(y);
    return container;
  }

  private isBlocked(x: number, y: number): boolean {
    return this.blocked.some((r) => r.contains(x, y));
  }

  private walkTo(x: number, y: number, onArrive?: () => void) {
    let tx = Phaser.Math.Clamp(x, 24, 12 * T);
    let ty = Phaser.Math.Clamp(y, 40, ROWS * T - 24);
    // Si la cible est dans une maison ou l'eau, on s'arrête au dernier point libre du trajet.
    if (this.isBlocked(tx, ty)) {
      let found = false;
      for (let f = 0.95; f >= 0; f -= 0.05) {
        const px = this.player.x + (tx - this.player.x) * f;
        const py = this.player.y + (ty - this.player.y) * f;
        if (!this.isBlocked(px, py)) {
          tx = px;
          ty = py;
          found = true;
          break;
        }
      }
      if (!found) return;
    }

    this.moveTween?.stop();
    const distance = Phaser.Math.Distance.Between(this.player.x, this.player.y, tx, ty);
    this.moveTween = this.tweens.add({
      targets: this.player,
      x: tx,
      y: ty,
      duration: (distance / PLAYER_SPEED) * 1000,
      onUpdate: () => this.player.setDepth(this.player.y),
      onComplete: () => onArrive?.(),
    });
  }

  private showDialog(npc: Npc) {
    this.closeDialog();
    const { text: dialogText, action } = npc.getDialog();
    const box = this.add.rectangle(480, 560, 880, 130, 0xffffff, 0.95).setStrokeStyle(3, 0x2d3436);
    const name = this.add.text(70, 505, npc.name, { fontSize: '18px', color: '#c0392b', fontStyle: 'bold' });
    const text = this.add.text(70, 532, dialogText, { fontSize: '17px', color: '#2d3436', wordWrap: { width: action ? 640 : 820 } });
    const parts: Phaser.GameObjects.GameObject[] = [box, name, text];

    if (action) {
      const label = this.add.text(810, 560, action.label, { fontSize: '17px', color: '#ffffff', fontStyle: 'bold' }).setOrigin(0.5);
      const button = this.add.rectangle(810, 560, label.width + 36, 44, 0x6ab04c).setStrokeStyle(3, 0x2d3436);
      button.setInteractive({ useHandCursor: true });
      button.on('pointerdown', (_pointer: Phaser.Input.Pointer, _x: number, _y: number, event: Phaser.Types.Input.EventData) => {
        event.stopPropagation();
        this.scene.start(action.scene);
      });
      parts.push(button, label.setDepth(1));
    }

    this.dialogBox = this.add.container(0, 0, parts).setDepth(10000);
  }

  private closeDialog() {
    this.dialogBox?.destroy();
    this.dialogBox = undefined;
  }
}

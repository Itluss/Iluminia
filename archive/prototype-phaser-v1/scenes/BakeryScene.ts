import Phaser from 'phaser';
import { generateOrders, orderInWords, type Order } from '../fractions';
import { record, save, persist, tier } from '../progress';

const ORDERS_PER_RUN = 4;
const SLICE_RADIUS = 70;
const TART = { x: 240, y: 300 };
const PLATE = { x: 760, y: 400 };
const ROW = { x: 80, y: 310, step: 72 };
const WORKERS = [
  { name: 'Tom', texture: 'char-worker1' },
  { name: 'Léa', texture: 'char-worker4' },
  { name: 'Sacha', texture: 'char-worker2' },
  { name: 'Nina', texture: 'char-worker3' },
];

interface Slice {
  g: Phaser.GameObjects.Graphics;
  rowIndex: number;
  onPlate: boolean;
}

interface FractionDisplay {
  container: Phaser.GameObjects.Container;
  numText: Phaser.GameObjects.Text;
  denText: Phaser.GameObjects.Text;
}

// Mission 1 — « Le four de Marta » (FRA-01, FRA-02).
// L'enfant découpe des tartes en parts égales et compose la commande de chaque ouvrier.
export class BakeryScene extends Phaser.Scene {
  private orders: Order[] = [];
  private orderIndex = 0;
  private wrongServes = 0;
  private cutDen: number | null = null;
  private slices: Slice[] = [];
  private wholeTart?: Phaser.GameObjects.Container;
  private busy = false;

  private workerSprite?: Phaser.GameObjects.Container;
  private bubbleText!: Phaser.GameObjects.Text;
  private feedbackText!: Phaser.GameObjects.Text;
  private orderFraction?: FractionDisplay;
  private plateFraction?: FractionDisplay;
  private progressDots: Phaser.GameObjects.Arc[] = [];

  constructor() {
    super('bakery');
  }

  preload() {
    for (const key of ['char-marta', 'char-worker1', 'char-worker2', 'char-worker3', 'char-worker4']) {
      this.load.image(key, `assets/${key}.png`);
    }
  }

  create() {
    // La difficulté suit la maîtrise courante de FRA-01 (le palier le plus faible prime).
    const t = Math.min(tier('FRA-01'), tier('FRA-02')) as 0 | 1 | 2;
    this.orders = generateOrders(t, ORDERS_PER_RUN);
    this.orderIndex = 0;
    this.slices = [];
    this.busy = false;

    this.cameras.main.setBackgroundColor(0xffeaa7);
    this.add.image(46, 40, 'char-marta').setScale(3.5);
    this.add.text(84, 22, 'Le four de Marta', { fontSize: '26px', color: '#6d4c1b', fontStyle: 'bold' });
    this.makeButton(80, 610, 'Retour au village', () => this.scene.start('village'), 0xb2bec3);

    // Progression de la fournée : une pastille par commande.
    this.progressDots = [];
    for (let i = 0; i < ORDERS_PER_RUN; i++) {
      this.progressDots.push(this.add.circle(320 + i * 34, 36, 11, 0xffffff).setStrokeStyle(3, 0x6d4c1b));
    }

    // Zone de découpe.
    this.add.text(90, 420, 'Découper en parts égales :', { fontSize: '17px', color: '#6d4c1b' });
    [2, 3, 4, 6, 8].forEach((den, i) => {
      this.makeButton(120 + i * 78, 480, `${den}`, () => this.cutTart(den), 0xe17055, 56);
    });

    // L'assiette de service.
    this.add.circle(PLATE.x, PLATE.y, 92, 0xffffff).setStrokeStyle(4, 0xb2bec3);
    const plateZone = this.add.circle(PLATE.x, PLATE.y, 100, 0x000000, 0.001);
    plateZone.setInteractive(new Phaser.Geom.Circle(0, 0, 100), Phaser.Geom.Circle.Contains);
    plateZone.on('pointerdown', () => this.removeLastFromPlate());
    this.add.text(PLATE.x, 508, "Sur l'assiette :", { fontSize: '16px', color: '#6d4c1b' }).setOrigin(0.5, 0);

    this.bubbleText = this.add.text(560, 70, '', {
      fontSize: '18px', color: '#2d3436', wordWrap: { width: 250 }, backgroundColor: '#ffffff', padding: { x: 12, y: 10 },
    });
    this.feedbackText = this.add.text(560, 190, '', { fontSize: '17px', color: '#c0392b', wordWrap: { width: 300 }, fontStyle: 'bold' });

    this.makeButton(PLATE.x, 570, 'Servir !', () => this.serve(), 0x6ab04c, 140);

    this.startOrder();
  }

  private startOrder() {
    const order = this.orders[this.orderIndex];
    const worker = WORKERS[this.orderIndex % WORKERS.length];
    this.wrongServes = 0;
    this.feedbackText.setText('');

    this.workerSprite?.destroy();
    const body = this.add.image(0, 0, worker.texture).setScale(4);
    const name = this.add.text(0, -52, worker.name, { fontSize: '15px', color: '#2d3436', fontStyle: 'bold' }).setOrigin(0.5);
    this.workerSprite = this.add.container(500, 110, [body, name]);

    this.bubbleText.setText(`« Je voudrais ${orderInWords(order)} de tarte, s'il te plaît ! »`);
    this.orderFraction?.container.destroy();
    this.orderFraction = this.makeFraction(880, 110, order.num, order.den, 30);

    this.newTart();
  }

  // Une tarte entière sur le plan de travail ; toute découpe repart de là.
  private newTart() {
    this.wholeTart?.destroy();
    this.slices.forEach((s) => s.g.destroy());
    this.slices = [];
    this.cutDen = null;
    this.updatePlateLabel();

    const crust = this.add.circle(0, 0, SLICE_RADIUS, 0xf0932b).setStrokeStyle(4, 0xc0741a);
    const filling = this.add.circle(0, 0, SLICE_RADIUS - 14, 0xd35400);
    this.wholeTart = this.add.container(TART.x, TART.y, [crust, filling]);
  }

  private cutTart(den: number) {
    if (this.busy) return;
    this.newTart();
    this.wholeTart?.destroy();
    this.wholeTart = undefined;
    this.cutDen = den;

    const angle = (Math.PI * 2) / den;
    for (let i = 0; i < den; i++) {
      const g = this.add.graphics();
      g.fillStyle(0xf0932b);
      g.slice(0, 0, SLICE_RADIUS, -angle / 2, angle / 2);
      g.fillPath();
      g.lineStyle(3, 0xc0741a);
      g.slice(0, 0, SLICE_RADIUS, -angle / 2, angle / 2);
      g.strokePath();
      g.setPosition(ROW.x + i * ROW.step, ROW.y);
      g.setRotation(-Math.PI / 2); // pointe vers le haut dans la rangée
      g.setInteractive(new Phaser.Geom.Circle(SLICE_RADIUS * 0.55, 0, 26), Phaser.Geom.Circle.Contains);
      const slice: Slice = { g, rowIndex: i, onPlate: false };
      g.on('pointerdown', () => this.moveToPlate(slice));
      this.slices.push(slice);
    }
    this.updatePlateLabel();
  }

  private plateSlices(): Slice[] {
    return this.slices.filter((s) => s.onPlate);
  }

  private moveToPlate(slice: Slice) {
    if (this.busy || slice.onPlate) return;
    slice.onPlate = true;
    slice.g.disableInteractive();
    this.layoutPlate();
    this.updatePlateLabel();
  }

  private removeLastFromPlate() {
    if (this.busy) return;
    const onPlate = this.plateSlices();
    const last = onPlate[onPlate.length - 1];
    if (!last) return;
    last.onPlate = false;
    this.tweens.add({
      targets: last.g,
      x: ROW.x + last.rowIndex * ROW.step,
      y: ROW.y,
      rotation: -Math.PI / 2,
      duration: 200,
      onComplete: () => last.g.setInteractive(new Phaser.Geom.Circle(SLICE_RADIUS * 0.55, 0, 26), Phaser.Geom.Circle.Contains),
    });
    this.layoutPlate();
    this.updatePlateLabel();
  }

  // Les parts s'assemblent sur l'assiette en secteurs, à partir du haut : on VOIT la fraction.
  private layoutPlate() {
    const den = this.cutDen ?? 1;
    const angle = (Math.PI * 2) / den;
    this.plateSlices().forEach((slice, i) => {
      this.tweens.add({
        targets: slice.g,
        x: PLATE.x,
        y: PLATE.y,
        rotation: -Math.PI / 2 + angle * (i + 0.5),
        duration: 220,
      });
    });
  }

  private updatePlateLabel() {
    this.plateFraction?.container.destroy();
    this.plateFraction = undefined;
    if (this.cutDen === null) return;
    this.plateFraction = this.makeFraction(PLATE.x + 150, PLATE.y, this.plateSlices().length, this.cutDen, 26);
  }

  private serve() {
    if (this.busy) return;
    const order = this.orders[this.orderIndex];
    if (this.cutDen === null) {
      this.feedbackText.setText('Découpe d’abord la tarte !');
      return;
    }
    const count = this.plateSlices().length;
    if (this.cutDen !== order.den) {
      this.wrongServes++;
      this.feedbackText.setText('« Hmm… ces parts ne sont pas de la bonne taille pour moi ! »');
      return;
    }
    if (count < order.num) {
      this.wrongServes++;
      this.feedbackText.setText('« J’ai encore faim, il en manque ! »');
      return;
    }
    if (count > order.num) {
      this.wrongServes++;
      this.feedbackText.setText('« Oh là, c’est trop pour moi ! »');
      return;
    }

    // Commande exacte : on enregistre la réussite (parfaite si aucun service raté).
    const perfect = this.wrongServes === 0;
    record('FRA-01', perfect);
    record('FRA-02', perfect);
    this.progressDots[this.orderIndex].setFillStyle(0x6ab04c);
    this.feedbackText.setColor('#27ae60').setText('« Merci, c’est exactement ça ! »');
    this.busy = true;

    this.time.delayedCall(1300, () => {
      this.feedbackText.setColor('#c0392b').setText('');
      this.busy = false;
      this.orderIndex++;
      if (this.orderIndex >= ORDERS_PER_RUN) {
        this.finish();
      } else {
        this.startOrder();
      }
    });
  }

  private finish() {
    save.missions.bakery++;
    persist();
    this.add.rectangle(480, 320, 960, 640, 0x2d3436, 0.75).setInteractive(); // bloque les clics vers les boutons en dessous
    this.add.rectangle(480, 300, 640, 260, 0xffffff).setStrokeStyle(4, 0x6d4c1b);
    this.add.text(480, 220, 'Fournée terminée !', { fontSize: '30px', color: '#6d4c1b', fontStyle: 'bold' }).setOrigin(0.5);
    this.add.text(480, 290, 'Marta : « Merci ! Les ouvriers sont rassasiés.\nVa voir Bram, le chantier du pont peut commencer ! »', {
      fontSize: '18px', color: '#2d3436', align: 'center',
    }).setOrigin(0.5);
    this.makeButton(480, 380, 'Retour au village', () => this.scene.start('village'), 0x6ab04c, 220);
  }

  // Écriture fractionnaire empilée (numérateur, barre, dénominateur) — la vraie notation.
  private makeFraction(x: number, y: number, num: number, den: number, size: number): FractionDisplay {
    const style = { fontSize: `${size}px`, color: '#2d3436', fontStyle: 'bold' };
    const numText = this.add.text(0, -size * 0.65, `${num}`, style).setOrigin(0.5);
    const denText = this.add.text(0, size * 0.65, `${den}`, style).setOrigin(0.5);
    const bar = this.add.rectangle(0, 0, size * 1.4, 3, 0x2d3436);
    const container = this.add.container(x, y, [numText, bar, denText]);
    return { container, numText, denText };
  }

  private makeButton(x: number, y: number, label: string, onClick: () => void, color: number, width?: number) {
    const text = this.add.text(0, 0, label, { fontSize: '18px', color: '#ffffff', fontStyle: 'bold' }).setOrigin(0.5);
    const w = width ?? text.width + 36;
    const rect = this.add.rectangle(0, 0, w, 42, color).setStrokeStyle(3, 0x2d3436);
    const container = this.add.container(x, y, [rect, text.setDepth(1)]);
    rect.setInteractive({ useHandCursor: true });
    rect.on('pointerdown', onClick);
    return container;
  }
}

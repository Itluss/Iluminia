import Phaser from 'phaser';
import { gameState, uiOpen } from '../state';
import { Player, HERO_HEIGHT, type MoveKeys } from '../entities/Player';
import { CharacterRig } from '../characters/CharacterRig';
import { loadHeroParts } from '../characters/loadHeroParts';
import { Lina } from '../entities/Lina';
import { Fox } from '../entities/Fox';
import { Hud } from '../ui/Hud';
import { QuestTracker } from '../ui/QuestTracker';
import { setupUiCamera, worldTag } from '../ui/uiLayer';
import { DialogueBox } from '../ui/DialogueBox';
import { QuestionPanel } from '../ui/QuestionPanel';
import { InventoryPanel } from '../ui/InventoryPanel';
import { QuestPanel } from '../ui/QuestPanel';
import { MapPanel } from '../ui/MapPanel';
import { addGlowTexture } from '../utils/textures';
import { buildEnvironmentFx } from '../fx/environment';

// Monde ouvert : UNE seule image continue (village-world.png, 2544×3792,
// natif ×1), peinte en un seul passage (aucun raccord entre deux décors
// séparés) — les 2 tentatives précédentes recollaient deux images
// indépendantes (même moteur, même mesure) et gardaient toujours une ligne
// de jonction visible (luminosité, style). La Place (bas de l'image, y grand)
// et le Bourg-nord (haut de l'image, y petit) sont les deux carrefours de
// CETTE image, reliés par un unique chemin continu en leur centre — aucune
// coupure possible puisque c'est un seul fichier peint d'un coup.
//
// Chemin ouvert au bord haut (futur voisin au nord) et au bord bas (futur
// voisin au sud) — réservés, non exploités dans cette itération (pas encore
// de 3e zone). Bordure fermée ailleurs (forêt/falaise/rivière décorative).
const WORLD_W = 2544;
const WORLD_H = 3792;
// zone praticable (hors forêt, eau, façades), en repère monde
const WALK = { x: 150, y: 150, w: WORLD_W - 300, h: WORLD_H - 300 };

export class VillageScene extends Phaser.Scene {
  private player!: Player;
  private lina!: Lina;
  private fox!: Fox;
  private hud!: Hud;
  private questTracker!: QuestTracker;
  private moveKeys!: MoveKeys;
  private hint!: Phaser.GameObjects.Container;
  private hintShown = false;
  private dialogue: DialogueBox | null = null;
  private sidePanel: { close(onDone?: () => void): void } | null = null;
  private lookX = 0;
  private isDraggingCam = false;
  private dragPointerX = 0;
  private dragPointerY = 0;
  private dragScrollX = 0;
  private dragScrollY = 0;
  private maxZoom = 1;
  private minZoom = 1;
  private targetZoom = 1;

  constructor() {
    super('village');
  }

  create() {
    // — un seul décor, en résolution native, très en arrière-plan
    this.add.image(0, 0, 'village').setOrigin(0).setDepth(-1_000_000);

    this.physics.world.setBounds(WALK.x, WALK.y, WALK.w, WALK.h);
    const solids = this.buildColliders();

    this.player = new Player(this, 1000, 3050);
    this.fox = new Fox(this, 930, 3080);
    // près de l'étal du marché de la Place
    this.lina = new Lina(this, 1400, 2550);

    const linaBlock = this.add.rectangle(1400, 2546, 40, 18, 0, 0);
    this.physics.add.existing(linaBlock, true);
    solids.push(linaBlock);
    solids.forEach(s => this.physics.add.collider(this.player, s));
    this.loadHeroRig();

    // — vie ambiante générée depuis le décor
    this.buildVillageAmbiance();
    this.buildLanternGlow();
    buildEnvironmentFx(this);

    // — caméra : suivi doux, joueur sous le centre, zoom calé sur un carrefour
    const cam = this.cameras.main;
    cam.setBounds(26, 26, WORLD_W - 52, WORLD_H - 52);
    cam.startFollow(this.player, false, 0.09, 0.09);
    cam.setFollowOffset(0, Math.round(this.scale.height * 0.14));
    // zoom de jeu normal : calé sur la hauteur d'un seul carrefour (moitié du monde)
    const HUB_H = WORLD_H / 2;
    const baseZoom = Math.max(1.06, (this.scale.width / (WORLD_W - 52)) * 1.01, (this.scale.height / (HUB_H - 52)) * 1.01);
    cam.setZoom(baseZoom + 0.1);
    cam.fadeIn(900, 12, 10, 6);
    this.tweens.add({ targets: cam, zoom: baseZoom, duration: 1700, ease: 'Sine.out' });
    // — molette : dézoome pour voir tout le monde (les deux carrefours),
    // sans jamais dépasser le zoom de jeu normal (baseZoom) en zoomant.
    this.maxZoom = baseZoom;
    this.minZoom = Math.min(this.scale.width / WORLD_W, this.scale.height / WORLD_H);
    this.targetZoom = baseZoom;

    // — « Appuie sur E » sur une petite plaque de bois, en fondu au-dessus de Lina
    const hintPlaque = this.add.nineslice(0, 0, 'plaque-sm', undefined, 172, 46, 22, 22, 20, 20);
    const hintText = this.add
      .text(0, 0, 'Appuie sur E', {
        fontFamily: "'Baloo2', 'Segoe UI', sans-serif",
        fontSize: '16px',
        fontStyle: 'bold',
        color: '#5a3a16',
      })
      .setOrigin(0.5);
    this.hint = this.add.container(this.lina.x, this.lina.y - 160, [hintPlaque, hintText]);
    this.hint.setDepth(1500).setAlpha(0);

    this.hud = new Hud(this, {
      onQuests: () => this.openSidePanel(close => new QuestPanel(this, close)),
      onInventory: () => this.openSidePanel(close => new InventoryPanel(this, close)),
      onMap: () =>
        this.openSidePanel(
          close =>
            new MapPanel(
              this,
              { playerX: this.player.x, playerY: this.player.y, linaX: this.lina.x, linaY: this.lina.y },
              close,
            ),
        ),
    });
    this.questTracker = new QuestTracker(this);

    // — contrôles
    const kb = this.input.keyboard!;
    const key = (c: keyof typeof Phaser.Input.Keyboard.KeyCodes) =>
      kb.addKey(Phaser.Input.Keyboard.KeyCodes[c]);
    this.moveKeys = {
      up: [key('UP'), key('Z'), key('W')],
      down: [key('DOWN'), key('S')],
      left: [key('LEFT'), key('Q'), key('A')],
      right: [key('RIGHT'), key('D')],
    };
    const interact = (e: KeyboardEvent) => {
      if (!e.repeat) this.tryInteract();
    };
    kb.on('keydown-E', interact);
    kb.on('keydown-ENTER', interact);

    // la caméra UI (sans zoom ni scroll) prend le relais pour toute l'interface
    setupUiCamera(this);

    // — pan caméra au clic gauche maintenu : détache le suivi du joueur le
    // temps du drag, reprend le suivi normal au relâchement.
    this.input.on('pointerdown', (pointer: Phaser.Input.Pointer) => {
      if (!pointer.leftButtonDown() || uiOpen()) return;
      const c = this.cameras.main;
      this.isDraggingCam = true;
      this.dragPointerX = pointer.x;
      this.dragPointerY = pointer.y;
      this.dragScrollX = c.scrollX;
      this.dragScrollY = c.scrollY;
      c.stopFollow();
    });
    this.input.on('pointermove', (pointer: Phaser.Input.Pointer) => {
      if (!this.isDraggingCam) return;
      if (!pointer.leftButtonDown()) {
        this.stopCamDrag();
        return;
      }
      const c = this.cameras.main;
      c.scrollX = this.dragScrollX - (pointer.x - this.dragPointerX) / c.zoom;
      c.scrollY = this.dragScrollY - (pointer.y - this.dragPointerY) / c.zoom;
    });
    this.input.on('pointerup', () => this.stopCamDrag());
    this.input.on('pointerupoutside', () => this.stopCamDrag());

    // — molette : zoom avant/arrière, borné entre la vue d'ensemble
    // (minZoom) et le zoom de jeu normal (maxZoom).
    this.input.on(
      'wheel',
      (_pointer: Phaser.Input.Pointer, _objects: unknown, _dx: number, dy: number) => {
        if (uiOpen()) return;
        this.targetZoom = Phaser.Math.Clamp(
          this.targetZoom * (1 - dy * 0.001),
          this.minZoom,
          this.maxZoom,
        );
      },
    );
  }

  private stopCamDrag() {
    this.isDraggingCam = false;
  }

  update(_time: number, delta: number) {
    const dt = delta / 1000;
    if (uiOpen()) {
      this.player.halt();
      this.fox.update(dt, this.player.x, this.player.y, 0);
      this.showHint(false);
      return;
    }
    this.player.move(this.moveKeys, dt);
    this.fox.update(dt, this.player.x, this.player.y, this.player.dirX);
    this.showHint(this.lina.isPlayerClose(this.player));

    // anticipation caméra : le regard part légèrement devant le héros
    this.lookX = Phaser.Math.Linear(this.lookX, this.player.dirX * 46, Math.min(1, dt * 3));
    this.cameras.main.setFollowOffset(-this.lookX, Math.round(this.scale.height * 0.14));

    // zoom molette lissé : la caméra glisse vers targetZoom, jamais de saut
    this.cameras.main.zoom = Phaser.Math.Linear(
      this.cameras.main.zoom,
      this.targetZoom,
      Math.min(1, dt * 6),
    );
  }

  /** Charge les pièces approuvées du héros modulaire (Character Lab) et
   *  bascule le Player dessus une fois prêtes — sprite d'origine conservé
   *  comme repli tant que ce n'est pas chargé (aucun blocage du jeu). */
  private loadHeroRig() {
    const manifest = this.cache.json.get('hero-manifest');
    const rigData = this.cache.json.get('hero-rig');
    if (!manifest || !rigData) return;
    loadHeroParts(this, manifest, rigData, () => {
      const rig = new CharacterRig(this, this.player.x, this.player.y, rigData, HERO_HEIGHT);
      this.player.attachRig(rig);
    });
  }

  /** Lueur chaude des lampadaires des deux carrefours (positions mesurées sur
   *  `village-world.png`, grille 100px). Halo en blend ADD (bloom lumineux)
   *  + vacillement irrégulier façon flamme. */
  private buildLanternGlow() {
    addGlowTexture(this, 'lantern-glow', 90, '255,190,90');
    const lamps: [number, number][] = [
      // Bourg-nord (carrefour du haut)
      [930, 300],
      [1090, 215],
      [500, 860],
      // Place (carrefour du bas)
      [895, 2350],
      [1085, 2260],
      [855, 3230],
      [1215, 3230],
    ];
    for (const [x, y] of lamps) {
      const g = this.add
        .image(x, y, 'lantern-glow')
        .setBlendMode(Phaser.BlendModes.ADD)
        .setDepth(y)
        .setScale(0.85)
        .setAlpha(0.55);
      this.tweens.add({
        targets: g,
        alpha: { from: 0.4, to: 0.65 },
        scale: { from: 0.78, to: 0.92 },
        duration: 900 + Math.random() * 500,
        yoyo: true,
        repeat: -1,
        ease: 'Sine.inOut',
        delay: Math.random() * 400,
      });
    }
  }

  /** Poussières lumineuses procédurales, réparties sur toute la hauteur du
   *  monde — l'asset dust-motes.png du sprint est inexploitable (image quasi
   *  noire) ; le reste des effets vient du sprint FX. */
  private buildVillageAmbiance() {
    addGlowTexture(this, 'mote-cream', 30, '255,240,210');
    for (let i = 0; i < 10; i++) {
      const x = 400 + (i % 5) * 400;
      const y = 500 + i * 330;
      const d = this.add.image(x, y, 'mote-cream').setDepth(940).setAlpha(0);
      d.setScale(0.5 + (i % 2) * 0.3);
      this.tweens.add({ targets: d, alpha: 0.12, duration: 1800, yoyo: true, repeat: -1, ease: 'Sine.inOut', delay: i * 400 });
      this.tweens.add({ targets: d, x: x + 60, y: y - 30, duration: 7000 + i * 900, yoyo: true, repeat: -1, ease: 'Sine.inOut' });
    }
  }

  private showHint(visible: boolean) {
    if (visible === this.hintShown) return;
    this.hintShown = visible;
    this.tweens.add({ targets: this.hint, alpha: visible ? 1 : 0, duration: 250, ease: 'Sine.out' });
  }

  /** Rectangles invisibles calés sur le décor (mesurés sur `village-world.png`,
   *  grille 100px) : les 4 bâtiments + la fontaine de chaque carrefour, plus
   *  les murs de bordure du monde entier. Le chemin central touche les bords
   *  haut et bas de l'image (ancrages réservés pour de futures zones) mais
   *  reste fermé tant qu'aucun voisin n'y est construit. */
  private buildColliders(): Phaser.GameObjects.Rectangle[] {
    const solids: Phaser.GameObjects.Rectangle[] = [];
    const solid = (x: number, y: number, w: number, h: number) => {
      const r = this.add.rectangle(x, y, w, h, 0, 0);
      this.physics.add.existing(r, true);
      solids.push(r);
    };

    // Bourg-nord (carrefour du haut)
    solid(630, 335, 400, 570);    // la chapelle au cristal
    solid(1230, 335, 200, 170);   // étal du marché
    solid(1725, 400, 750, 500);   // le moulin et sa roue (rivière à l'est)
    solid(495, 900, 650, 240);    // étals du marché, bas-gauche
    solid(1805, 990, 950, 420);   // le potager (citrouilles, choux)
    solid(1000, 680, 280, 260);   // fontaine du Bourg-nord

    // Place (carrefour du bas — spawn du joueur)
    solid(635, 2335, 390, 570);   // maison, près de la rivière
    solid(1295, 2350, 250, 300);  // étal du marché
    solid(1625, 2400, 410, 500);  // maison à côté du marché
    solid(575, 3265, 450, 570);   // maison, bas-gauche
    solid(1675, 3180, 690, 340);  // appentis de bois, bas-droit
    solid(1000, 2820, 280, 260);  // la fontaine centrale

    // murs de bordure du monde entier (fermés : aucun voisin construit)
    const left = WALK.x;
    const right = WALK.x + WALK.w;
    const top = WALK.y;
    const bottom = WALK.y + WALK.h;
    const THICK = 60;
    solid((left + right) / 2, top, right - left, THICK);
    solid((left + right) / 2, bottom, right - left, THICK);
    solid(left, (top + bottom) / 2, THICK, bottom - top);
    solid(right, (top + bottom) / 2, THICK, bottom - top);

    return solids;
  }

  // ---------- interactions ----------

  private tryInteract() {
    if (uiOpen()) return;
    if (!this.lina.isPlayerClose(this.player)) return;
    this.openDialogue();
  }

  private openDialogue() {
    gameState.dialogueOpen = true;
    this.player.halt();

    if (gameState.questionDone) {
      this.dialogue = new DialogueBox(this, {
        name: 'Lina',
        text: 'Merci ! Grâce à toi, nous pouvons commencer à réparer le pont.',
        buttonLabel: 'Fermer',
        onButton: () => this.closeDialogue(),
      });
      return;
    }

    this.dialogue = new DialogueBox(this, {
      name: 'Lina',
      text:
        'Le pont des fractions s’est effondré ! ' +
        'Pour le réparer, j’ai besoin de ton aide. ' +
        'Réponds correctement à cette question.',
      buttonLabel: 'Continuer',
      onButton: () => {
        this.dialogue?.close(() => {
          this.dialogue = null;
          new QuestionPanel(this, {
            onCorrectRewards: () => this.giveRewards(),
            onClose: () => {
              gameState.dialogueOpen = false;
            },
          });
        });
      },
    });
  }

  private closeDialogue() {
    this.dialogue?.close(() => {
      this.dialogue = null;
      gameState.dialogueOpen = false;
    });
  }

  /** Récompenses — une seule fois. */
  private giveRewards() {
    if (gameState.questionDone) return;
    gameState.questionDone = true;
    gameState.xp += 10;
    gameState.planches += 1;
    gameState.coins += 5;
    gameState.stars += 1;
    this.hud.refresh();
    this.questTracker.refresh();
    this.lina.questCompleted();

    const icon = this.add.image(this.lina.x - 26, this.lina.y - 110, 'icon-xp');
    icon.setScale(30 / icon.height).setDepth(1500);
    worldTag(icon);
    const float = this.add
      .text(this.lina.x + 14, this.lina.y - 110, '+10 XP', {
        fontFamily: "'Baloo2', 'Segoe UI', sans-serif",
        fontSize: '24px',
        fontStyle: 'bold',
        color: '#ffd94a',
      })
      .setOrigin(0.5)
      .setShadow(0, 2, 'rgba(30,22,10,0.9)', 4)
      .setDepth(1500);
    worldTag(float);
    this.tweens.add({
      targets: [icon, float],
      y: '-=46',
      alpha: 0,
      duration: 1500,
      ease: 'Sine.out',
      onComplete: () => {
        icon.destroy();
        float.destroy();
      },
    });
  }

  /** Un seul panneau latéral ouvert à la fois (Quêtes, Inventaire ou Carte). */
  private openSidePanel(factory: (close: () => void) => { close(onDone?: () => void): void }) {
    if (gameState.dialogueOpen) return;
    if (this.sidePanel) {
      const current = this.sidePanel;
      this.sidePanel = null;
      current.close(() => {
        gameState.inventoryOpen = false;
      });
      return;
    }
    gameState.inventoryOpen = true;
    const close = () => {
      this.sidePanel?.close(() => {
        this.sidePanel = null;
        gameState.inventoryOpen = false;
      });
    };
    this.sidePanel = factory(close);
  }
}

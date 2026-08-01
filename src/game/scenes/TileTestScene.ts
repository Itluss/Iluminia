import Phaser from 'phaser';
import { Player, type MoveKeys } from '../entities/Player';
import { trimAndDownscaleTexture } from '../utils/textures';

// Prototype isolé : monde en tuiles (Phaser Tilemap natif) en remplacement
// potentiel du diorama peint unique. Accès : http://localhost:5173/#tiletest
// N'affecte PAS VillageScene ni village-world.png.
//
// Index de tuiles dans tileset-prototype.png (voir build-tileset-atlas.mjs) :
// 0 herbe · 1 chemin-droit · 2 chemin-virage · 3 eau (bloquante) · 4 berge · 5 lisière
const TILE = 128;
const HERBE = 0;
const CHEMIN_DROIT = 1;
const CHEMIN_VIRAGE = 2;
const EAU = 3;
const BERGE = 4;
const LISIERE = 5;

const COLS = 22;
const ROWS = 16;

// mare : rectangle d'eau bordé de berge en haut/bas (seules orientations
// générées pour ce test minimal — voir buildMapData)
const POND_X0 = 10;
const POND_X1 = 14;
const POND_Y0 = 3;
const POND_Y1 = 5;

export class TileTestScene extends Phaser.Scene {
  private player!: Player;
  private moveKeys!: MoveKeys;

  constructor() {
    super('tiletest');
  }

  preload() {
    this.load.image('tileset-prototype', 'art/generated/tileset-prototype.png');
    this.load.image('decor-arbre-src', 'art/generated/decor-arbre.png');
    this.load.image('decor-fontaine-src', 'art/generated/decor-fontaine.png');
  }

  create() {
    // décor : alpha natif (gpt-image-1 transparent), juste rogner les marges
    // et normaliser la hauteur d'affichage — pas de détourage nécessaire.
    trimAndDownscaleTexture(this, 'decor-arbre-src', 'decor-arbre', 190);
    trimAndDownscaleTexture(this, 'decor-fontaine-src', 'decor-fontaine', 110);

    const data = this.buildMapData();
    const map = this.make.tilemap({ data, tileWidth: TILE, tileHeight: TILE });
    const tileset = map.addTilesetImage('tiles', 'tileset-prototype', TILE, TILE, 4, 8)!;
    const layer = map.createLayer(0, tileset, 0, 0)!;
    layer.setCollision(EAU);
    // rive basse de la mare : même tuile berge que la rive haute, retournée
    // verticalement (herbe/eau inversés) — pas de régénération nécessaire.
    for (let x = POND_X0; x <= POND_X1; x++) {
      const t = layer.getTileAt(x, POND_Y1 + 1);
      if (t) t.flipY = true;
    }

    const worldW = COLS * TILE;
    const worldH = ROWS * TILE;
    this.physics.world.setBounds(0, 0, worldW, worldH);

    this.player = new Player(this, 3 * TILE, 12 * TILE);
    this.physics.add.collider(this.player, layer);

    const decor = this.physics.add.staticGroup();
    this.placeDecor(decor, 'decor-arbre', 8 * TILE, 11 * TILE, 22, 14);
    this.placeDecor(decor, 'decor-arbre', 17 * TILE, 12 * TILE, 22, 14);
    this.placeDecor(decor, 'decor-fontaine', 4.5 * TILE, 5 * TILE, 40, 22);
    this.physics.add.collider(this.player, decor);

    const cam = this.cameras.main;
    cam.setBounds(0, 0, worldW, worldH);
    cam.startFollow(this.player, false, 0.09, 0.09);
    cam.setZoom(1.15);

    const kb = this.input.keyboard!;
    const key = (c: keyof typeof Phaser.Input.Keyboard.KeyCodes) => kb.addKey(Phaser.Input.Keyboard.KeyCodes[c]);
    this.moveKeys = {
      up: [key('UP'), key('Z'), key('W')],
      down: [key('DOWN'), key('S')],
      left: [key('LEFT'), key('Q'), key('A')],
      right: [key('RIGHT'), key('D')],
    };

    this.add
      .text(16, 14, 'TILE TEST — prototype monde en tuiles (isolé de VillageScene)', {
        fontFamily: 'sans-serif',
        fontSize: '15px',
        color: '#ffffff',
        backgroundColor: '#00000080',
        padding: { x: 8, y: 4 },
      })
      .setScrollFactor(0)
      .setDepth(1000);
  }

  update(_t: number, delta: number) {
    this.player.move(this.moveKeys, delta / 1000);
  }

  /** Sprite de décor statique + corps de collision réduit à sa base (tronc,
   *  bassin) plutôt qu'à sa boîte englobante entière. */
  private placeDecor(group: Phaser.Physics.Arcade.StaticGroup, key: string, x: number, y: number, bw: number, bh: number) {
    const sprite = group.create(x, y, key) as Phaser.Physics.Arcade.Sprite;
    sprite.setOrigin(0.5, 1);
    sprite.setDepth(y);
    const body = sprite.body as Phaser.Physics.Arcade.StaticBody;
    body.setSize(bw, bh);
    body.setOffset((sprite.width - bw) / 2, sprite.height - bh);
  }

  /** Carte 2D construite en code (pas de Tiled) : bordure de lisière, un
   *  chemin qui tourne, une mare bordée de berge (haut + bas, seules
   *  orientations générées pour ce test minimal — gauche/droite en contact
   *  direct herbe/eau, limite connue et documentée dans le rapport). */
  private buildMapData(): number[][] {
    const g: number[][] = Array.from({ length: ROWS }, () => Array(COLS).fill(HERBE));

    // bordure : lisière de forêt sur tout le pourtour
    for (let x = 0; x < COLS; x++) {
      g[0][x] = LISIERE;
      g[ROWS - 1][x] = LISIERE;
    }
    for (let y = 0; y < ROWS; y++) {
      g[y][0] = LISIERE;
      g[y][COLS - 1] = LISIERE;
    }

    // chemin : droit sur la ligne 8, de la colonne 1 à 17, puis virage vers le bas
    const pathRow = 8;
    for (let x = 1; x <= 17; x++) g[pathRow][x] = CHEMIN_DROIT;
    g[pathRow][18] = CHEMIN_VIRAGE;

    // mare : rectangle d'eau bordé de berge en haut/bas (rive basse retournée
    // par flipY après création du layer, voir create())
    for (let y = POND_Y0; y <= POND_Y1; y++) {
      for (let x = POND_X0; x <= POND_X1; x++) g[y][x] = EAU;
    }
    for (let x = POND_X0; x <= POND_X1; x++) {
      g[POND_Y0 - 1][x] = BERGE;
      g[POND_Y1 + 1][x] = BERGE;
    }

    return g;
  }
}

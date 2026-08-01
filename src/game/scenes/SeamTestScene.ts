import Phaser from 'phaser';
import { Player, type MoveKeys } from '../entities/Player';

// Prototype isolé : teste la technique « monde en deux images invisibles »
// proposée par Camille (voir art/reviews/current-plan.md). Accès :
// http://localhost:5173/#seamtest — n'affecte PAS VillageScene ni
// village-world.png.
//
// village-west.png / village-east.png sont deux crops PURS (aucune
// génération IA) de la MÊME image source (public/art/generated/image.png),
// coupée en son centre — le raccord artistique est donc garanti par
// construction (pixels strictement adjacents des deux côtés de la coupe).
// Le vrai risque testé ici est la MÉCANIQUE de bascule : plutôt que de
// détruire/recréer une scène Phaser (ce qui recrée les touches clavier et
// peut perdre l'état « touche maintenue », rendant le mouvement visiblement
// interrompu), cette scène reste UNIQUE et vivante en permanence — seuls la
// texture de fond, la position locale du joueur et le scroll caméra sont
// basculés dans la même frame, sans jamais quitter la scène ni réinitialiser
// quoi que ce soit d'autre (clavier, physique, caméra).
const HALF_W = 816;
const HALF_H = 963;
const EDGE_MARGIN = 30; // distance du bord qui déclenche la bascule
const SPAWN_WEST = { x: 390, y: 250 }; // fontaine du carrefour haut (village-west.png)

type Side = 'west' | 'east';

export class SeamTestScene extends Phaser.Scene {
  private player!: Player;
  private moveKeys!: MoveKeys;
  private bg!: Phaser.GameObjects.Image;
  private side: Side = 'west';
  private label!: Phaser.GameObjects.Text;

  constructor() {
    super('seamtest');
  }

  preload() {
    this.load.image('seam-west', 'art/generated/village-west.png');
    this.load.image('seam-east', 'art/generated/village-east.png');
  }

  create() {
    this.bg = this.add.image(0, 0, 'seam-west').setOrigin(0).setDepth(-1_000_000);

    this.physics.world.setBounds(0, 0, HALF_W, HALF_H);
    this.player = new Player(this, SPAWN_WEST.x, SPAWN_WEST.y);

    const cam = this.cameras.main;
    cam.setBounds(0, 0, HALF_W, HALF_H);
    const baseZoom = Math.max(
      1.06,
      (this.scale.width / (HALF_W - 26)) * 1.01,
      (this.scale.height / (HALF_H - 26)) * 1.01,
    );
    cam.setZoom(baseZoom);
    cam.startFollow(this.player, false, 0.09, 0.09);
    cam.centerOn(this.player.x, this.player.y);

    const kb = this.input.keyboard!;
    const key = (c: keyof typeof Phaser.Input.Keyboard.KeyCodes) => kb.addKey(Phaser.Input.Keyboard.KeyCodes[c]);
    this.moveKeys = {
      up: [key('UP'), key('Z'), key('W')],
      down: [key('DOWN'), key('S')],
      left: [key('LEFT'), key('Q'), key('A')],
      right: [key('RIGHT'), key('D')],
    };

    this.label = this.add
      .text(16, 14, 'SEAM TEST — west (#seamtest)', {
        fontFamily: 'sans-serif',
        fontSize: '15px',
        color: '#ffffff',
        backgroundColor: '#00000080',
        padding: { x: 8, y: 4 },
      })
      .setScrollFactor(0)
      .setDepth(1000);

    // instrumentation QA uniquement (scripts/art-qa/seam-transition-check.mjs) :
    // permet de repérer l'instant exact de bascule sans dépendre de captures
    // d'écran coûteuses à haute fréquence. Sans effet en jeu normal.
    (window as unknown as {
      __seamDebug: () => { x: number; y: number; side: Side; scrollX: number; zoom: number };
    }).__seamDebug = () => ({
      x: this.player.x,
      y: this.player.y,
      side: this.side,
      scrollX: this.cameras.main.scrollX,
      zoom: this.cameras.main.zoom,
    });
  }

  update(_time: number, delta: number) {
    const dt = delta / 1000;
    this.player.move(this.moveKeys, dt);

    if (this.side === 'west' && this.player.x >= HALF_W - EDGE_MARGIN && this.player.dirX > 0) {
      this.switchSide('east', EDGE_MARGIN);
    } else if (this.side === 'east' && this.player.x <= EDGE_MARGIN && this.player.dirX < 0) {
      this.switchSide('west', HALF_W - EDGE_MARGIN);
    }
  }

  /** Bascule vers l'autre moitié SANS quitter la scène : la texture de fond,
   *  la position locale du joueur et le scroll caméra changent dans la même
   *  frame — à l'écran, le joueur ne bouge pas d'un pixel, seul le décor
   *  change. Aucune recréation de scène, de clavier ou de caméra.
   *
   *  Le scroll caméra est translaté du MÊME delta que le joueur (pas un
   *  `centerOn` qui recentrerait depuis zéro) : `centerOn` effacerait le
   *  léger retard de lissage du suivi (`startFollow` lerp 0.09), ce qui
   *  créerait un micro-saut caméra perceptible pile au moment de la bascule.
   *  screenX = (player.x - scrollX) * zoom est invariant si les deux
   *  translatent du même delta, quel que soit l'état du lissage en cours. */
  private switchSide(to: Side, newX: number) {
    const deltaX = newX - this.player.x;
    this.side = to;
    this.bg.setTexture(to === 'west' ? 'seam-west' : 'seam-east');
    this.player.setPosition(newX, this.player.y);
    this.cameras.main.scrollX += deltaX;
    this.label.setText(`SEAM TEST — ${to} (#seamtest)`);
  }
}

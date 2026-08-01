import Phaser from 'phaser';
import { perspScale } from '../utils/depth';
import { CharacterRig } from '../characters/CharacterRig';

const SPEED = 150;
export const HERO_HEIGHT = 145; // +25% (retour Camille 2026-07-31) — anciennement 116
const WALK_FRAME_MS = 150;       // ancienne alternance 2 poses (repli)
const CYCLE_FRAME_MS = 90;       // cycle de marche multi-frames
const WALK_NORM_H = 240;         // hauteur commune des frames préparées au boot
// ordre de lecture des planches (null = ordre séquentiel de la planche).
// side : 8 frames propres extraites d'une vidéo I2V (course fluide, boucle
// naturelle) — plus besoin d'écarter une frame défectueuse comme avant.
const WALK_ORDER: Record<'side' | 'front' | 'back', number[] | null> = {
  side: null,
  front: null,
  back: null,
};

export interface MoveKeys {
  up: Phaser.Input.Keyboard.Key[];
  down: Phaser.Input.Keyboard.Key[];
  left: Phaser.Input.Keyboard.Key[];
  right: Phaser.Input.Keyboard.Key[];
}

// Le héros : marche animée (2 poses générées), squash départ/arrêt,
// retournement interpolé, respiration, ombre dynamique, perspective 2.5D.
export class Player extends Phaser.Physics.Arcade.Sprite {
  private shadow: Phaser.GameObjects.Image;
  private baseScales: Record<string, number> = {};
  private currentKey = 'hero';
  private hasWalkFrame: boolean;
  private animCounts: Record<'side' | 'front' | 'back', number> = { side: 0, front: 0, back: 0 };
  private currentDir: 'side' | 'front' | 'back' = 'side';
  private breathT = 0;
  private walkT = 0;
  private walkFrameT = 0;
  private bounce = 0;
  private facing = 1;
  private displayFacing = 1;
  private wasMoving = false;
  private rig: CharacterRig | null = null;

  /** Direction horizontale courante (pour l'anticipation caméra). */
  dirX = 0;

  constructor(scene: Phaser.Scene, x: number, y: number) {
    super(scene, x, y, 'hero');
    scene.add.existing(this);
    scene.physics.add.existing(this);

    this.setOrigin(0.5, 1);
    this.hasWalkFrame = scene.textures.exists('hero-walk');
    // les textures n'ont pas toutes la même taille : hauteur affichée normalisée
    this.baseScales['hero'] = HERO_HEIGHT / this.height;
    if (this.hasWalkFrame) {
      const walk = scene.textures.get('hero-walk').getSourceImage() as HTMLImageElement;
      this.baseScales['hero-walk'] = HERO_HEIGHT / walk.height;
    }
    // frames du cycle de marche : échelle COMMUNE (espace normalisé 240 px)
    this.baseScales['walk'] = HERO_HEIGHT / WALK_NORM_H;
    (['side', 'front', 'back'] as const).forEach(d => {
      let n = 0;
      while (scene.textures.exists(`walk-${d}-${n}`)) n++;
      this.animCounts[d] = n;
    });
    this.setScale(this.baseScales['hero']);
    this.setCollideWorldBounds(true);
    this.fitBody();

    this.shadow = scene.add.image(x, y - 2, 'soft-shadow').setScale(0.56, 0.5).setAlpha(0.9);
  }

  halt() {
    this.setVelocity(0, 0);
    this.dirX = 0;
  }

  /** Bascule l'affichage vers le héros modulaire riggé (Character Lab) à
   *  l'arrêt : le sprite d'origine reste actif (physique, collisions) en
   *  permanence, mais devient invisible SEULEMENT quand le rig est montré.
   *  En déplacement, le rig n'a ni cycle de marche multi-directions ni vue
   *  de dos/profil (identité modulaire encore front-only) — on repasse donc
   *  sur l'ancien sprite animé (marche + orientation déjà au point) plutôt
   *  que de figer/casser le mouvement. Limite connue : le héros change
   *  visuellement d'un style à l'autre entre l'arrêt et la marche. */
  attachRig(rig: CharacterRig) {
    this.rig = rig;
    this.rig.container.setVisible(false);
  }

  move(keys: MoveKeys, dt: number) {
    const down = (ks: Phaser.Input.Keyboard.Key[]) => ks.some(k => k.isDown);
    let vx = 0;
    let vy = 0;
    if (down(keys.left)) vx = -1;
    else if (down(keys.right)) vx = 1;
    if (down(keys.up)) vy = -1;
    else if (down(keys.down)) vy = 1;

    if (vx !== 0 && vy !== 0) {
      vx *= Math.SQRT1_2;
      vy *= Math.SQRT1_2;
    }
    this.setVelocity(vx * SPEED, vy * SPEED);
    this.dirX = vx;

    const moving = vx !== 0 || vy !== 0;
    const hasCycle = this.animCounts.side > 0;

    if (moving && hasCycle) {
      // cycle de marche multi-frames, orienté selon la direction dominante
      let dir: 'side' | 'front' | 'back' = Math.abs(vx) >= Math.abs(vy) ? 'side' : vy > 0 ? 'front' : 'back';
      if (this.animCounts[dir] === 0) dir = 'side';
      if (dir !== this.currentDir) this.walkFrameT = 0;
      this.currentDir = dir;
      this.walkFrameT += dt * 1000;
      const seq = WALK_ORDER[dir];
      const count = seq ? seq.length : this.animCounts[dir];
      const step = Math.floor(this.walkFrameT / CYCLE_FRAME_MS) % count;
      const idx = seq ? seq[step] : step;
      const wanted = `walk-${dir}-${idx}`;
      if (wanted !== this.currentKey) {
        this.currentKey = wanted;
        this.setTexture(wanted);
        this.setOrigin(0.5, 1);
        this.fitBody();
      }
    } else if (this.hasWalkFrame && moving) {
      // repli : ancienne alternance 2 poses
      this.walkFrameT += dt * 1000;
      const wanted = Math.floor(this.walkFrameT / WALK_FRAME_MS) % 2 === 0 ? 'hero' : 'hero-walk';
      if (wanted !== this.currentKey) {
        this.currentKey = wanted;
        this.setTexture(wanted);
        this.setOrigin(0.5, 1);
        this.fitBody();
      }
    } else if (!moving && this.currentKey !== 'hero') {
      this.currentKey = 'hero';
      this.walkFrameT = 0;
      this.setTexture('hero');
      this.setOrigin(0.5, 1);
      this.fitBody();
    }

    // squash très bref au démarrage et à l'arrêt
    if (moving && !this.wasMoving) this.bounce = -0.07;
    if (!moving && this.wasMoving) this.bounce = 0.055;
    this.wasMoving = moving;
    this.bounce = Phaser.Math.Linear(this.bounce, 0, Math.min(1, dt * 9));

    this.breathT += dt;
    this.walkT = moving ? this.walkT + dt : 0;
    const usingCycle = moving && hasCycle;
    const breath = moving ? 0 : Math.sin(this.breathT * 2.4) * 0.012;
    // quand le vrai cycle joue, il porte le mouvement : plus de bob/roulis procédural
    const walkBob = moving && !usingCycle ? Math.abs(Math.sin(this.walkT * 9)) * 0.015 : 0;
    const targetRot = moving && !usingCycle ? Math.sin(this.walkT * 11) * 0.022 : 0;
    this.setRotation(Phaser.Math.Linear(this.rotation, targetRot, Math.min(1, dt * 14)));

    // le miroir horizontal ne vaut que pour la vue de profil (la planche
    // marche vers la droite). Face et dos : bascule INSTANTANÉE — interpoler
    // ferait passer le sprite par une épaisseur nulle (héros aminci/coupé).
    if (usingCycle && this.currentDir !== 'side') {
      this.facing = 1;
      this.displayFacing = 1;
    } else {
      if (vx !== 0) this.facing = vx > 0 ? 1 : -1;
      this.displayFacing = Phaser.Math.Linear(this.displayFacing, this.facing, Math.min(1, dt * 10));
    }

    // perspective 2.5D : plus petit vers le fond
    const persp = perspScale(this.y);
    const keyScale = this.currentKey.startsWith('walk-')
      ? this.baseScales['walk']
      : this.baseScales[this.currentKey] ?? this.baseScales['hero'];
    const base = keyScale * persp;
    this.setScale(base * this.displayFacing, base * (1 + breath + walkBob + this.bounce));

    // le rig (pose idle uniquement) ne remplace le sprite qu'à l'arrêt : pas
    // de cycle de marche multi-directions dans le puppet pour l'instant.
    const showRig = this.rig !== null && !moving;
    this.setVisible(!showRig);

    const shadowPulse = 1 + (breath + walkBob) * 3;
    // le rig porte une cape bien plus large que l'ancien sprite : l'ombre de
    // contact doit déborder de son ourlet pour rester visible sous les pieds.
    const shadowW = showRig ? 2.1 : 0.56;
    const shadowA = showRig ? 0.9 : moving ? 0.75 : 0.9;
    this.shadow
      .setPosition(this.x, this.y - 2)
      .setScale(shadowW * persp * shadowPulse, 0.5 * persp)
      .setAlpha(shadowA)
      .setDepth(this.y - 1);

    this.setDepth(this.y);

    if (this.rig) {
      this.rig.container.setVisible(showRig);
      if (showRig) {
        this.rig.container.setPosition(this.x, this.y);
        this.rig.container.setScale(persp * this.displayFacing, persp);
        this.rig.container.setDepth(this.y);
        this.rig.update(dt, false);
      }
    }
  }

  /** Corps physique constant en unités monde (~34×16 px aux pieds), quel que
   *  soit le format de la frame courante — les frames rognées du cycle ont
   *  toutes des dimensions différentes. */
  private fitBody() {
    const body = this.body as Phaser.Physics.Arcade.Body;
    const keyScale = this.currentKey.startsWith('walk-')
      ? this.baseScales['walk']
      : this.baseScales[this.currentKey] ?? this.baseScales['hero'];
    const bw = 34 / keyScale;
    const bh = 16 / keyScale;
    body.setSize(bw, bh);
    body.setOffset((this.width - bw) / 2, this.height - bh);
  }
}

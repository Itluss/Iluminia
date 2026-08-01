import Phaser from 'phaser';

// Rig 2D « puppet » Phaser natif : os hiérarchiques (transformations
// propagées manuellement — liste d'affichage PLATE pour un contrôle total
// de l'ordre de rendu), pièces attachées via hero.rig.json. Aucune
// coordonnée en dur ici : tout vient du manifeste et du rig.

interface Bone {
  id: string;
  parent: string | null;
  pos: [number, number];
  limits?: [number, number];
}
interface Slot {
  part: string;
  bone: string;
  pivot: [number, number];
  scale: number;
  z: number;
  offset?: [number, number];
  rotDeg?: number; // rotation de base : redresse une pièce peinte en biais
  group?: string;
  default?: boolean;
}
interface RigData {
  characterId: string;
  space: { width: number; height: number };
  bones: Bone[];
  slots: Slot[];
  idle: Record<string, number>;
  walk?: Record<string, number>;
}

interface BoneState {
  def: Bone;
  angle: number; // animation, en degrés
  dx: number;    // décalage d'animation (espace canonique, px)
  dy: number;
  worldX: number;
  worldY: number;
  worldAngle: number;
}

export class CharacterRig {
  readonly container: Phaser.GameObjects.Container;
  private scene: Phaser.Scene;
  private rig: RigData;
  private bones = new Map<string, BoneState>();
  private boneOrder: Bone[] = [];
  private images = new Map<string, Phaser.GameObjects.Image>();
  private slotByPart = new Map<string, Slot>();
  private activeByGroup = new Map<string, string>();
  private unit: number; // px canonique → px monde
  private t = 0;
  private timeScale = 1;
  private nextBlink = 3;
  private blinkUntil = -1;
  private debugG: Phaser.GameObjects.Graphics | null = null;
  private idleOn = true;

  /** Textures attendues : `char-<characterId>-<part>` (chargées par la scène). */
  constructor(scene: Phaser.Scene, x: number, y: number, rig: RigData, heightPx: number) {
    this.scene = scene;
    this.rig = rig;
    this.unit = heightPx / rig.space.height;
    this.container = scene.add.container(x, y);

    for (const b of rig.bones) {
      this.bones.set(b.id, { def: b, angle: 0, dx: 0, dy: 0, worldX: 0, worldY: 0, worldAngle: 0 });
    }
    // ordre parent → enfant garanti par tri topologique simple
    const placed = new Set<string>();
    while (this.boneOrder.length < rig.bones.length) {
      for (const b of rig.bones) {
        if (placed.has(b.id)) continue;
        if (b.parent === null || placed.has(b.parent)) {
          this.boneOrder.push(b);
          placed.add(b.id);
        }
      }
    }

    const sorted = [...rig.slots].sort((a, b2) => a.z - b2.z);
    for (const s of sorted) {
      const key = `char-${rig.characterId}-${s.part}`;
      if (!scene.textures.exists(key)) continue;
      const img = scene.add.image(0, 0, key);
      img.setOrigin(s.pivot[0], s.pivot[1]);
      this.container.add(img);
      this.images.set(s.part, img);
      this.slotByPart.set(s.part, s);
      if (s.group) {
        img.setVisible(!!s.default);
        if (s.default) this.activeByGroup.set(s.group, s.part);
      }
    }
    this.updateTransforms();
  }

  setTimeScale(v: number) { this.timeScale = v; }
  setIdle(on: boolean) { this.idleOn = on; }

  /** Bascule la pièce active d'un groupe (eyes, mouth). */
  setGroupPart(group: string, part: string) {
    const current = this.activeByGroup.get(group);
    if (current === part) return;
    if (current) this.images.get(current)?.setVisible(false);
    this.images.get(part)?.setVisible(true);
    this.activeByGroup.set(group, part);
  }

  setExpression(states: Record<string, Record<string, string>>, name: string) {
    const st = states[name];
    if (!st) return;
    if (st.eyes) this.setGroupPart('eyes', st.eyes);
    if (st.mouth) this.setGroupPart('mouth', st.mouth);
  }

  /** Idle procédural (respiration, poids, tête, bras, cape et cheveux en
   *  léger retard, clignement irrégulier) OU cycle de marche procédural
   *  (hanches/genoux/épaules en opposition de phase) si `moving`.
   *  NON UTILISÉ par Player.ts actuellement (toujours appelé avec `false`) :
   *  le retour visuel du 2026-07-31 signale un déhanchement disgracieux et
   *  des jambes qui se chevauchent (rotation FK pure sans IK ni tri de
   *  profondeur dynamique gauche/droite) — Player retombe sur l'ancien
   *  sprite animé pendant le déplacement. Code gardé pour une reprise
   *  future (walk_down, Phase 10-11) une fois ce défaut résolu. */
  update(dt: number, moving = false) {
    this.t += dt * this.timeScale;
    const t = this.t;

    if (this.idleOn) {
      const set = (id: string, angle: number, dx = 0, dy = 0) => {
        const b = this.bones.get(id);
        if (b) { b.angle = this.clampBone(b, angle); b.dx = dx; b.dy = dy; }
      };

      if (moving) {
        const wc = this.rig.walk ?? {};
        const w = 2 * Math.PI * (wc.strideHz ?? 1.8);
        const phase = t * w;
        const hipSwing = wc.hipSwingDeg ?? 26;
        const kneeBend = wc.kneeBendDeg ?? 34;
        const armSwing = wc.armSwingDeg ?? 20;
        set('hips', 0, 0, -Math.abs(Math.sin(phase)) * (wc.hipsBobPx ?? 2.5));
        set('torso', Math.sin(phase) * (wc.torsoRotDeg ?? 2));
        set('head', Math.sin(phase) * (wc.headRotDeg ?? 1.2));
        set('left_hip', Math.sin(phase) * hipSwing);
        set('right_hip', Math.sin(phase + Math.PI) * hipSwing);
        set('left_knee', Math.max(0, Math.sin(phase + Math.PI / 2)) * kneeBend);
        set('right_knee', Math.max(0, Math.sin(phase + Math.PI / 2 + Math.PI)) * kneeBend);
        set('left_shoulder', Math.sin(phase + Math.PI) * armSwing);
        set('right_shoulder', Math.sin(phase) * armSwing);
        set('cape_b', Math.sin(phase - 0.4) * (wc.capeRotDeg ?? 4));
      } else {
        const p = this.rig.idle;
        const w = 2 * Math.PI * (p.breathHz ?? 0.24);
        set('hips', 0, 0, Math.sin(t * w) * (p.hipsBobPx ?? 3));
        set('torso', Math.sin(t * w) * (p.torsoRotDeg ?? 1.1));
        set('head', (p.headTiltBiasDeg ?? 1.5) + Math.sin(t * w * 0.6 + 0.8) * (p.headRotDeg ?? 1.8));
        set('left_shoulder', Math.sin(t * w + 0.5) * (p.armRotDeg ?? 2.2));
        set('right_shoulder', Math.sin(t * w + 2.1) * -(p.armRotDeg ?? 2.2));
        set('cape_b', Math.sin((t - (p.capeLagSec ?? 0.35)) * w) * (p.capeRotDeg ?? 2.4));
        set('left_hip', 0);
        set('right_hip', 0);
        set('left_knee', 0);
        set('right_knee', 0);
      }

      // clignement irrégulier (actif en marche comme au repos)
      const p = this.rig.idle;
      if (this.t > this.nextBlink) {
        this.blinkUntil = this.t + (p.blinkDurSec ?? 0.13);
        this.nextBlink = this.t + Phaser.Math.FloatBetween(p.blinkMinSec ?? 2.6, p.blinkMaxSec ?? 4.8);
      }
      if (this.images.has('eyes_closed')) {
        this.setGroupPart('eyes', this.t < this.blinkUntil ? 'eyes_closed' : 'eyes_open');
      }
    }
    this.updateTransforms();
    if (this.debugG) this.drawDebug();
  }

  private clampBone(b: BoneState, angle: number): number {
    const lim = b.def.limits;
    return lim ? Phaser.Math.Clamp(angle, lim[0], lim[1]) : angle;
  }

  /** Propagation manuelle des transformations le long de la hiérarchie. */
  private updateTransforms() {
    const S = this.rig.space;
    for (const def of this.boneOrder) {
      const b = this.bones.get(def.id)!;
      const px = def.pos[0] * S.width;
      const py = def.pos[1] * S.height;
      if (!def.parent) {
        b.worldX = px + b.dx;
        b.worldY = py + b.dy;
        b.worldAngle = b.angle;
        continue;
      }
      const par = this.bones.get(def.parent)!;
      const parDef = par.def;
      const ox = px - parDef.pos[0] * S.width + b.dx;
      const oy = py - parDef.pos[1] * S.height + b.dy;
      const rad = Phaser.Math.DegToRad(par.worldAngle);
      const cos = Math.cos(rad);
      const sin = Math.sin(rad);
      b.worldX = par.worldX + ox * cos - oy * sin;
      b.worldY = par.worldY + ox * sin + oy * cos;
      b.worldAngle = par.worldAngle + b.angle;
    }
    const rootDef = this.rig.bones.find(b2 => !b2.parent)!;
    const rx = rootDef.pos[0] * S.width;
    const ry = rootDef.pos[1] * S.height;
    for (const [part, img] of this.images) {
      const slot = this.slotByPart.get(part)!;
      const b = this.bones.get(slot.bone)!;
      const offX = (slot.offset?.[0] ?? 0) * S.width;
      const offY = (slot.offset?.[1] ?? 0) * S.height;
      const rad = Phaser.Math.DegToRad(b.worldAngle);
      const cos = Math.cos(rad);
      const sin = Math.sin(rad);
      const wx = b.worldX + offX * cos - offY * sin;
      const wy = b.worldY + offX * sin + offY * cos;
      // ancre du conteneur = point au sol (root)
      img.setPosition((wx - rx) * this.unit, (wy - ry) * this.unit);
      img.setRotation(rad + Phaser.Math.DegToRad(slot.rotDeg ?? 0));
      img.setScale(slot.scale * this.unit);
    }
  }

  setDebug(on: boolean) {
    if (on && !this.debugG) {
      this.debugG = this.scene.add.graphics();
      this.container.add(this.debugG);
    } else if (!on && this.debugG) {
      this.debugG.destroy();
      this.debugG = null;
    }
  }

  private drawDebug() {
    const g = this.debugG!;
    const S = this.rig.space;
    const rootDef = this.rig.bones.find(b => !b.parent)!;
    const rx = rootDef.pos[0] * S.width;
    const ry = rootDef.pos[1] * S.height;
    g.clear();
    for (const def of this.boneOrder) {
      const b = this.bones.get(def.id)!;
      const x = (b.worldX - rx) * this.unit;
      const y = (b.worldY - ry) * this.unit;
      if (def.parent) {
        const par = this.bones.get(def.parent)!;
        g.lineStyle(2, 0x33ddff, 0.9);
        g.lineBetween((par.worldX - rx) * this.unit, (par.worldY - ry) * this.unit, x, y);
      }
      g.fillStyle(0xffdd33, 1);
      g.fillCircle(x, y, 4);
    }
  }
}

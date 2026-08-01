import Phaser from 'phaser';

// Caméra UI dédiée : l'interface n'est JAMAIS affectée par le zoom ni le
// scroll de la caméra du monde. Chaque objet d'UI est tagué via uiTag() ;
// les objets du monde créés APRÈS setupUiCamera() sont tagués via worldTag().

let uiCam: Phaser.Cameras.Scene2D.Camera | null = null;
let mainCam: Phaser.Cameras.Scene2D.Camera | null = null;
const pending: Phaser.GameObjects.GameObject[] = [];

export function uiTag(...objs: Phaser.GameObjects.GameObject[]) {
  if (uiCam && mainCam) {
    apply(objs);
  } else {
    pending.push(...objs);
  }
}

export function worldTag(...objs: Phaser.GameObjects.GameObject[]) {
  if (uiCam) uiCam.ignore(objs);
}

export function setupUiCamera(scene: Phaser.Scene) {
  mainCam = scene.cameras.main;
  uiCam = scene.cameras.add(0, 0, scene.scale.width, scene.scale.height);
  uiCam.setScroll(0, 0);
  // par défaut, la caméra UI ignore tout ce qui existe déjà (le monde)
  uiCam.ignore(scene.children.list);
  // puis les objets d'UI enregistrés lui sont rendus, et retirés du monde
  apply(pending.splice(0));
  scene.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
    uiCam = null;
    mainCam = null;
    pending.length = 0;
  });
}

function apply(objs: Phaser.GameObjects.GameObject[]) {
  if (!uiCam || !mainCam) return;
  for (const o of objs) {
    o.cameraFilter &= ~uiCam.id; // visible par la caméra UI
    o.cameraFilter |= mainCam.id; // invisible pour la caméra monde
  }
}

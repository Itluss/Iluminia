import Phaser from 'phaser';
import { BootScene } from './scenes/BootScene';
import { VillageScene } from './scenes/VillageScene';
import { LabScene } from './scenes/LabScene';
import { TileTestScene } from './scenes/TileTestScene';
import { SeamTestScene } from './scenes/SeamTestScene';

// Plein écran : hauteur logique fixe (540), largeur calée sur le ratio réel
// de la fenêtre (borné 16:9 → 21:9). Avec Scale.FIT, plus de bandes noires
// sur les écrans courants, et l'UI se positionne via scene.scale.
const aspect = Phaser.Math.Clamp(
  window.innerWidth / Math.max(1, window.innerHeight),
  16 / 9,
  21 / 9,
);
export const GAME_HEIGHT = 900; // résolution logique PC : l'UI garde des proportions de jeu moderne
export const GAME_WIDTH = Math.round((GAME_HEIGHT * aspect) / 2) * 2;

export const gameConfig: Phaser.Types.Core.GameConfig = {
  type: Phaser.AUTO,
  width: GAME_WIDTH,
  height: GAME_HEIGHT,
  parent: 'app',
  backgroundColor: '#1a1508',
  physics: {
    default: 'arcade',
    arcade: { debug: false },
  },
  scale: {
    mode: Phaser.Scale.FIT,
    autoCenter: Phaser.Scale.CENTER_BOTH,
  },
  scene: [BootScene, VillageScene, LabScene, TileTestScene, SeamTestScene],
};

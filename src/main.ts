import Phaser from 'phaser';
import { gameConfig } from './game/config';

// La police du jeu doit être prête avant que Phaser ne rende le moindre texte.
async function boot() {
  try {
    await Promise.all([
      document.fonts.load("600 16px 'Baloo2'"),
      document.fonts.load("800 16px 'Baloo2'"),
    ]);
  } catch {
    // la police système prendra le relais
  }
  const game = new Phaser.Game(gameConfig);
  // exposé pour les bancs de contrôle (scripts/dump-frames.mjs) — inoffensif en jeu
  (window as unknown as { __ELUMINIA_GAME: Phaser.Game }).__ELUMINIA_GAME = game;
}

boot();

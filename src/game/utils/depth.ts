import Phaser from 'phaser';

// Perspective 2.5D : les personnages rapetissent subtilement vers le fond.
// y = position des pieds dans le monde (décor diorama 2528×1696,
// zone praticable ≈ y 480→1335).
export function perspScale(y: number): number {
  return 0.84 + 0.16 * Phaser.Math.Clamp((y - 480) / (1335 - 480), 0, 1);
}

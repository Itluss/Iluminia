// Lecture/écriture de world.json et map-generation-spec.json — aucun état
// n'est mis à jour ailleurs que dans ces deux fichiers.
import { readFileSync, writeFileSync } from 'node:fs';
import { WORLD_JSON, SPEC_JSON } from './paths.mjs';

export function loadWorld() {
  return JSON.parse(readFileSync(WORLD_JSON, 'utf8'));
}

export function saveWorld(world) {
  writeFileSync(WORLD_JSON, JSON.stringify(world, null, 2) + '\n');
}

export function loadSpec() {
  return JSON.parse(readFileSync(SPEC_JSON, 'utf8'));
}

export function getChunk(world, id) {
  const chunk = world.chunks[id];
  if (!chunk) throw new Error(`Chunk introuvable dans world.json : ${id}`);
  return chunk;
}

export const OPPOSITE = { north: 'south', south: 'north', east: 'west', west: 'east' };

export function nextChunkId(id, direction) {
  const [x, y] = id.split('_').map(Number);
  const delta = { north: [0, -1], south: [0, 1], east: [1, 0], west: [-1, 0] }[direction];
  return `${x + delta[0]}_${y + delta[1]}`;
}

// Chemins partagés du pipeline d'extension de map — un seul endroit à
// modifier si la structure art/maps/ bouge.
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

export const ROOT = fileURLToPath(new URL('../../../', import.meta.url));

export const MAPS_DIR = resolve(ROOT, 'art/maps');
export const WORLD_JSON = resolve(MAPS_DIR, 'world.json');
export const SPEC_JSON = resolve(MAPS_DIR, 'map-generation-spec.json');
export const MASTERS_DIR = resolve(MAPS_DIR, 'masters');
export const MASKS_DIR = resolve(MAPS_DIR, 'masks');
export const CHUNKS_DIR = resolve(MAPS_DIR, 'chunks');
export const TILES_DIR = resolve(MAPS_DIR, 'tiles');
export const PREVIEWS_DIR = resolve(MAPS_DIR, 'previews');
export const QA_DIR = resolve(MAPS_DIR, 'qa');
export const HISTORY_DIR = resolve(MAPS_DIR, 'history');
export const SOURCE_DIR = resolve(MAPS_DIR, 'source');

// Fichiers compagnons d'une tuile fixe (art/maps/tiles/chunk_<gx>_<gy>/).
// Deux catégories, à ne jamais confondre :
//   - dérivés à 100% de world.json + de la géométrie de la tuile
//     (meta.json, connectors.json) : toujours réécrits par map:tiles.
//   - à auteur humain (collisions.json, objects.json, navigation.json) :
//     PAS dérivables d'un PNG peint sans une passe vision/heuristique dédiée
//     (hors périmètre ici) — créés vides seulement s'ils n'existent pas
//     encore, jamais écrasés, pour ne jamais perdre un travail manuel.
import { existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';

const SCAFFOLD_NOTE = 'scaffold vide — non dérivé automatiquement du PNG peint, à auteur manuellement ou via une passe vision dédiée future (voir docs/map-pipeline/README.md).';

function writeIfAbsent(path, content) {
  if (existsSync(path)) return false;
  writeFileSync(path, JSON.stringify(content, null, 2) + '\n');
  return true;
}

function writeAlways(path, content) {
  writeFileSync(path, JSON.stringify(content, null, 2) + '\n');
}

/** Projette les connecteurs déclarés dans world.json (fraction le long du bord
 * d'un chunk organique) en coordonnées absolues, et ne garde que ceux qui
 * tombent géométriquement dans la cellule logique de cette tuile. */
function projectConnectors(tile, world) {
  const projected = [];
  for (const chunk of Object.values(world.chunks)) {
    if (!chunk.connectors || !chunk.originPx) continue;
    const { x: ox, y: oy } = chunk.originPx;
    const w = chunk.widthPx;
    const h = chunk.heightPx;
    for (const [direction, list] of Object.entries(chunk.connectors)) {
      for (const c of list) {
        let absX, absY;
        if (direction === 'north') { absX = ox + c.position * w; absY = oy; }
        else if (direction === 'south') { absX = ox + c.position * w; absY = oy + h; }
        else if (direction === 'west') { absX = ox; absY = oy + c.position * h; }
        else { absX = ox + w; absY = oy + c.position * h; }

        const inCell = absX >= tile.cellRect.x && absX < tile.cellRect.x + tile.cellRect.width
          && absY >= tile.cellRect.y && absY < tile.cellRect.y + tile.cellRect.height;
        if (!inCell) continue;

        projected.push({
          type: c.type,
          absoluteX: Math.round(absX),
          absoluteY: Math.round(absY),
          widthPx: c.widthPx,
          required: c.required,
          transitionTheme: c.transitionTheme ?? null,
          sourceChunk: chunk.id,
          sourceDirection: direction,
        });
      }
    }
  }
  return projected;
}

export function scaffoldCompanionFiles(tileDir, tile, world) {
  mkdirSync(tileDir, { recursive: true });

  writeAlways(resolve(tileDir, 'meta.json'), {
    chunkId: tile.id,
    gx: tile.gx,
    gy: tile.gy,
    worldX: tile.cellRect.x,
    worldY: tile.cellRect.y,
    tileSize: tile.cellRect.width,
    coveredRect: tile.coveredRect,
    isPartial: tile.isPartial,
    pngOffsetInCell: tile.pngOffsetInCell,
    sources: tile.contributions.map(c => ({
      organicChunkId: c.chunkId,
      contributedRectPx: {
        x: tile.coveredRect.x + c.destOffsetInCovered.x,
        y: tile.coveredRect.y + c.destOffsetInCovered.y,
        width: c.srcRectLocal.width,
        height: c.srcRectLocal.height,
      },
    })),
    generatedAt: new Date().toISOString(),
  });

  writeAlways(resolve(tileDir, 'connectors.json'), {
    chunkId: tile.id,
    connectors: projectConnectors(tile, world),
  });

  writeIfAbsent(resolve(tileDir, 'collisions.json'), { chunkId: tile.id, colliders: [], note: SCAFFOLD_NOTE });
  writeIfAbsent(resolve(tileDir, 'objects.json'), { chunkId: tile.id, objects: [], note: SCAFFOLD_NOTE });
  writeIfAbsent(resolve(tileDir, 'navigation.json'), { chunkId: tile.id, walkableRects: [], note: SCAFFOLD_NOTE });
}

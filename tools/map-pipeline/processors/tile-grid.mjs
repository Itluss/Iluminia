// Grille fixe dérivée (tileSize x tileSize, ex. 2048x2048) pour le futur
// chargement Phaser — reconstruite à partir des masters organiques approuvés
// de world.json (taille variable, cumulatifs). Ne remplace ni ne modifie le
// pipeline d'extension organique : c'est une couche de lecture seule dérivée.
//
// Principe : chaque pixel absolu n'est lu que dans le master du chunk qui le
// possède EXCLUSIVEMENT (chunk.paintedRegionPx) — jamais dans un descendant
// qui le contient aussi en double (les masters organiques sont cumulatifs,
// voir composeAssembled() dans canvas.mjs). Comme cmdApprove (cli.mjs)
// garantit que les paintedRegionPx de tous les chunks approuvés sont
// disjoints, il n'y a jamais d'ambiguïté sur la source d'un pixel donné.
import { resolve } from 'node:path';
import { mkdirSync, writeFileSync } from 'node:fs';
import sharp from 'sharp';
import { toSharpRect, intersectRect } from '../lib/rect.mjs';
import { TILES_DIR } from '../lib/paths.mjs';
import { scaffoldCompanionFiles } from './tile-scaffold.mjs';

function unionRect(rects) {
  const minX = Math.min(...rects.map(r => r.x));
  const minY = Math.min(...rects.map(r => r.y));
  const maxX = Math.max(...rects.map(r => r.x + r.width));
  const maxY = Math.max(...rects.map(r => r.y + r.height));
  return { x: minX, y: minY, width: maxX - minX, height: maxY - minY };
}

/**
 * Géométrie pure, sans I/O pixel — même philosophie que planExtension()
 * dans canvas.mjs, utilisable telle quelle par --dry-run.
 */
export function planTileGrid(world, { tileSize = 2048 } = {}) {
  const chunks = Object.values(world.chunks).filter(c => c.status === 'approved' && c.paintedRegionPx);
  if (chunks.length === 0) {
    return { tileSize, bounds: null, gxRange: [0, -1], gyRange: [0, -1], tiles: [] };
  }

  const bounds = unionRect(chunks.map(c => c.paintedRegionPx));
  const gxRange = [Math.floor(bounds.x / tileSize), Math.floor((bounds.x + bounds.width - 1) / tileSize)];
  const gyRange = [Math.floor(bounds.y / tileSize), Math.floor((bounds.y + bounds.height - 1) / tileSize)];

  const tiles = [];
  for (let gy = gyRange[0]; gy <= gyRange[1]; gy++) {
    for (let gx = gxRange[0]; gx <= gxRange[1]; gx++) {
      const cellRect = { x: gx * tileSize, y: gy * tileSize, width: tileSize, height: tileSize };
      const rawContributions = [];
      for (const chunk of chunks) {
        const inter = intersectRect(cellRect, chunk.paintedRegionPx);
        if (inter) rawContributions.push({ chunk, interAbs: inter });
      }
      if (rawContributions.length === 0) continue; // pas de pixel peint dans cette cellule (trou dans un bbox non rectangulaire)

      const coveredRect = unionRect(rawContributions.map(c => c.interAbs));
      const contributions = rawContributions.map(({ chunk, interAbs }) => ({
        chunkId: chunk.id,
        chunkSource: chunk.source,
        srcRectLocal: {
          x: interAbs.x - chunk.originPx.x,
          y: interAbs.y - chunk.originPx.y,
          width: interAbs.width,
          height: interAbs.height,
        },
        destOffsetInCovered: { x: interAbs.x - coveredRect.x, y: interAbs.y - coveredRect.y },
      }));

      tiles.push({
        id: `chunk_${gx}_${gy}`,
        gx,
        gy,
        cellRect,
        coveredRect,
        isPartial: coveredRect.width < tileSize || coveredRect.height < tileSize,
        pngOffsetInCell: { x: coveredRect.x - cellRect.x, y: coveredRect.y - cellRect.y },
        contributions,
      });
    }
  }

  return { tileSize, bounds, gxRange, gyRange, tiles };
}

/** I/O réel — sharp uniquement, aucun appel réseau. */
export async function buildTileBackground(tile, worldRootAbs) {
  const layers = [];
  for (const c of tile.contributions) {
    const srcPath = resolve(worldRootAbs, c.chunkSource);
    const buf = await sharp(srcPath).removeAlpha().extract(toSharpRect(c.srcRectLocal)).toBuffer();
    layers.push({ input: buf, left: c.destOffsetInCovered.x, top: c.destOffsetInCovered.y });
  }
  return sharp({
    create: { width: tile.coveredRect.width, height: tile.coveredRect.height, channels: 3, background: { r: 0, g: 0, b: 0 } },
  })
    .composite(layers)
    .png()
    .toBuffer();
}

/** Écrit réellement la grille (background.png + fichiers compagnons) sous art/maps/tiles/. */
export async function refreshTileGrid(world, worldRootAbs, { tileSize = 2048 } = {}) {
  const plan = planTileGrid(world, { tileSize });
  const written = [];
  for (const tile of plan.tiles) {
    const dir = resolve(TILES_DIR, tile.id);
    mkdirSync(dir, { recursive: true });
    const background = await buildTileBackground(tile, worldRootAbs);
    writeFileSync(resolve(dir, 'background.png'), background);
    scaffoldCompanionFiles(dir, tile, world);
    written.push(tile.id);
  }
  return { plan, written };
}

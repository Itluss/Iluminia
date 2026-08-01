// Géométrie du canevas d'extension : construit le petit canevas envoyé à
// l'IA (bande de contexte protégée + zone vide à générer), puis recompose le
// master final en ne prenant JAMAIS un pixel généré dans la zone protégée —
// la protection est assurée ICI, localement, pas par un masque côté API
// (aucune des deux API disponibles ne le garantit, voir docs/map-extension-audit.md §8).
import sharp from 'sharp';
import { toSharpRect } from '../lib/rect.mjs';

const AXIS = { north: 'y', south: 'y', east: 'x', west: 'x' };
// growth : le sens dans lequel le nouveau master grandit par rapport à la source
const GROWS_FROM_START = { north: true, west: true, south: false, east: false };

/**
 * Calcule la géométrie d'une extension sans lire/écrire aucun pixel — utilisé
 * tel quel par --dry-run.
 */
export function planExtension({ sourceWidth, sourceHeight, direction, newSizePx, overlapPx }) {
  const axis = AXIS[direction];
  const growsFromStart = GROWS_FROM_START[direction];
  const fixedDim = axis === 'y' ? sourceWidth : sourceHeight; // dimension inchangée (largeur pour nord/sud, hauteur pour est/ouest)
  const sourceExtent = axis === 'y' ? sourceHeight : sourceWidth;

  if (overlapPx > sourceExtent) {
    throw new Error(`overlapPx (${overlapPx}) > dimension source disponible (${sourceExtent}) sur l'axe ${axis}`);
  }

  const contextCanvasExtent = overlapPx + newSizePx;
  const masterExtent = sourceExtent + newSizePx;

  return {
    direction,
    axis,
    growsFromStart,
    fixedDim,
    sourceExtent,
    newSizePx,
    overlapPx,
    // canevas envoyé à l'IA : petit, pas la map entière
    contextCanvas: axis === 'y'
      ? { width: fixedDim, height: contextCanvasExtent }
      : { width: contextCanvasExtent, height: fixedDim },
    // rectangles (dans le repère du contextCanvas) : le contexte protégé se
    // place du côté source (fin du canevas si on grandit depuis le début,
    // début du canevas sinon), la zone générable prend le reste.
    contextBandInCanvas: axis === 'y'
      ? { x: 0, y: growsFromStart ? newSizePx : 0, width: fixedDim, height: overlapPx }
      : { x: growsFromStart ? newSizePx : 0, y: 0, width: overlapPx, height: fixedDim },
    generableInCanvas: axis === 'y'
      ? { x: 0, y: growsFromStart ? 0 : overlapPx, width: fixedDim, height: newSizePx }
      : { x: growsFromStart ? 0 : overlapPx, y: 0, width: newSizePx, height: fixedDim },
    // d'où vient la bande de contexte DANS LA SOURCE
    contextBandInSource: axis === 'y'
      ? { x: 0, y: growsFromStart ? 0 : sourceHeight - overlapPx, width: sourceWidth, height: overlapPx }
      : { x: growsFromStart ? 0 : sourceWidth - overlapPx, y: 0, width: overlapPx, height: sourceHeight },
    // master final
    masterSize: axis === 'y'
      ? { width: fixedDim, height: masterExtent }
      : { width: masterExtent, height: fixedDim },
    // où la source (inchangée) se place dans le nouveau master
    sourceOffsetInMaster: axis === 'y'
      ? { x: 0, y: growsFromStart ? newSizePx : 0 }
      : { x: growsFromStart ? newSizePx : 0, y: 0 },
    // où la nouvelle zone (générée) se place dans le nouveau master
    newRegionOffsetInMaster: axis === 'y'
      ? { x: 0, y: growsFromStart ? 0 : sourceHeight }
      : { x: growsFromStart ? 0 : sourceWidth, y: 0 },
    newRegionSize: axis === 'y' ? { width: fixedDim, height: newSizePx } : { width: newSizePx, height: fixedDim },
    originShift: growsFromStart
      ? `le repère (0,0) du master se déplace de ${newSizePx}px sur l'axe ${axis} — toute coordonnée existante (colliders, PNJ, points d'interaction) devra être décalée de +${newSizePx} sur ${axis} lors de l'intégration Phaser`
      : `le repère (0,0) du master ne bouge pas — aucune coordonnée existante à décaler`,
  };
}

/**
 * Construit réellement le canevas (RGBA) + le masque à envoyer à l'IA.
 * Convention du masque : pixel OPAQUE = zone protégée (contexte, ne jamais
 * modifier) · pixel TRANSPARENT = zone générable. Cette convention n'est pas
 * garantie respectée par l'API (voir audit) — le masque est produit pour
 * documentation et pour un futur provider qui la respecterait ; la
 * protection réelle vient de composeAssembled() ci-dessous, jamais du masque.
 */
export async function buildExtensionCanvas(sourcePath, plan) {
  const band = plan.contextBandInSource;
  const bandBuf = await sharp(sourcePath).extract(toSharpRect(band)).png().toBuffer();

  const { width: cw, height: ch } = plan.contextCanvas;
  const bandPosInCanvas = plan.growsFromStart
    ? (plan.axis === 'y' ? { left: 0, top: plan.newSizePx } : { left: plan.newSizePx, top: 0 })
    : { left: 0, top: 0 };

  const canvas = await sharp({ create: { width: cw, height: ch, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } } })
    .composite([{ input: bandBuf, left: bandPosInCanvas.left, top: bandPosInCanvas.top }])
    .png()
    .toBuffer();

  const maskBandOpaque = await sharp({ create: { width: band.width, height: band.height, channels: 4, background: { r: 255, g: 255, b: 255, alpha: 1 } } })
    .png()
    .toBuffer();
  const mask = await sharp({ create: { width: cw, height: ch, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } } })
    .composite([{ input: maskBandOpaque, left: bandPosInCanvas.left, top: bandPosInCanvas.top }])
    .png()
    .toBuffer();

  return { canvas, mask, bandPosInCanvas };
}

/**
 * Recompose le master final : la zone source est reprise OCTET PAR OCTET
 * depuis le fichier source original (jamais depuis la réponse de l'IA), la
 * nouvelle zone vient uniquement de generatedExtensionBuffer (déjà rognée à
 * exactement plan.newRegionSize par l'appelant).
 */
export async function composeAssembled(sourcePath, plan, generatedExtensionBuffer) {
  const { width, height } = plan.masterSize;
  return sharp({ create: { width, height, channels: 3, background: { r: 0, g: 0, b: 0 } } })
    .composite([
      { input: sourcePath, left: plan.sourceOffsetInMaster.x, top: plan.sourceOffsetInMaster.y },
      { input: generatedExtensionBuffer, left: plan.newRegionOffsetInMaster.x, top: plan.newRegionOffsetInMaster.y },
    ])
    .png()
    .toBuffer();
}

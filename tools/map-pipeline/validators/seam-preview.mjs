// Validation §13 : image de contrôle de la couture — bande de 300-500px de
// chaque côté + ligne rouge exactement sur la frontière. Les contrôles
// géométriques/objectifs (continuité de teinte moyenne de part et d'autre)
// sont calculés ici ; la continuité SÉMANTIQUE (le chemin/la rivière
// continue-t-il vraiment, la perspective est-elle stable) reste du ressort de
// la revue visuelle (§14, art/maps/qa/<chunk>-visual-review.md) — ce n'est
// pas automatisable de façon fiable, ne pas prétendre le contraire.
import sharp from 'sharp';
import { toSharpRect } from '../lib/rect.mjs';

const BAND = 400;

export async function buildSeamPreview(assembledBuffer, plan, outPath) {
  const { width, height } = plan.masterSize;
  // coordonnée de la couture dans le master : la frontière entre la source
  // (inchangée) et la nouvelle zone, sur l'axe variable de l'extension.
  const seamCoord = plan.growsFromStart ? plan.newSizePx : plan.sourceExtent;

  const crop = plan.axis === 'y'
    ? { x: 0, y: Math.max(0, seamCoord - BAND), width, height: Math.min(height, seamCoord + BAND) - Math.max(0, seamCoord - BAND) }
    : { x: Math.max(0, seamCoord - BAND), y: 0, width: Math.min(width, seamCoord + BAND) - Math.max(0, seamCoord - BAND), height };

  const cropBuf = await sharp(assembledBuffer).extract(toSharpRect(crop)).png().toBuffer();
  const localSeam = plan.axis === 'y' ? seamCoord - crop.y : seamCoord - crop.x;

  const svgLine = plan.axis === 'y'
    ? `<svg width="${crop.width}" height="${crop.height}"><line x1="0" y1="${localSeam}" x2="${crop.width}" y2="${localSeam}" stroke="red" stroke-width="3" opacity="0.85"/></svg>`
    : `<svg width="${crop.width}" height="${crop.height}"><line x1="${localSeam}" y1="0" x2="${localSeam}" y2="${crop.height}" stroke="red" stroke-width="3" opacity="0.85"/></svg>`;

  await sharp(cropBuf).composite([{ input: Buffer.from(svgLine) }]).png().toFile(outPath);

  // continuité objective : teinte moyenne de bandes fines de part et d'autre
  // de la couture (signal grossier — un écart faible ne garantit PAS que le
  // chemin/la rivière se raccorde, seulement que la couleur ne "casse" pas)
  const stripThickness = 24;
  const beforeCrop = plan.axis === 'y'
    ? { x: 0, y: Math.max(0, seamCoord - stripThickness), width, height: stripThickness }
    : { x: Math.max(0, seamCoord - stripThickness), y: 0, width: stripThickness, height };
  const afterCrop = plan.axis === 'y'
    ? { x: 0, y: seamCoord, width, height: stripThickness }
    : { x: seamCoord, y: 0, width: stripThickness, height };

  // sharp ignore le .extract() précédent si .stats() est chaîné directement
  // dessus (constaté empiriquement : renvoie les stats de l'image ENTIÈRE,
  // pas de la zone extraite) — matérialiser l'extraction via .toBuffer()
  // d'abord, PUIS calculer les stats sur ce buffer isolé.
  const beforeBuf = await sharp(assembledBuffer).extract(toSharpRect(beforeCrop)).toBuffer();
  const afterBuf = await sharp(assembledBuffer).extract(toSharpRect(afterCrop)).toBuffer();
  const beforeStats = await sharp(beforeBuf).stats();
  const afterStats = await sharp(afterBuf).stats();
  const meanDiff = beforeStats.channels
    .map((c, i) => Math.abs(c.mean - afterStats.channels[i].mean))
    .reduce((a, b) => a + b, 0) / beforeStats.channels.length;

  return {
    seamPreviewPath: outPath,
    seamCoordInMaster: seamCoord,
    meanColorDiff: Number(meanDiff.toFixed(2)),
    meanColorDiffNote: meanDiff < 10
      ? 'écart de teinte faible de part et d\'autre de la couture — signal favorable, ne remplace pas la revue visuelle'
      : 'écart de teinte notable — rupture de ton probable, à vérifier prioritairement en revue visuelle',
  };
}

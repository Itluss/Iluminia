// Validation §12 : la zone protégée de l'assemblage final doit être
// IDENTIQUE octet pour octet à la map source d'origine. Vérifié ici par une
// vraie comparaison pixel par pixel (pas une confiance dans le code de
// composeAssembled, qui pourrait contenir un bug) : la seule preuve
// acceptable pour le critère d'acceptation n°1.
import sharp from 'sharp';

export async function checkProtectedPixels(sourcePath, assembledBuffer, plan) {
  // .removeAlpha() sur les deux côtés : composeAssembled() (composite sharp)
  // produit toujours une sortie RGBA même à partir d'entrées RGB, alors que
  // le fichier source original n'a pas de canal alpha — sans ce nettoyage,
  // la comparaison échoue systématiquement sur un désaccord de canaux qui
  // n'a rien à voir avec un vrai changement de pixel.
  const { data: srcData, info: srcInfo } = await sharp(sourcePath).removeAlpha().raw().toBuffer({ resolveWithObject: true });
  const { data: asmData, info: asmInfo } = await sharp(assembledBuffer)
    .extract({
      left: plan.sourceOffsetInMaster.x,
      top: plan.sourceOffsetInMaster.y,
      width: srcInfo.width,
      height: srcInfo.height,
    })
    .removeAlpha()
    .raw()
    .toBuffer({ resolveWithObject: true });

  if (srcInfo.width !== asmInfo.width || srcInfo.height !== asmInfo.height || srcInfo.channels !== asmInfo.channels) {
    return {
      identical: false,
      diffPixelCount: null,
      totalPixels: srcInfo.width * srcInfo.height,
      reason: `dimensions/canaux incohérents (source ${srcInfo.width}x${srcInfo.height}x${srcInfo.channels} vs extrait ${asmInfo.width}x${asmInfo.height}x${asmInfo.channels})`,
    };
  }

  let diffPixelCount = 0;
  let firstDiffAt = null;
  const totalPixels = srcInfo.width * srcInfo.height;
  for (let i = 0; i < srcData.length; i += srcInfo.channels) {
    let differs = false;
    for (let ch = 0; ch < srcInfo.channels; ch++) {
      if (srcData[i + ch] !== asmData[i + ch]) { differs = true; break; }
    }
    if (differs) {
      diffPixelCount++;
      if (firstDiffAt === null) {
        const pixelIndex = i / srcInfo.channels;
        firstDiffAt = { x: pixelIndex % srcInfo.width, y: Math.floor(pixelIndex / srcInfo.width) };
      }
    }
  }

  return {
    identical: diffPixelCount === 0,
    diffPixelCount,
    totalPixels,
    firstDiffAt,
    reason: diffPixelCount === 0 ? null : `${diffPixelCount} pixel(s) protégé(s) modifié(s) — reconstruire depuis la source, ne jamais approuver`,
  };
}

// Planche de contrôle visuelle (Phase 7) : toutes les dernières générations
// détourées d'un personnage sur une grille, avec étiquettes — pour la revue
// humaine et l'agent validateur.
import sharp from 'sharp';
import { readFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';

export async function buildContactSheet(manifest, workDir, outPath, { cell = 250, cols = 5 } = {}) {
  const genDir = join(workDir, 'generations');
  // dernière génération détourée par pièce
  const latest = new Map();
  for (const g of manifest.generationHistory ?? []) {
    if (g.keyedFile && g.status !== 'failed' && existsSync(join(workDir, g.keyedFile))) {
      latest.set(g.partId, g);
    }
  }
  const items = [...latest.entries()];
  if (!items.length) throw new Error('aucune génération détourée à afficher');

  const rows = Math.ceil(items.length / cols);
  const W = cols * cell;
  const H = rows * (cell + 28);
  const composites = [];
  for (let i = 0; i < items.length; i++) {
    const [partId, g] = items[i];
    const cx = (i % cols) * cell;
    const cy = Math.floor(i / cols) * (cell + 28);
    const img = await sharp(join(workDir, g.keyedFile))
      .resize(cell - 16, cell - 16, { fit: 'inside' })
      .png()
      .toBuffer();
    const meta = await sharp(img).metadata();
    composites.push({
      input: img,
      left: cx + Math.round((cell - meta.width) / 2),
      top: cy + Math.round((cell - 16 - meta.height) / 2) + 8,
    });
    const label = Buffer.from(
      `<svg width="${cell}" height="24"><text x="${cell / 2}" y="16" text-anchor="middle" font-family="Arial" font-size="13" fill="#333">${partId} (${g.status})</text></svg>`,
    );
    composites.push({ input: label, left: cx, top: cy + cell + 2 });
  }
  await sharp({ create: { width: W, height: H, channels: 4, background: { r: 236, g: 232, b: 224, alpha: 1 } } })
    .composite(composites)
    .png()
    .toFile(outPath);
  return { count: items.length, path: outPath };
}

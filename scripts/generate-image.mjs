// CLI de génération d'images (même moteur que le serveur MCP).
// Usage :
//   node scripts/generate-image.mjs --prompt "un renard magique" --filename renard.png
//     [--size 1024x1024|1536x1024|1024x1536|auto] [--transparent]
//     [--ref chemin.png ...]   (défaut : public/art/image.png, la bible)
//     [--no-style-ref]         (génération libre, sans référence)
import { generateImage, SIZES } from './lib/image-gen.mjs';

const args = process.argv.slice(2);
const opt = { references: null, transparent: false, size: '1024x1024' };
const refs = [];
for (let i = 0; i < args.length; i++) {
  switch (args[i]) {
    case '--prompt': opt.prompt = args[++i]; break;
    case '--filename': opt.filename = args[++i]; break;
    case '--size': opt.size = args[++i]; break;
    case '--transparent': opt.transparent = true; break;
    case '--ref': refs.push(args[++i]); break;
    case '--no-style-ref': opt.references = []; break;
    case '--engine': opt.engine = args[++i]; break;
    default:
      console.error(`Argument inconnu : ${args[i]}`);
      process.exitCode = 1;
  }
}
if (refs.length) opt.references = refs;

if (!opt.prompt || !opt.filename) {
  console.error('Usage : node scripts/generate-image.mjs --prompt "..." --filename nom.png');
  console.error(`Tailles : ${SIZES.join(', ')} · --transparent · --ref <png> · --no-style-ref`);
  process.exitCode = 1;
} else {
  try {
    const r = await generateImage(opt);
    console.log(`Image générée : ${r.publicPath} (${Math.round(r.bytes / 1024)} Ko)`);
    if (r.references.length) console.log(`Références de style : ${r.references.join(', ')}`);
  } catch (err) {
    console.error(`Échec : ${err.message}`);
    process.exitCode = 1;
  }
}

// Contrôles automatiques post-capture (ne remplace pas la revue IA).
// Usage : node scripts/visual-check.mjs
import { existsSync, readFileSync, statSync } from 'node:fs';
import { resolve } from 'node:path';

const failures = [];
const check = (ok, label) => {
  console.log(`${ok ? 'OK ' : 'FAIL'}  ${label}`);
  if (!ok) failures.push(label);
};

// 1. la capture existe, n'est pas vide, et a une taille d'image suffisante
const pngPath = resolve('art/reviews/latest.png');
if (!existsSync(pngPath)) {
  check(false, 'art/reviews/latest.png existe');
} else {
  const size = statSync(pngPath).size;
  check(size > 10_000, `latest.png non vide (${size} octets)`);
  const buf = readFileSync(pngPath);
  const isPng = buf.length > 24 && buf.readUInt32BE(0) === 0x89504e47;
  check(isPng, 'latest.png est un PNG valide');
  if (isPng) {
    const width = buf.readUInt32BE(16);
    const height = buf.readUInt32BE(20);
    check(width >= 900, `largeur >= 900 px (${width})`);
    check(height >= 500, `hauteur >= 500 px (${height})`);
  }
}

// 2. pas d'erreur navigateur critique
const errPath = resolve('art/reviews/browser-errors.json');
if (existsSync(errPath)) {
  const errors = JSON.parse(readFileSync(errPath, 'utf8'));
  const critical = errors.filter(
    e => e.type === 'pageerror' || e.type === 'fatal' || /failed|uncaught|cannot read/i.test(e.message),
  );
  check(critical.length === 0, `aucune erreur navigateur critique (${critical.length} trouvée(s))`);
  if (critical.length) critical.forEach(e => console.log(`      -> ${e.type}: ${e.message.slice(0, 160)}`));
} else {
  check(false, 'browser-errors.json existe (lancer npm run capture d’abord)');
}

// 3. le build existe
check(existsSync(resolve('dist/index.html')), 'dist/index.html existe (npm run build)');

// 4. les assets déclarés du manifest existent
const manifestPath = resolve('art/generated/manifest.json');
if (existsSync(manifestPath)) {
  const manifest = JSON.parse(readFileSync(manifestPath, 'utf8'));
  for (const asset of manifest.assets ?? []) {
    if (asset.source === 'existing' || asset.source === 'generated') {
      check(existsSync(resolve(asset.destination)), `asset présent : ${asset.destination}`);
    }
  }
} else {
  console.log('INFO  pas de manifest.json (aucune itération déclarée)');
}

if (failures.length) {
  console.error(`\n${failures.length} contrôle(s) en échec.`);
  process.exitCode = 1;
} else {
  console.log('\nTous les contrôles automatiques passent.');
}

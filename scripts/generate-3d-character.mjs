// Génération 3D d'un personnage via Meshy (multi-image-to-3D).
// Usage : node scripts/generate-3d-character.mjs
// Prérequis : MESHY_API_KEY dans l'environnement (voir CLAUDE.md).
// Premier essai (2026-08-07) : personnage "Max", planche 5 angles fournie
// par Camille, 4 vues (face/3-4 avant/profil/dos) recadrées proprement
// (sans texte/étiquettes) dans scripts/../art/generated/3d/max-views/.

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');

const API_KEY = process.env.MESHY_API_KEY;
if (!API_KEY) {
  console.error('MESHY_API_KEY absente. Voir CLAUDE.md (setx MESHY_API_KEY "msy_...").');
  process.exit(1);
}

const VIEWS_DIR = path.join(ROOT, 'art', 'generated', '3d', 'max-views');
const OUT_DIR = path.join(ROOT, 'art', 'generated', '3d');
const MODELS_DIR = path.join(ROOT, 'public', 'models');

function toDataUri(filePath) {
  const buf = fs.readFileSync(filePath);
  return `data:image/png;base64,${buf.toString('base64')}`;
}

async function main() {
  const viewFiles = ['face.png', '3q_front.png', 'profile.png', 'back.png'];
  const image_urls = viewFiles.map(f => toDataUri(path.join(VIEWS_DIR, f)));

  console.log('Création de la tâche multi-image-to-3d...');
  const createRes = await fetch('https://api.meshy.ai/openapi/v1/multi-image-to-3d', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      image_urls,
      ai_model: 'latest',
      should_texture: true,
      enable_pbr: true,
      texture_resolution: '2k',
      target_polycount: 30000,
      should_remesh: true,
      target_formats: ['glb'],
    }),
  });

  if (!createRes.ok) {
    console.error('Échec création tâche :', createRes.status, await createRes.text());
    process.exit(1);
  }
  const { result: taskId } = await createRes.json();
  console.log('Tâche créée :', taskId);

  const pollUrl = `https://api.meshy.ai/openapi/v1/multi-image-to-3d/${taskId}`;
  let task;
  for (;;) {
    await new Promise(r => setTimeout(r, 8000));
    const res = await fetch(pollUrl, { headers: { Authorization: `Bearer ${API_KEY}` } });
    task = await res.json();
    console.log(`  statut=${task.status} progress=${task.progress ?? '?'}%`);
    if (task.status === 'SUCCEEDED' || task.status === 'FAILED' || task.status === 'CANCELED') break;
  }

  if (task.status !== 'SUCCEEDED') {
    console.error('Tâche non aboutie :', JSON.stringify(task, null, 2));
    process.exit(1);
  }

  fs.mkdirSync(OUT_DIR, { recursive: true });
  fs.mkdirSync(MODELS_DIR, { recursive: true });

  fs.writeFileSync(path.join(OUT_DIR, 'max-task.json'), JSON.stringify(task, null, 2));

  const glbUrl = task.model_urls?.glb;
  if (glbUrl) {
    const glbRes = await fetch(glbUrl);
    const glbBuf = Buffer.from(await glbRes.arrayBuffer());
    fs.writeFileSync(path.join(MODELS_DIR, 'max-character.glb'), glbBuf);
    console.log('GLB enregistré :', path.join(MODELS_DIR, 'max-character.glb'), `(${(glbBuf.length / 1024 / 1024).toFixed(2)} Mo)`);
  }

  if (task.thumbnail_url) {
    const thumbRes = await fetch(task.thumbnail_url);
    const thumbBuf = Buffer.from(await thumbRes.arrayBuffer());
    fs.writeFileSync(path.join(OUT_DIR, 'max-thumbnail.png'), thumbBuf);
    console.log('Vignette enregistrée :', path.join(OUT_DIR, 'max-thumbnail.png'));
  }

  console.log('Crédits consommés :', task.consumed_credits ?? '?');
}

main().catch(err => { console.error(err); process.exit(1); });

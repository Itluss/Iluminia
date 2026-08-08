// Rig + animations (marche/course) pour un personnage 3D déjà généré via
// Meshy (voir scripts/generate-3d-character.mjs). Étape 2 (2026-08-07,
// demande Camille) : "Max" glissait sans foulée dans l'arène — Meshy fournit
// gratuitement (~5 crédits) un rig + animations marche/course de base.
// Usage : node scripts/rig-3d-character.mjs

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

const OUT_DIR = path.join(ROOT, 'art', 'generated', '3d');
const MODELS_DIR = path.join(ROOT, 'public', 'models');
const SOURCE_TASK_JSON = path.join(OUT_DIR, 'max-task.json');

async function main() {
  const sourceTask = JSON.parse(fs.readFileSync(SOURCE_TASK_JSON, 'utf8'));
  const inputTaskId = sourceTask.id;
  console.log('Tâche source (multi-image-to-3d) :', inputTaskId);

  console.log('Création de la tâche de rigging...');
  const createRes = await fetch('https://api.meshy.ai/openapi/v1/rigging', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      input_task_id: inputTaskId,
      height_meters: 1.3, // enfant CM1-CM2, échelle réaliste (planche : "120-140cm")
    }),
  });

  if (!createRes.ok) {
    console.error('Échec création tâche :', createRes.status, await createRes.text());
    process.exit(1);
  }
  const { result: taskId } = await createRes.json();
  console.log('Tâche créée :', taskId);

  const pollUrl = `https://api.meshy.ai/openapi/v1/rigging/${taskId}`;
  let task;
  for (;;) {
    await new Promise(r => setTimeout(r, 6000));
    const res = await fetch(pollUrl, { headers: { Authorization: `Bearer ${API_KEY}` } });
    task = await res.json();
    console.log(`  statut=${task.status} progress=${task.progress ?? '?'}%`);
    if (task.status === 'SUCCEEDED' || task.status === 'FAILED' || task.status === 'CANCELED') break;
  }

  if (task.status !== 'SUCCEEDED') {
    console.error('Tâche non aboutie :', JSON.stringify(task, null, 2));
    process.exit(1);
  }

  fs.mkdirSync(MODELS_DIR, { recursive: true });
  fs.writeFileSync(path.join(OUT_DIR, 'max-rigging-task.json'), JSON.stringify(task, null, 2));

  const downloads = {
    'max-character-rigged.glb': task.result?.rigged_character_glb_url,
    'max-walk.glb': task.result?.basic_animations?.walking_glb_url,
    'max-run.glb': task.result?.basic_animations?.running_glb_url,
  };

  for (const [filename, url] of Object.entries(downloads)) {
    if (!url) { console.log('  (absent)', filename); continue; }
    const res = await fetch(url);
    const buf = Buffer.from(await res.arrayBuffer());
    fs.writeFileSync(path.join(MODELS_DIR, filename), buf);
    console.log('Enregistré :', filename, `(${(buf.length / 1024 / 1024).toFixed(2)} Mo)`);
  }

  console.log('Crédits consommés :', task.consumed_credits ?? '?');
}

main().catch(err => { console.error(err); process.exit(1); });

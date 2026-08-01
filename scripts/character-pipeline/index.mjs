// CLI du pipeline de personnages Eluminia (Phases 2→8, 16).
// Usage : node scripts/character-pipeline/index.mjs <commande> <characterId> [options]
// Commandes :
//   status <id>                       état des pièces et générations
//   dry-run <id> [--part <p>]         plan de génération : appels + coût, SANS appel API
//   generate <id> --part <p> [--force] génère UNE pièce (cache anti-doublon, versionné)
//   generate <id> --all --confirm      génère toutes les pièces manquantes (après dry-run)
//   process <id> --generation <gid>    détoure + rogne une génération brute
//   validate <id>                      contrôles automatiques → qa/validation-report.json
//   approve <id> --part <p> --generation <gid> [--force]  promeut une génération en pièce
//   init <newId>                       initialise un nouveau personnage depuis le template
import { readFileSync, writeFileSync, existsSync, mkdirSync, copyFileSync, readdirSync } from 'node:fs';
import { resolve, join } from 'node:path';
import { createHash } from 'node:crypto';
import { generateImage } from '../lib/image-gen.mjs';
import { keyAndTrim, validatePart } from './lib/png-keying.mjs';
import { buildContactSheet } from './lib/contact-sheet.mjs';
import { buildPrompt, PART_PROMPTS } from './prompts/parts.mjs';

const COST_PER_CALL = { '1024x1024': 0.134, '1024x1536': 0.24, '1536x1024': 0.24 }; // Banana 1K / 2K (USD)
const BUDGET_PER_RUN_USD = 3.0;
const MAX_ATTEMPTS_PER_PART = 3;

const args = process.argv.slice(2);
const cmd = args[0];
const charId = args[1];
const opt = {};
for (let i = 2; i < args.length; i++) {
  const a = args[i];
  if (a === '--force' || a === '--all' || a === '--confirm') opt[a.slice(2)] = true;
  else if (a.startsWith('--')) opt[a.slice(2)] = args[++i];
}

const pub = id => resolve(`public/art/characters/${id}`);
const work = id => resolve(`art/characters/${id}`);
const manifestPath = id => join(pub(id), 'character.manifest.json');

function loadManifest(id) {
  if (!existsSync(manifestPath(id))) throw new Error(`manifeste introuvable : ${manifestPath(id)} (utiliser init ?)`);
  return JSON.parse(readFileSync(manifestPath(id), 'utf8'));
}
function saveManifest(id, m) {
  writeFileSync(manifestPath(id), JSON.stringify(m, null, 2));
}
function validateManifest(m) {
  const errs = [];
  for (const k of ['characterId', 'displayName', 'version', 'canonicalHeight', 'canvasWidth', 'canvasHeight', 'renderOrder', 'parts']) {
    if (m[k] === undefined) errs.push(`champ manquant : ${k}`);
  }
  const ids = new Set();
  for (const p of m.parts ?? []) {
    for (const k of ['id', 'filename', 'category', 'parent', 'zIndex', 'pivotX', 'pivotY', 'status']) {
      if (p[k] === undefined) errs.push(`pièce ${p.id ?? '?'} : champ manquant ${k}`);
    }
    if (ids.has(p.id)) errs.push(`pièce dupliquée : ${p.id}`);
    ids.add(p.id);
    if (p.parent !== 'root' && !ids.has(p.parent) && !(m.parts.some(q => q.id === p.parent))) {
      errs.push(`pièce ${p.id} : parent inconnu ${p.parent}`);
    }
  }
  for (const r of m.renderOrder ?? []) if (!ids.has(r)) errs.push(`renderOrder : pièce inconnue ${r}`);
  return errs;
}

const hash = s => createHash('sha1').update(s).digest('hex').slice(0, 12);
const fileHash = p => (existsSync(p) ? hash(readFileSync(p).toString('base64')) : 'absent');

function references(id, m) {
  const refs = [join(pub(id), m.sourceReference)];
  const master = join(pub(id), 'approved', 'master_front.png');
  if (existsSync(master)) refs.push(master);
  return refs.filter(existsSync);
}

function planFor(id, m, only) {
  const todo = [];
  const masterApproved = existsSync(join(pub(id), 'approved', 'master_front.png'));
  if (!masterApproved && (!only || only === 'master_front')) {
    todo.push({ partId: 'master_front', size: PART_PROMPTS.master_front.size, note: 'PRÉALABLE : à approuver avant les pièces' });
  }
  for (const p of m.parts) {
    if (only && p.id !== only) continue;
    if (!PART_PROMPTS[p.id]) continue;
    if (['approved'].includes(p.status)) continue;
    if (!only && !masterApproved) continue; // les pièces attendent le maître
    todo.push({ partId: p.id, size: PART_PROMPTS[p.id].size ?? '1024x1024' });
  }
  const cost = todo.reduce((s, t) => s + (COST_PER_CALL[t.size] ?? 0.134), 0);
  return { todo, cost };
}

function costsJournal(id) {
  const p = join(work(id), 'qa', 'costs.json');
  return { path: p, data: existsSync(p) ? JSON.parse(readFileSync(p, 'utf8')) : { totalUsd: 0, calls: [] } };
}

async function generateOne(id, m, partId, force) {
  const { prompt, size } = buildPrompt(partId);
  const refs = references(id, m);
  if (!refs.length) throw new Error(`aucune référence : déposer la planche dans ${join(pub(id), m.sourceReference)}`);
  const pHash = hash(prompt + size);
  const rHash = hash(refs.map(fileHash).join('+'));

  const dup = (m.generationHistory ?? []).find(
    g => g.partId === partId && g.promptHash === pHash && g.referenceHash === rHash && g.status !== 'failed',
  );
  if (dup && !force) {
    console.log(`↷ cache : génération équivalente existante pour ${partId} (${dup.generationId}) — utiliser --force pour régénérer`);
    return null;
  }
  const attempts = (m.generationHistory ?? []).filter(g => g.partId === partId).length;
  if (attempts >= MAX_ATTEMPTS_PER_PART && !force) {
    throw new Error(`${partId} : ${attempts} tentatives déjà — inspecter avant de régénérer (--force)`);
  }

  const journal = costsJournal(id);
  const cost = COST_PER_CALL[size] ?? 0.134;
  if (journal.data.totalUsd + cost > BUDGET_PER_RUN_USD * 10) {
    throw new Error(`budget cumulé dépassé (${journal.data.totalUsd.toFixed(2)} $) — augmenter BUDGET si volontaire`);
  }

  const genId = `gen-${new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19)}-${pHash.slice(0, 6)}`;
  console.log(`→ génération ${partId} (${size}, ~${cost.toFixed(2)} $) : ${genId}`);
  const tmpName = `pipeline-${genId}.png`;
  const r = await generateImage({ prompt, filename: tmpName, size, references: refs, engine: 'banana' });

  const genDir = join(work(id), 'generations');
  mkdirSync(genDir, { recursive: true });
  const rawPath = join(genDir, `${genId}.png`);
  copyFileSync(r.path, rawPath);

  // détourage + rognage automatiques (Phase 6)
  let processReport = null;
  const keyedPath = join(genDir, `${genId}.keyed.png`);
  try {
    processReport = await keyAndTrim(rawPath, keyedPath);
  } catch (err) {
    console.warn(`  ⚠ détourage échoué : ${err.message}`);
  }

  const meta = {
    generationId: genId,
    date: new Date().toISOString(),
    partId,
    engine: 'banana/gemini-3-pro-image',
    prompt,
    promptHash: pHash,
    referenceFiles: refs.map(f => f.replace(resolve('.') + '\\', '')),
    referenceHash: rHash,
    outputFile: `generations/${genId}.png`,
    keyedFile: processReport ? `generations/${genId}.keyed.png` : null,
    processReport,
    estimatedCostUsd: cost,
    status: 'needs_review',
  };
  writeFileSync(join(genDir, `${genId}.json`), JSON.stringify(meta, null, 2));
  m.generationHistory = [...(m.generationHistory ?? []), meta];
  const part = m.parts.find(p => p.id === partId);
  if (part && part.status === 'planned') part.status = 'generated';
  saveManifest(id, m);

  journal.data.totalUsd = Math.round((journal.data.totalUsd + cost) * 1000) / 1000;
  journal.data.calls.push({ date: meta.date, generationId: genId, partId, size, costUsd: cost });
  mkdirSync(join(work(id), 'qa'), { recursive: true });
  writeFileSync(journal.path, JSON.stringify(journal.data, null, 2));
  console.log(`  ✓ brut : ${rawPath}`);
  if (processReport) console.log(`  ✓ détouré : ${keyedPath} (${processReport.w}x${processReport.h})`);
  return meta;
}

async function main() {
  if (!cmd || (!charId && cmd !== 'help')) {
    console.log('Usage : node scripts/character-pipeline/index.mjs <status|dry-run|generate|process|validate|approve|init> <characterId> [options]');
    return;
  }

  if (cmd === 'init') {
    const dir = pub(charId);
    if (existsSync(join(dir, 'character.manifest.json'))) throw new Error(`${charId} existe déjà`);
    for (const d of ['references', 'approved', 'parts', 'rig', 'animations', 'exports']) mkdirSync(join(dir, d), { recursive: true });
    for (const d of ['generations', 'qa']) mkdirSync(join(work(charId), d), { recursive: true });
    const template = JSON.parse(readFileSync(manifestPath('hero'), 'utf8'));
    template.characterId = charId;
    template.displayName = charId;
    template.generationHistory = [];
    template.parts.forEach(p => { p.status = 'planned'; p.sourceGenerationId = null; });
    saveManifest(charId, template);
    console.log(`✓ ${charId} initialisé depuis le template hero (adapter le manifeste : proportions, pièces)`);
    return;
  }

  const m = loadManifest(charId);
  const errs = validateManifest(m);
  if (errs.length) {
    console.error(`Manifeste invalide :\n - ${errs.join('\n - ')}`);
    process.exitCode = 1;
    return;
  }

  if (cmd === 'status') {
    console.log(`${m.displayName} v${m.version} — ${m.parts.length} pièces`);
    const refOk = existsSync(join(pub(charId), m.sourceReference));
    console.log(`référence : ${m.sourceReference} ${refOk ? '✓' : '✗ MANQUANTE'}`);
    for (const p of m.parts) console.log(`  ${p.status.padEnd(12)} ${p.id}`);
    const j = costsJournal(charId).data;
    console.log(`générations : ${(m.generationHistory ?? []).length} · coût cumulé : ${j.totalUsd.toFixed(2)} $`);
    return;
  }

  if (cmd === 'dry-run') {
    const { todo, cost } = planFor(charId, m, opt.part);
    console.log(`Plan de génération (${charId}) — AUCUN appel effectué :`);
    for (const t of todo) console.log(`  ${t.partId.padEnd(24)} ${t.size}  ~${(COST_PER_CALL[t.size] ?? 0.134).toFixed(2)} $${t.note ? '  ← ' + t.note : ''}`);
    console.log(`Total : ${todo.length} appel(s), ~${cost.toFixed(2)} $ (budget/run : ${BUDGET_PER_RUN_USD.toFixed(2)} $)`);
    if (cost > BUDGET_PER_RUN_USD) console.log('⚠ au-dessus du budget par exécution : générer en plusieurs fois ou --confirm');
    return;
  }

  if (cmd === 'generate') {
    if (opt.part) {
      await generateOne(charId, m, opt.part, opt.force);
      return;
    }
    if (opt.all) {
      const { todo, cost } = planFor(charId, m);
      if (!opt.confirm) {
        console.log(`--all nécessite --confirm après lecture du dry-run (${todo.length} appels, ~${cost.toFixed(2)} $)`);
        return;
      }
      if (cost > BUDGET_PER_RUN_USD) throw new Error(`coût ${cost.toFixed(2)} $ > budget ${BUDGET_PER_RUN_USD} $ : générer par lots`);
      for (const t of todo) await generateOne(charId, loadManifest(charId), t.partId, false);
      return;
    }
    console.log('préciser --part <id> ou --all --confirm');
    return;
  }

  if (cmd === 'process') {
    if (!opt.generation) throw new Error('--generation <gid> requis');
    const raw = join(work(charId), 'generations', `${opt.generation}.png`);
    const keyed = join(work(charId), 'generations', `${opt.generation}.keyed.png`);
    const rep = await keyAndTrim(raw, keyed);
    console.log(`✓ détouré : ${keyed} (${rep.w}x${rep.h}, fond rgb(${rep.bgColor.join(',')}))`);
    return;
  }

  if (cmd === 'validate') {
    const report = { date: new Date().toISOString(), characterId: charId, parts: [] };
    const genDir = join(work(charId), 'generations');
    const keyedFiles = existsSync(genDir) ? readdirSync(genDir).filter(f => f.endsWith('.keyed.png')) : [];
    for (const f of keyedFiles) {
      const v = await validatePart(join(genDir, f));
      report.parts.push({ file: `generations/${f}`, ...v });
      console.log(`${v.status.padEnd(8)} ${f} (${v.w}x${v.h})`);
      for (const c of v.checks.filter(c2 => !c2.ok)) console.log(`         ✗ ${c.name}${c.detail ? ' — ' + c.detail : ''}`);
    }
    for (const p of m.parts.filter(p2 => p2.status === 'approved')) {
      const path = join(pub(charId), p.filename);
      if (!existsSync(path)) { report.parts.push({ part: p.id, status: 'FAIL', checks: [{ name: 'fichier approuvé présent', ok: false }] }); continue; }
      const v = await validatePart(path);
      report.parts.push({ part: p.id, file: p.filename, ...v });
      console.log(`${v.status.padEnd(8)} [approved] ${p.id}`);
    }
    mkdirSync(join(work(charId), 'qa'), { recursive: true });
    writeFileSync(join(work(charId), 'qa', 'validation-report.json'), JSON.stringify(report, null, 2));
    console.log(`→ rapport : art/characters/${charId}/qa/validation-report.json`);
    return;
  }

  if (cmd === 'approve') {
    if (!opt.part || !opt.generation) throw new Error('--part <id> et --generation <gid> requis');
    if (opt.generation === 'latest') {
      const gens = (m.generationHistory ?? []).filter(g => g.partId === opt.part && g.keyedFile && g.status !== 'failed');
      if (!gens.length) throw new Error(`aucune génération détourée pour ${opt.part}`);
      opt.generation = gens[gens.length - 1].generationId;
    }
    const isMaster = opt.part === 'master_front';
    const part = isMaster ? null : m.parts.find(p => p.id === opt.part);
    if (!isMaster && !part) throw new Error(`pièce inconnue : ${opt.part}`);
    const keyed = join(work(charId), 'generations', `${opt.generation}.keyed.png`);
    if (!existsSync(keyed)) throw new Error(`génération détourée introuvable : ${keyed}`);
    const dest = isMaster ? join(pub(charId), 'approved', 'master_front.png') : join(pub(charId), part.filename);
    if (existsSync(dest) && !opt.force) {
      throw new Error(`${dest} existe (pièce approuvée) — jamais d'écrasement silencieux : --force pour remplacer (l'ancienne devient superseded)`);
    }
    mkdirSync(join(dest, '..'), { recursive: true });
    copyFileSync(keyed, dest);
    for (const g of m.generationHistory ?? []) {
      if (g.partId === opt.part && g.status === 'approved') g.status = 'superseded';
      if (g.generationId === opt.generation) g.status = 'approved';
    }
    if (part) { part.status = 'approved'; part.sourceGenerationId = opt.generation; }
    saveManifest(charId, m);
    console.log(`✓ approuvé : ${opt.part} ← ${opt.generation} → ${dest}`);
    return;
  }

  if (cmd === 'sheet') {
    const out = join(work(charId), 'qa', 'contact-sheet.png');
    mkdirSync(join(work(charId), 'qa'), { recursive: true });
    const r = await buildContactSheet(m, work(charId), out);
    console.log(`✓ planche de contrôle : ${out} (${r.count} pièces)`);
    return;
  }

  console.log(`commande inconnue : ${cmd}`);
}

main().catch(err => {
  console.error(`Échec : ${err.message}`);
  process.exitCode = 1;
});

#!/usr/bin/env node
// CLI du pipeline d'extension de map par outpainting contrôlé.
// Commandes : extend · preview · validate · approve · split · tiles
// Voir docs/map-pipeline/README.md pour le détail de chaque étape.
import { mkdirSync, writeFileSync, readFileSync, existsSync, cpSync } from 'node:fs';
import { resolve, join } from 'node:path';
import sharp from 'sharp';

import { MASTERS_DIR, QA_DIR, HISTORY_DIR, CHUNKS_DIR, TILES_DIR, ROOT } from './lib/paths.mjs';
import { loadWorld, saveWorld, loadSpec, getChunk, OPPOSITE, nextChunkId } from './lib/world-store.mjs';
import { planExtension, buildExtensionCanvas, composeAssembled } from './processors/canvas.mjs';
import { buildPrompt } from './prompts/build-prompt.mjs';
import { buildBriefPrompt, buildReviewPrompt } from './prompts/build-chat-prompts.mjs';
import { generateExtension, estimateCost } from './providers/banana.mjs';
import { requestArtBrief, requestAssembledReview, estimateChatCost } from './providers/chatgpt.mjs';
import { checkProtectedPixels } from './validators/protected-pixels.mjs';
import { buildSeamPreview } from './validators/seam-preview.mjs';
import { toSharpRect, intersectRect } from './lib/rect.mjs';
import { planTileGrid, refreshTileGrid } from './processors/tile-grid.mjs';

const MAX_REVIEW_ATTEMPTS = 3;
const REVIEW_SCORE_THRESHOLD = 95;

const [, , command, ...rest] = process.argv;
const args = parseArgs(rest);

function parseArgs(argv) {
  const out = {};
  for (let i = 0; i < argv.length; i++) {
    if (argv[i].startsWith('--')) {
      const key = argv[i].slice(2);
      const next = argv[i + 1];
      if (next === undefined || next.startsWith('--')) { out[key] = true; }
      else { out[key] = next; i++; }
    }
  }
  return out;
}

function fail(msg) {
  console.error(`Erreur : ${msg}`);
  process.exitCode = 1;
}

async function main() {
  switch (command) {
    case 'extend': return cmdExtend();
    case 'preview': return cmdPreview();
    case 'validate': return cmdValidate();
    case 'approve': return cmdApprove();
    case 'split': return cmdSplit();
    case 'tiles': return cmdTiles();
    default:
      console.log('Usage : node tools/map-pipeline/cli.mjs <extend|preview|validate|approve|split|tiles> [--flags]');
      process.exitCode = command ? 1 : 0;
  }
}

// ---------------------------------------------------------------- extend --
async function cmdExtend() {
  const { source, direction, theme } = args;
  if (!source || !direction || !theme) return fail('--source, --direction et --theme sont requis');
  if (!['north', 'south', 'east', 'west'].includes(direction)) return fail('--direction doit être north|south|east|west');

  const world = loadWorld();
  const spec = loadSpec();
  const chunk = getChunk(world, source);
  if (chunk.neighbors[direction]) return fail(`Le chunk ${source} a déjà un voisin ${direction} (${chunk.neighbors[direction]}) — étendre ce voisin plutôt que ${source}`);

  const sourcePath = resolve(ROOT, chunk.source);
  if (!existsSync(sourcePath)) return fail(`Source introuvable : ${sourcePath}`);

  const newSizePx = Number(args['new-size'] ?? 700);
  const overlapPx = Number(args.overlap ?? spec.overlapWidthPx);
  const connectors = chunk.connectors?.[direction] ?? [];

  const plan = planExtension({
    sourceWidth: chunk.widthPx,
    sourceHeight: chunk.heightPx,
    direction,
    newSizePx,
    overlapPx,
  });

  const targetChunkId = nextChunkId(source, direction);
  const briefPrompt = buildBriefPrompt({ spec, connectors, theme, direction });
  const basePrompt = buildPrompt({ spec, connectors, theme, direction }); // sans artBrief, pour affichage dry-run
  const genId = `gen-${source}-${direction}-${Date.now()}`;
  const bananaCost = estimateCost({ imageSize: '2K' });
  const chatCost = estimateChatCost({ maxAttempts: MAX_REVIEW_ATTEMPTS });

  if (args['dry-run']) {
    console.log('=== DRY-RUN — aucun appel API, aucun fichier écrit ===\n');
    console.log(`Chunk source          : ${source} (${chunk.widthPx}x${chunk.heightPx}, ${chunk.source})`);
    console.log(`Chunk cible (nouveau)  : ${targetChunkId}`);
    console.log(`Direction              : ${direction}`);
    console.log(`Thème                  : ${theme}`);
    console.log(`Nouvelle zone          : ${newSizePx}px sur l'axe ${plan.axis}`);
    console.log(`Bande de chevauchement : ${overlapPx}px (${(100 * overlapPx / (plan.axis === 'y' ? chunk.heightPx : chunk.widthPx)).toFixed(1)}% de la dimension source sur cet axe)`);
    console.log(`Canevas envoyé à l'IA  : ${plan.contextCanvas.width}x${plan.contextCanvas.height} (PAS la map entière ${chunk.widthPx}x${chunk.heightPx})`);
    console.log(`  bande de contexte (protégée) : x=${plan.contextBandInCanvas.x} y=${plan.contextBandInCanvas.y} ${plan.contextBandInCanvas.width}x${plan.contextBandInCanvas.height}`);
    console.log(`  zone générable                : x=${plan.generableInCanvas.x} y=${plan.generableInCanvas.y} ${plan.generableInCanvas.width}x${plan.generableInCanvas.height}`);
    console.log(`Master final            : ${plan.masterSize.width}x${plan.masterSize.height}`);
    console.log(`Décalage de repère      : ${plan.originShift}`);
    console.log(`Connecteurs détectés (${direction}) : ${connectors.length ? '' : 'aucun — bordure fermée, prolongation du décor de clôture'}`);
    connectors.forEach(c => console.log(`  - ${c.type} @ ${Math.round(c.position * 100)}%, largeur ${c.widthPx}px, ${c.required ? 'obligatoire' : 'optionnel'}`));
    console.log(`\nCoût estimé (pire cas) : ~$${(bananaCost.perImageUsd * MAX_REVIEW_ATTEMPTS + chatCost.worstCaseUsd).toFixed(2)} (Banana : ~$${bananaCost.perImageUsd}/appel × jusqu'à ${MAX_REVIEW_ATTEMPTS} tentatives + ChatGPT : ~$${chatCost.worstCaseUsd.toFixed(2)} — ${chatCost.note} ; ${bananaCost.note} ; régénération non garantie, 1 appel Banana suffit si le score ChatGPT passe dès la 1ère tentative)`);
    console.log(`\n--- Prompt brief ChatGPT (prévu, avant génération) ---\n${briefPrompt}\n--------------------`);
    console.log(`\n--- Prompt Nano Banana (sans le brief ChatGPT, qui sera ajouté en annexe une fois généré) ---\n${basePrompt}\n--------------------`);
    console.log(`\nFichiers qui seraient créés (hors dry-run) :`);
    console.log(`  art/maps/history/${genId}/before.png`);
    console.log(`  art/maps/history/${genId}/chatgpt-brief.txt`);
    console.log(`  art/maps/history/${genId}/chatgpt-brief-request.json`);
    console.log(`  art/maps/history/${genId}/canvas.png`);
    console.log(`  art/maps/history/${genId}/mask.png`);
    console.log(`  art/maps/history/${genId}/prompt.txt`);
    console.log(`  art/maps/history/${genId}/params.json`);
    console.log(`  art/maps/history/${genId}/raw-generation.png`);
    console.log(`  art/maps/history/${genId}/extension-only.png`);
    console.log(`  art/maps/history/${genId}/assembled.png`);
    console.log(`  art/maps/history/${genId}/chatgpt-review-attempt-{1..${MAX_REVIEW_ATTEMPTS}}.json`);
    console.log(`  art/maps/history/${genId}/chatgpt-review-summary.json`);
    console.log(`  art/maps/qa/${targetChunkId}-protected-area-report.json`);
    console.log(`  art/maps/qa/${targetChunkId}-seam-preview.png`);
    console.log(`  art/maps/qa/${targetChunkId}-visual-review.md   (constats ChatGPT + approbation humaine finale à compléter)`);
    console.log(`\nNote : ce dry-run couvre l'extension organique (Banana + ChatGPT). La grille fixe dérivée a son propre dry-run séparé : npm run map:tiles -- --dry-run (aucune des deux commandes ne déclenche l'autre).`);
    console.log(`\nProchaine étape réelle : relancer sans --dry-run pour lancer les appels API (1 brief + 1 à ${MAX_REVIEW_ATTEMPTS} génération(s)/revue(s), pas de série au-delà).`);
    return;
  }

  // ---- exécution réelle ----
  const genDir = join(HISTORY_DIR, genId);
  mkdirSync(genDir, { recursive: true });
  mkdirSync(QA_DIR, { recursive: true });

  cpSync(sourcePath, join(genDir, 'before.png'));

  console.log('Appel ChatGPT (brief artistique)...');
  const { brief, raw: briefRaw } = await requestArtBrief({ promptText: briefPrompt });
  writeFileSync(join(genDir, 'chatgpt-brief.txt'), brief);
  writeFileSync(join(genDir, 'chatgpt-brief-request.json'), JSON.stringify({ promptText: briefPrompt, response: briefRaw }, null, 2));

  const prompt = buildPrompt({ spec, connectors, theme, direction, artBrief: brief });

  const { canvas, mask } = await buildExtensionCanvas(sourcePath, plan);
  writeFileSync(join(genDir, 'canvas.png'), canvas);
  writeFileSync(join(genDir, 'mask.png'), mask);
  writeFileSync(join(genDir, 'prompt.txt'), prompt);
  writeFileSync(join(genDir, 'params.json'), JSON.stringify({ source, direction, theme, newSizePx, overlapPx, targetChunkId, plan }, null, 2));

  const aspect = plan.contextCanvas.width === plan.contextCanvas.height ? '1:1'
    : plan.contextCanvas.width > plan.contextCanvas.height ? '3:2' : '2:3';

  // Une tentative complète : appel Banana -> recomposition -> validations. Réutilisée
  // par la boucle de régénération ChatGPT ci-dessous — aucune duplication de la
  // logique de protection pixel / seam preview déjà auditée.
  async function runGenerationAttempt(promptForThisAttempt) {
    console.log(`Appel Nano Banana (${plan.contextCanvas.width}x${plan.contextCanvas.height})...`);
    const { buffer: rawBuffer, rawResponseMeta } = await generateExtension({ canvasBuffer: canvas, prompt: promptForThisAttempt, aspectRatio: aspect });
    // la sortie brute de l'API n'a pas forcément les dimensions exactes du
    // canevas envoyé (§4 de l'audit) : redimensionnement qualité avant de
    // découper UNIQUEMENT la zone générable — jamais la bande de contexte.
    const resizedRaw = await sharp(rawBuffer).resize(plan.contextCanvas.width, plan.contextCanvas.height, { fit: 'fill' }).toBuffer();
    const extensionOnly = await sharp(resizedRaw).extract(toSharpRect(plan.generableInCanvas)).png().toBuffer();
    const assembled = await composeAssembled(sourcePath, plan, extensionOnly);
    const protectedReport = await checkProtectedPixels(sourcePath, assembled, plan);
    const seam = await buildSeamPreview(assembled, plan, resolve(QA_DIR, `${targetChunkId}-seam-preview.png`));
    return { rawBuffer, rawResponseMeta, extensionOnly, assembled, protectedReport, seam };
  }

  let attempt = 1;
  let result = await runGenerationAttempt(prompt);
  const reviews = [];

  while (true) {
    writeFileSync(resolve(QA_DIR, `${targetChunkId}-protected-area-report.json`), JSON.stringify({ genId, attempt, ...result.protectedReport }, null, 2));
    if (!result.protectedReport.identical) {
      // Échec BLOQUANT, jamais contourné par le score ChatGPT : ceci indique un
      // bug du pipeline de recomposition (pas un problème de contenu artistique),
      // voir docs/map-extension-audit.md §12 — pas de régénération automatique.
      console.error(`ÉCHEC : ${result.protectedReport.diffPixelCount} pixel(s) protégé(s) modifié(s) (tentative ${attempt}) — assemblage rejeté, ne PAS approuver ce chunk.`);
      process.exitCode = 1;
      return;
    }

    console.log(`Appel ChatGPT (revue, tentative ${attempt}/${MAX_REVIEW_ATTEMPTS})...`);
    const reviewPrompt = buildReviewPrompt({ theme, direction, spec, attempt });
    const review = await requestAssembledReview({ promptText: reviewPrompt, imageBuffer: result.assembled });
    reviews.push(review);
    writeFileSync(join(genDir, `chatgpt-review-attempt-${attempt}.json`), JSON.stringify(review, null, 2));

    if (review.score >= REVIEW_SCORE_THRESHOLD || attempt >= MAX_REVIEW_ATTEMPTS) break;

    console.log(`Score ChatGPT ${review.score}/100 (< ${REVIEW_SCORE_THRESHOLD}) — régénération (tentative ${attempt + 1}/${MAX_REVIEW_ATTEMPTS})...`);
    attempt++;
    const retryPrompt = `${prompt}\n\nPrevious attempt feedback to address: ${review.notes}`;
    result = await runGenerationAttempt(retryPrompt);
  }

  writeFileSync(join(genDir, 'raw-generation.png'), result.rawBuffer);
  writeFileSync(join(genDir, 'raw-response-meta.json'), JSON.stringify(result.rawResponseMeta, null, 2));
  writeFileSync(join(genDir, 'extension-only.png'), result.extensionOnly);
  writeFileSync(join(genDir, 'assembled.png'), result.assembled);

  const finalReview = reviews[reviews.length - 1];
  const passed = finalReview.score >= REVIEW_SCORE_THRESHOLD;
  writeFileSync(join(genDir, 'chatgpt-review-summary.json'), JSON.stringify({ attempts: reviews, finalScore: finalReview.score, passed, chosenAttempt: attempt }, null, 2));

  writeFileSync(resolve(QA_DIR, `${targetChunkId}-visual-review.md`), [
    `# Revue visuelle — ${targetChunkId} (${genId})`,
    '',
    `Couture visible ? ${finalReview.seamVisible ? 'oui' : 'non'} (ChatGPT)`,
    `Le chemin continue-t-il naturellement ? ${finalReview.pathContinuous ? 'oui' : 'non'} (ChatGPT)`,
    `La rivière continue-t-elle correctement ? ${finalReview.riverContinuous ? 'oui' : 'non'} (ChatGPT)`,
    `La perspective est-elle stable ? ${finalReview.perspectiveStable ? 'oui' : 'non'} (ChatGPT)`,
    `L'éclairage reste-t-il cohérent ? ${finalReview.lightingConsistent ? 'oui' : 'non'} (ChatGPT)`,
    `Le nouveau biome arrive-t-il progressivement ? ${finalReview.biomeGradual ? 'oui' : 'non'} (ChatGPT)`,
    `Y a-t-il un élément coupé ? ${finalReview.cutElement ? 'oui' : 'non'} (ChatGPT)`,
    `Faut-il régénérer ? ${passed ? 'non — seuil atteint' : `oui — seuil non atteint après ${MAX_REVIEW_ATTEMPTS} tentative(s)`}`,
    '',
    `Score ChatGPT (tentative finale ${attempt}/${MAX_REVIEW_ATTEMPTS}) : ${finalReview.score}/100`,
    `Constats ChatGPT : ${finalReview.notes}`,
    `Signal automatique (non contractuel) : écart de teinte à la couture = ${result.seam.meanColorDiff} — ${result.seam.meanColorDiffNote}`,
    '',
    `Approbation humaine (map:approve autorisé ?) : À REMPLIR`,
  ].join('\n'));

  console.log(`\nOK — assemblage produit : ${genDir}/assembled.png (tentative retenue ${attempt}/${MAX_REVIEW_ATTEMPTS}, score ChatGPT ${finalReview.score}/100${passed ? '' : ' — SOUS le seuil de 95, revue humaine requise avant toute approbation'})`);
  console.log(`Zone protégée : identique (0 pixel modifié, ${result.protectedReport.totalPixels} pixels vérifiés).`);
  console.log(`Couture : art/maps/qa/${targetChunkId}-seam-preview.png (écart de teinte ${result.seam.meanColorDiff})`);
  console.log(`Revue à compléter (approbation humaine, toujours manuelle) : art/maps/qa/${targetChunkId}-visual-review.md`);
  console.log(`\nSi la revue est favorable : npm run map:approve -- --chunk ${targetChunkId} --gen ${genId}`);
}

// --------------------------------------------------------------- preview --
async function cmdPreview() {
  const { chunk } = args;
  if (!chunk) return fail('--chunk requis');
  const seamPath = resolve(QA_DIR, `${chunk}-seam-preview.png`);
  if (!existsSync(seamPath)) return fail(`Aucune couture générée pour ${chunk} — lancer map:extend d'abord.`);
  console.log(`Aperçu de couture : ${seamPath}`);
}

// -------------------------------------------------------------- validate --
async function cmdValidate() {
  const { chunk } = args;
  if (!chunk) return fail('--chunk requis');
  const reportPath = resolve(QA_DIR, `${chunk}-protected-area-report.json`);
  if (!existsSync(reportPath)) return fail(`Aucun rapport pour ${chunk} — lancer map:extend d'abord.`);
  const report = JSON.parse(readFileSync(reportPath, 'utf8'));
  console.log(JSON.stringify(report, null, 2));
  console.log(report.identical ? 'VALIDE : zone protégée intacte.' : 'INVALIDE : ne pas approuver.');
  process.exitCode = report.identical ? 0 : 1;
}

// --------------------------------------------------------------- approve --
async function cmdApprove() {
  const { chunk, gen } = args;
  if (!chunk || !gen) return fail('--chunk et --gen sont requis');

  const paramsPath = resolve(HISTORY_DIR, gen, 'params.json');
  const assembledPath = resolve(HISTORY_DIR, gen, 'assembled.png');
  if (!existsSync(paramsPath) || !existsSync(assembledPath)) return fail(`Génération introuvable : ${gen}`);
  const params = JSON.parse(readFileSync(paramsPath, 'utf8'));

  const reportPath = resolve(QA_DIR, `${chunk}-protected-area-report.json`);
  const report = JSON.parse(readFileSync(reportPath, 'utf8'));
  if (!report.identical) return fail(`Zone protégée invalide pour ${gen} — approbation refusée.`);

  const world = loadWorld();
  const sourceChunk = getChunk(world, params.source);
  if (!sourceChunk.originPx || !sourceChunk.paintedRegionPx) {
    return fail(`${params.source} n'a pas de originPx/paintedRegionPx — migration world.json requise avant d'approuver de nouveaux chunks.`);
  }

  // Position absolue dérivée UNIQUEMENT des offsets déjà calculés par planExtension() —
  // aucune nouvelle géométrie (voir docs/map-pipeline/README.md).
  const originPx = {
    x: sourceChunk.originPx.x - params.plan.sourceOffsetInMaster.x,
    y: sourceChunk.originPx.y - params.plan.sourceOffsetInMaster.y,
  };
  const paintedRegionPx = {
    x: originPx.x + params.plan.newRegionOffsetInMaster.x,
    y: originPx.y + params.plan.newRegionOffsetInMaster.y,
    width: params.plan.newRegionSize.width,
    height: params.plan.newRegionSize.height,
  };

  // Garde-fou anti-chevauchement : deux chunks approuvés ne peuvent jamais prétendre
  // posséder la même zone absolue (rendrait le tuilage ambigu, voir partie B du plan).
  for (const [otherId, other] of Object.entries(world.chunks)) {
    if (!other.paintedRegionPx) continue;
    if (intersectRect(paintedRegionPx, other.paintedRegionPx)) {
      return fail(`paintedRegionPx de ${chunk} chevauche celui de ${otherId} — approbation refusée, world.json non modifié.`);
    }
  }

  const masterFilename = `${chunk}.png`;
  mkdirSync(MASTERS_DIR, { recursive: true });
  cpSync(assembledPath, resolve(MASTERS_DIR, masterFilename));

  world.chunks[chunk] = {
    id: chunk,
    theme: params.theme,
    source: `art/maps/masters/${masterFilename}`,
    widthPx: params.plan.masterSize.width,
    heightPx: params.plan.masterSize.height,
    status: 'approved',
    note: `créé par extension ${params.direction} de ${params.source} (${gen})`,
    originPx,
    paintedRegionPx,
    neighbors: { north: null, south: null, east: null, west: null, [OPPOSITE[params.direction]]: params.source },
    connectors: { north: [], south: [], east: [], west: [] },
  };
  sourceChunk.neighbors[params.direction] = chunk;
  saveWorld(world);

  console.log(`Approuvé : ${chunk} -> art/maps/masters/${masterFilename}`);
  console.log(`world.json mis à jour (${params.source}.neighbors.${params.direction} = ${chunk}).`);
  console.log(`Note : intégration Phaser (chargement, colliders, décalage de repère) volontairement NON faite ici — étape séparée après validation humaine complète.`);
}

// ----------------------------------------------------------------- split --
async function cmdSplit() {
  const { source, size } = args;
  if (!source) return fail('--source requis (chemin du master ou id de chunk)');
  const world = loadWorld();
  const chunk = world.chunks[source];
  const sourcePath = chunk ? resolve(ROOT, chunk.source) : resolve(ROOT, source);
  if (!existsSync(sourcePath)) return fail(`Introuvable : ${sourcePath}`);

  const tileSize = Number(size ?? 1024);
  const meta = await sharp(sourcePath).metadata();
  mkdirSync(CHUNKS_DIR, { recursive: true });

  const cols = Math.ceil(meta.width / tileSize);
  const rows = Math.ceil(meta.height / tileSize);
  let written = 0;
  for (let gy = 0; gy < rows; gy++) {
    for (let gx = 0; gx < cols; gx++) {
      const w = Math.min(tileSize, meta.width - gx * tileSize);
      const h = Math.min(tileSize, meta.height - gy * tileSize);
      const out = resolve(CHUNKS_DIR, `chunk_${gx}_${gy}.png`);
      await sharp(sourcePath).extract({ left: gx * tileSize, top: gy * tileSize, width: w, height: h }).png().toFile(out);
      written++;
    }
  }
  console.log(`${written} tuiles techniques écrites dans art/maps/chunks/ (${cols}x${rows}, taille ${tileSize}px, découpage géométrique pur, aucune génération).`);
}

// ----------------------------------------------------------------- tiles --
// Grille fixe dérivée (2048x2048 par défaut) pour le futur chargement Phaser
// dynamique — reconstruite à partir des masters organiques approuvés de
// world.json. Ne génère rien, ne modifie jamais world.json ni les masters :
// lecture seule sur du contenu déjà approuvé (voir docs/map-pipeline/README.md).
async function cmdTiles() {
  const world = loadWorld();
  const tileSize = Number(args['tile-size'] ?? 2048);

  if (args['dry-run']) {
    const plan = planTileGrid(world, { tileSize });
    console.log('=== DRY-RUN — aucun fichier écrit ===\n');
    if (!plan.bounds) {
      console.log('Aucun chunk approuvé dans world.json — rien à tuiler.');
      return;
    }
    console.log(`Taille de tuile           : ${tileSize}px`);
    console.log(`Bbox monde absolue         : x=${plan.bounds.x} y=${plan.bounds.y} ${plan.bounds.width}x${plan.bounds.height}`);
    console.log(`Grille                     : gx ${plan.gxRange[0]}..${plan.gxRange[1]}, gy ${plan.gyRange[0]}..${plan.gyRange[1]}`);
    console.log(`Tuiles produites           : ${plan.tiles.length}\n`);
    for (const tile of plan.tiles) {
      console.log(`  ${tile.id} : couverte ${tile.coveredRect.width}x${tile.coveredRect.height}${tile.isPartial ? ' (PARTIELLE — bord de monde connu, pas de padding)' : ''}, sources : ${tile.contributions.map(c => c.chunkId).join(', ')}`);
    }
    console.log(`\nFichiers qui seraient écrits par tuile : background.png, meta.json, connectors.json (toujours réécrits) + collisions.json, objects.json, navigation.json (scaffold vide, seulement si absents).`);
    return;
  }

  const { plan, written } = await refreshTileGrid(world, ROOT, { tileSize });
  console.log(`${written.length} tuile(s) écrite(s) sous ${TILES_DIR} (aucun appel IA, aucune modification de world.json).`);
  const partial = plan.tiles.filter(t => t.isPartial).map(t => t.id);
  if (partial.length) console.log(`Tuiles partielles (bord de monde connu, PNG recadré au contenu réel, jamais étiré) : ${partial.join(', ')}`);
}

main().catch(err => { console.error(err); process.exitCode = 1; });

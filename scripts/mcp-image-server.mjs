// Serveur MCP « eluminia-images » (transport stdio, JSON-RPC ligne par ligne).
// Expose l'outil generate_image : génération OpenAI gpt-image-1 avec la bible
// graphique du jeu (public/art/image.png) comme référence de style par défaut.
// Enregistré dans .mcp.json à la racine du projet.
import { createInterface } from 'node:readline';
import { generateImage, SIZES, ENGINES, DEFAULT_STYLE_REFS, OUTPUT_DIR } from './lib/image-gen.mjs';

const TOOL = {
  name: 'generate_image',
  description:
    `Génère une image dans le style d'Eluminia (« Les Gardiens du Savoir ») et l'écrit dans ${OUTPUT_DIR}/. ` +
    `Par défaut, la bible graphique (${DEFAULT_STYLE_REFS.join(', ')}) est jointe comme référence de style ; ` +
    'fournir references pour utiliser d\'autres images de public/art/, ou use_style_base=false pour une génération libre. ' +
    'Toujours demander un fond transparent pour les personnages et objets destinés au jeu. ' +
    'Deux moteurs : "openai" (gpt-image-1 — décors, alpha natif) et "banana" (Nano Banana Pro — ' +
    'COHÉRENCE de personnage entre poses via références multiples ; pas d\'alpha natif → prévoir le détourage).',
  inputSchema: {
    type: 'object',
    properties: {
      prompt: { type: 'string', description: 'Description précise de l\'image (en anglais de préférence). Ne pas décrire le style : il vient des références.' },
      filename: { type: 'string', description: 'Nom du fichier de sortie, ex. "renard-magique.png".' },
      size: { type: 'string', enum: SIZES, description: 'Dimensions (défaut 1024x1024).' },
      transparent: { type: 'boolean', description: 'Fond transparent (recommandé pour personnages/objets).' },
      references: { type: 'array', items: { type: 'string' }, description: 'Chemins d\'images de référence (relatifs au projet), ex. ["public/art/image.png"].' },
      use_style_base: { type: 'boolean', description: 'false pour générer sans aucune référence de style (défaut true).' },
      engine: { type: 'string', enum: ENGINES, description: 'Moteur : "openai" (défaut, décors) ou "banana" (personnages/cohérence).' },
    },
    required: ['prompt', 'filename'],
  },
};

const send = msg => process.stdout.write(JSON.stringify(msg) + '\n');
const reply = (id, result) => send({ jsonrpc: '2.0', id, result });
const replyError = (id, code, message) => send({ jsonrpc: '2.0', id, error: { code, message } });

const rl = createInterface({ input: process.stdin, terminal: false });
rl.on('line', async line => {
  line = line.trim();
  if (!line) return;
  let msg;
  try {
    msg = JSON.parse(line);
  } catch {
    return;
  }
  const { id, method, params } = msg;

  if (method === 'initialize') {
    reply(id, {
      protocolVersion: params?.protocolVersion ?? '2025-06-18',
      capabilities: { tools: {} },
      serverInfo: { name: 'eluminia-images', version: '1.0.0' },
    });
    return;
  }
  if (method === 'notifications/initialized' || id === undefined) return; // notification
  if (method === 'ping') {
    reply(id, {});
    return;
  }
  if (method === 'tools/list') {
    reply(id, { tools: [TOOL] });
    return;
  }
  if (method === 'tools/call') {
    if (params?.name !== 'generate_image') {
      replyError(id, -32602, `Outil inconnu : ${params?.name}`);
      return;
    }
    const a = params.arguments ?? {};
    try {
      const r = await generateImage({
        prompt: a.prompt,
        filename: a.filename,
        size: a.size ?? '1024x1024',
        transparent: a.transparent ?? false,
        references: a.use_style_base === false ? [] : a.references ?? null,
        engine: a.engine ?? 'openai',
      });
      reply(id, {
        content: [
          {
            type: 'text',
            text:
              `Image générée : ${r.publicPath} (${Math.round(r.bytes / 1024)} Ko). ` +
              (r.references.length ? `Références de style : ${r.references.map(p => p.split(/[\\/]/).pop()).join(', ')}. ` : 'Sans référence de style. ') +
              'Penser à : vérifier visuellement le fichier (Read), puis mettre à jour art/generated/manifest.json.',
          },
        ],
        isError: false,
      });
    } catch (err) {
      reply(id, { content: [{ type: 'text', text: `Échec de génération : ${err.message}` }], isError: true });
    }
    return;
  }
  replyError(id, -32601, `Méthode non gérée : ${method}`);
});

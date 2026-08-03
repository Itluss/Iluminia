// Génération d'images pour Eluminia — deux moteurs :
//   - openai  : gpt-image-1 (décors, fonds transparents natifs)
//   - banana  : Nano Banana Pro / gemini-3-pro-image (personnages, COHÉRENCE
//               entre poses ; pas d'alpha natif → détourage en aval)
// Toute génération prend PAR DÉFAUT la planche UI de Camille comme référence
// de style (public/ui/interface.png) — le jeu est désormais le spike 3D
// procédural, cette planche est la seule référence graphique HUD actuelle.
import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { resolve, basename } from 'node:path';

export const DEFAULT_STYLE_REFS = ['public/ui/interface.png'];
export const OUTPUT_DIR = 'public/ui/generated';
export const SIZES = ['1024x1024', '1536x1024', '1024x1536', 'auto'];
export const ENGINES = ['openai', 'banana'];
// Nano Banana Pro exige la facturation activée sur la clé Gemini ; sans
// facturation, surcharger avec GEMINI_IMAGE_MODEL=gemini-3.1-flash-image.
const BANANA_MODEL = process.env.GEMINI_IMAGE_MODEL || 'gemini-3-pro-image';

const STYLE_SUFFIX =
  " — Match exactly the art style of the reference image(s): soft painted " +
  "children's game UI icon, warm cream/brown palette, glossy rounded shading, " +
  "thin dark outline. No text, no watermark, no border, no frame, no background.";

export async function generateImage({
  prompt,
  filename,
  size = '1024x1024',
  transparent = false,
  references = null, // null => références de style par défaut ; [] => aucune
  quality = 'high',
  engine = 'openai',
}) {
  if (!ENGINES.includes(engine)) throw new Error(`engine invalide (${engine}). Valeurs : ${ENGINES.join(', ')}`);
  const key = engine === 'banana' ? process.env.GEMINI_API_KEY : process.env.OPENAI_API_KEY;
  if (!key) {
    throw new Error(
      engine === 'banana'
        ? 'GEMINI_API_KEY absente. Créer une clé sur https://aistudio.google.com puis : setx GEMINI_API_KEY "..." (et rouvrir la session).'
        : "OPENAI_API_KEY absente. Créer une clé sur https://platform.openai.com/api-keys " +
          'puis : setx OPENAI_API_KEY "sk-..."  (et rouvrir le terminal / la session).',
    );
  }
  if (!prompt || !filename) throw new Error('prompt et filename sont obligatoires.');
  if (!SIZES.includes(size)) throw new Error(`size invalide (${size}). Valeurs : ${SIZES.join(', ')}`);
  if (!/^[\w][\w.-]*\.png$/i.test(filename)) throw new Error('filename : nom simple en .png attendu.');

  const refs = (references ?? DEFAULT_STYLE_REFS).map(r => resolve(r)).filter(r => {
    if (!existsSync(r)) {
      console.warn(`Référence introuvable, ignorée : ${r}`);
      return false;
    }
    return true;
  });

  const TRANSPARENT_SUFFIX =
    ' — The subject must be ISOLATED on a fully transparent background (alpha channel): ' +
    'no ground, no floor, no shadow on the ground, no backdrop, no scenery of any kind.';
  const fullPrompt = prompt + (refs.length ? STYLE_SUFFIX : '') + (transparent ? TRANSPARENT_SUFFIX : '');
  let b64;

  if (engine === 'banana') {
    b64 = await callBanana(key, fullPrompt, refs, size);
  } else if (refs.length > 0) {
    // /images/edits : le style des références guide la génération
    const form = new FormData();
    form.append('model', 'gpt-image-1');
    form.append('prompt', fullPrompt);
    form.append('size', size);
    form.append('quality', quality);
    if (transparent) form.append('background', 'transparent');
    for (const ref of refs) {
      form.append('image[]', new Blob([readFileSync(ref)], { type: 'image/png' }), basename(ref));
    }
    b64 = await callApi('https://api.openai.com/v1/images/edits', key, form);
  } else {
    b64 = await callApi(
      'https://api.openai.com/v1/images/generations',
      key,
      JSON.stringify({
        model: 'gpt-image-1',
        prompt: fullPrompt,
        size,
        quality,
        background: transparent ? 'transparent' : 'auto',
      }),
      { 'Content-Type': 'application/json' },
    );
  }

  const outDir = resolve(OUTPUT_DIR);
  mkdirSync(outDir, { recursive: true });
  const outPath = resolve(outDir, filename);
  const buf = Buffer.from(b64, 'base64');
  writeFileSync(outPath, buf);
  return { path: outPath, publicPath: `${OUTPUT_DIR}/${filename}`, bytes: buf.length, references: refs, engine };
}

// Nano Banana Pro (API Gemini) : références en entrée multimodale — idéal
// pour la cohérence d'un personnage entre plusieurs poses.
async function callBanana(key, fullPrompt, refs, size) {
  const aspect = { '1024x1024': '1:1', '1536x1024': '3:2', '1024x1536': '2:3' }[size];
  // En 1K, Gemini sort ~1264×848 : trop petit pour un décor affiché en natif
  // (agrandir est interdit) → 2K pour les formats rectangulaires, quitte à
  // réduire à l'intégration.
  const imageSize = size === '1024x1024' ? '1K' : '2K';
  const parts = refs.map(ref => ({
    inline_data: { mime_type: 'image/png', data: readFileSync(ref).toString('base64') },
  }));
  parts.push({ text: fullPrompt });

  const res = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${BANANA_MODEL}:generateContent`,
    {
      method: 'POST',
      headers: { 'x-goog-api-key': key, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ role: 'user', parts }],
        generationConfig: {
          responseModalities: ['IMAGE'],
          ...(aspect ? { imageConfig: { aspectRatio: aspect, imageSize } } : {}),
        },
      }),
    },
  );
  const json = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw new Error(`API Gemini ${res.status} : ${json?.error?.message ?? 'réponse illisible'}`);
  }
  const partsOut = json?.candidates?.[0]?.content?.parts ?? [];
  const img = partsOut.find(p => p.inlineData?.data || p.inline_data?.data);
  const data = img?.inlineData?.data ?? img?.inline_data?.data;
  if (!data) throw new Error('Réponse Gemini sans image (inlineData manquant).');
  return data;
}

async function callApi(url, key, body, extraHeaders = {}) {
  const res = await fetch(url, {
    method: 'POST',
    headers: { Authorization: `Bearer ${key}`, ...extraHeaders },
    body,
  });
  const json = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw new Error(`API ${res.status} : ${json?.error?.message ?? 'réponse illisible'}`);
  }
  const data = json?.data?.[0]?.b64_json;
  if (!data) throw new Error('Réponse API sans image (b64_json manquant).');
  return data;
}

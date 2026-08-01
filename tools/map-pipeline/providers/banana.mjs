// Appel Nano Banana (Gemini) pour le pipeline d'extension : prend un canevas
// (PNG buffer) + un prompt, renvoie l'image brute générée (PNG buffer).
// Ne réutilise PAS scripts/lib/image-gen.mjs (qui travaille par chemins de
// fichiers et références de style multiples) : ici l'unique référence est le
// canevas d'extension lui-même, déjà construit par processors/canvas.mjs.
const BANANA_MODEL = process.env.GEMINI_IMAGE_MODEL || 'gemini-3-pro-image';

export async function generateExtension({ canvasBuffer, prompt, aspectRatio, imageSize = '2K' }) {
  const key = process.env.GEMINI_API_KEY;
  if (!key) {
    throw new Error(
      'GEMINI_API_KEY absente. Créer une clé sur https://aistudio.google.com puis : ' +
      'setx GEMINI_API_KEY "..." (et rouvrir la session).',
    );
  }

  const parts = [
    { inline_data: { mime_type: 'image/png', data: canvasBuffer.toString('base64') } },
    { text: prompt },
  ];

  const res = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${BANANA_MODEL}:generateContent`,
    {
      method: 'POST',
      headers: { 'x-goog-api-key': key, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ role: 'user', parts }],
        generationConfig: {
          responseModalities: ['IMAGE'],
          ...(aspectRatio ? { imageConfig: { aspectRatio, imageSize } } : {}),
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
  if (!data) throw new Error("Réponse Gemini sans image (inlineData manquant) — voir json.candidates pour le motif de refus éventuel.");
  return { buffer: Buffer.from(data, 'base64'), rawResponseMeta: { model: BANANA_MODEL, candidateCount: json?.candidates?.length ?? 0 } };
}

/** Estimation grossière du coût — à affiner une fois le vrai tarif Nano Banana Pro connu pour ce compte. */
export function estimateCost({ imageSize = '2K' } = {}) {
  const perImageUsd = imageSize === '2K' ? 0.06 : 0.03; // placeholder documenté, PAS une donnée facturée vérifiée
  return { perImageUsd, note: 'estimation non contractuelle — à vérifier sur la console Google AI avant un usage en série' };
}

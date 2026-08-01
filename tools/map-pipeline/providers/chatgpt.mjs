// Appels ChatGPT (OpenAI) pour le pipeline d'extension : un brief artistique
// texte avant génération, une revue notée (vision) après assemblage.
// Réutilise OPENAI_API_KEY (déjà utilisée par scripts/lib/image-gen.mjs pour
// gpt-image-1) — même pattern d'erreur, pas de nouvelle dépendance (fetch brut).
const CHAT_MODEL = process.env.OPENAI_CHAT_MODEL || 'gpt-4o';

function requireKey() {
  const key = process.env.OPENAI_API_KEY;
  if (!key) {
    throw new Error(
      'OPENAI_API_KEY absente. Créer une clé sur https://platform.openai.com/api-keys ' +
      'puis : setx OPENAI_API_KEY "sk-..."  (et rouvrir le terminal / la session).',
    );
  }
  return key;
}

async function chatCompletion(key, body) {
  const res = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: { Authorization: `Bearer ${key}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ model: CHAT_MODEL, ...body }),
  });
  const json = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw new Error(`API OpenAI ${res.status} : ${json?.error?.message ?? 'réponse illisible'}`);
  }
  return json;
}

export async function requestArtBrief({ promptText }) {
  const key = requireKey();
  const json = await chatCompletion(key, {
    messages: [{ role: 'user', content: promptText }],
  });
  const brief = json?.choices?.[0]?.message?.content;
  if (!brief) throw new Error('Réponse ChatGPT sans contenu (brief).');
  return { brief, raw: { model: CHAT_MODEL, usage: json.usage } };
}

const REVIEW_SCHEMA = {
  name: 'map_extension_review',
  strict: true,
  schema: {
    type: 'object',
    additionalProperties: false,
    required: [
      'score', 'seamVisible', 'pathContinuous', 'riverContinuous',
      'perspectiveStable', 'lightingConsistent', 'biomeGradual', 'cutElement', 'notes',
    ],
    properties: {
      score: { type: 'integer', minimum: 0, maximum: 100 },
      seamVisible: { type: 'boolean' },
      pathContinuous: { type: 'boolean' },
      riverContinuous: { type: 'boolean' },
      perspectiveStable: { type: 'boolean' },
      lightingConsistent: { type: 'boolean' },
      biomeGradual: { type: 'boolean' },
      cutElement: { type: 'boolean' },
      notes: { type: 'string' },
    },
  },
};

export async function requestAssembledReview({ promptText, imageBuffer }) {
  const key = requireKey();
  const dataUrl = `data:image/png;base64,${imageBuffer.toString('base64')}`;
  const json = await chatCompletion(key, {
    messages: [{
      role: 'user',
      content: [
        { type: 'text', text: promptText },
        { type: 'image_url', image_url: { url: dataUrl } },
      ],
    }],
    response_format: { type: 'json_schema', json_schema: REVIEW_SCHEMA },
  });
  const content = json?.choices?.[0]?.message?.content;
  if (!content) throw new Error('Réponse ChatGPT sans contenu (revue).');
  const review = JSON.parse(content);
  return { ...review, verdict: review.score >= 95 ? 'pass' : 'revise', raw: { model: CHAT_MODEL, usage: json.usage } };
}

/** Estimation grossière — placeholder documenté, à vérifier sur la console OpenAI avant un usage en série. */
export function estimateChatCost({ maxAttempts = 3 } = {}) {
  const briefUsd = 0.01;
  const reviewUsd = 0.02; // revue vision, plus coûteuse qu'un brief texte seul
  const worstCaseUsd = briefUsd + reviewUsd * maxAttempts;
  return {
    briefUsd, reviewUsd, worstCaseUsd,
    note: `estimation non contractuelle — pire cas 1 brief + ${maxAttempts} revues, à vérifier sur la console OpenAI avant un usage en série`,
  };
}

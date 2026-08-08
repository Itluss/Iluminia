// Comparaison GPT vision : planche de concept "Observatoire d'Astra" vs
// capture en jeu (rendu 3D procédural, angle isométrique différent de
// l'illustration — la fidélité visée est celle de la palette/ambiance/
// objets clés, pas un calque pixel-exact comme pour une UI 2D).
import { readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';

const key = process.env.OPENAI_API_KEY;
if (!key) throw new Error('OPENAI_API_KEY absente.');

const boardPath = resolve('public/ui/generated/board-quest-maths-astra-observatory.png');
const capturePath = resolve('art/reviews/latest-numbers.png');
const outPath = resolve('art/reviews/gpt-comparison-astra.md');

const toDataUrl = p => `data:image/png;base64,${readFileSync(p).toString('base64')}`;

const prompt = `Tu compares une planche de concept art (image 1) et une capture d'écran d'un jeu vidéo 3D pour enfants (image 2, rendu procédural low-poly toon shading, vue isométrique).

Image 1 : planche de concept pour une zone appelée "l'Observatoire d'Astra" — cercle de pierre avec anneau bleu pâle incrusté, obélisque central à rune étoilée dorée lumineuse, lanternes à orbe turquoise, cristaux violets/lilas flottants portant des nombres.

Image 2 : capture en jeu de cette même zone, avec en plus le HUD du jeu (ignore le HUD) et le héros au centre.

Le rendu 3D ne peut PAS reproduire le style peint/illustré de la planche (géométries simples, toon shading) — la fidélité visée porte sur : la palette de couleurs (pierre/anneau/obélisque/lanternes/cristaux), la présence et disposition des éléments clés (cercle de pierre + anneau, obélisque central avec symbole lumineux, lanternes autour, cristaux flottants), l'ambiance générale (magique, chaleureuse, pas sombre).

Réponds en français, en deux parties :
1. "FIDÉLITÉ" : note de 1 à 10 sur la fidélité de palette/ambiance/composition à la planche (pas de fidélité géométrique pixel-exacte, précise-le dans ta justification).
2. "CORRECTIONS" : liste à puces des écarts de couleur ou d'éléments manquants/mal représentés, classés par impact décroissant. Maximum 6 puces.`;

const res = await fetch('https://api.openai.com/v1/chat/completions', {
  method: 'POST',
  headers: { Authorization: `Bearer ${key}`, 'Content-Type': 'application/json' },
  body: JSON.stringify({
    model: 'gpt-4o',
    messages: [
      {
        role: 'user',
        content: [
          { type: 'text', text: prompt },
          { type: 'image_url', image_url: { url: toDataUrl(boardPath) } },
          { type: 'image_url', image_url: { url: toDataUrl(capturePath) } },
        ],
      },
    ],
    max_tokens: 700,
  }),
});
const json = await res.json();
if (!res.ok) throw new Error(`API OpenAI ${res.status} : ${json?.error?.message ?? 'réponse illisible'}`);
const text = json.choices?.[0]?.message?.content ?? '(réponse vide)';
writeFileSync(outPath, text);
console.log(text);
console.log(`\n--- écrit dans ${outPath} ---`);

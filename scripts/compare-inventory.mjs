// Comparaison GPT vision : capture du menu inventaire en jeu vs planche de
// référence de Camille (section 3 "MENU INVENTAIRE" fait foi). Sortie texte
// avec des indications concrètes de correction, pas de jugement vague.
import { readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';

const key = process.env.OPENAI_API_KEY;
if (!key) throw new Error('OPENAI_API_KEY absente.');

const boardPath = resolve('art/board/image.png');
const capturePath = resolve('art/reviews/latest.png');
const outPath = resolve('art/reviews/gpt-comparison.md');

const toDataUrl = p => `data:image/png;base64,${readFileSync(p).toString('base64')}`;

const prompt = `Tu compares deux images du menu inventaire d'un jeu vidéo pour enfants (style toon fantasy).

Image 1 : la PLANCHE DE RÉFÉRENCE complète. Seule la section encadrée "3. MENU INVENTAIRE" (grand panneau, à droite) fait foi comme cible — ignore les autres sections numérotées (1,2,4,5,6).

Image 2 : une capture d'écran du menu inventaire tel qu'il est actuellement rendu dans le jeu (résolution 1600x900, HUD de jeu visible autour, ignore le HUD).

L'objectif est une REPRODUCTION VISUELLE LA PLUS FIDÈLE POSSIBLE de la section 3 de la planche — pas une réinterprétation. Compare précisément : silhouette générale de la fenêtre, proportions du header (couleur olive, icône sac à dos, position du titre, bouton fermer), position/style des onglets, taille relative des cases de la grille (6 colonnes), largeur relative du panneau de détail à droite, position des boutons, présentation du footer, couleurs, arrondis, ombres, espacements.

Réponds en français, en deux parties :
1. "FIDÉLITÉ" : note globale de 1 à 10 sur la fidélité à la planche, avec une phrase de justification.
2. "CORRECTIONS" : liste à puces des écarts concrets et actionnables, classés par impact visuel décroissant. Sois précis et quantifié quand possible (ex. "le panneau de détail fait environ X% de la largeur totale contre Y% sur la planche"). Maximum 8 puces.`;

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
    max_tokens: 900,
  }),
});
const json = await res.json();
if (!res.ok) throw new Error(`API OpenAI ${res.status} : ${json?.error?.message ?? 'réponse illisible'}`);
const text = json.choices?.[0]?.message?.content ?? '(réponse vide)';
writeFileSync(outPath, text);
console.log(text);
console.log(`\n--- écrit dans ${outPath} ---`);

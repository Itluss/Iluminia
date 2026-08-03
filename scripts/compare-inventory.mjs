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

const prompt = `Tu compares deux images du menu inventaire d'un jeu vidéo éducatif pour enfants (style toon, palette bonbon).

Image 1 : la PLANCHE DE RÉFÉRENCE complète fournie par la directrice artistique. Seule la section encadrée "3. MENU INVENTAIRE" (grand panneau, à droite) fait foi comme cible — ignore les autres sections numérotées (1,2,4,5,6) de la planche.

Image 2 : une capture d'écran du menu inventaire tel qu'il est actuellement rendu dans le jeu (résolution 1600x900, HUD de jeu visible autour).

Compare UNIQUEMENT la structure/style du panneau d'inventaire (image 2) à la section 3 de la planche (image 1) : proportions du panneau, header (couleur, icône, titre, bouton fermer), bandeau d'onglets (position, style, icônes), grille d'objets (taille des cases, bordures des cases vides, espacement, badges), panneau de détail à droite, pied de page (capacité, devises). Note : le contenu de la grille est volontairement différent (2 vraies ressources du jeu au lieu des items RPG de la planche) — ne signale PAS ça comme un défaut, c'est voulu.

Réponds en français, en deux parties :
1. "FIDÉLITÉ" : note globale de 1 à 10 sur la fidélité structurelle/stylistique à la planche, avec une phrase de justification.
2. "CORRECTIONS" : liste à puces des écarts concrets et actionnables (couleurs, proportions, espacements, éléments manquants ou en trop), classés par impact visuel décroissant. Sois précis (ex. "le bandeau d'onglets est X% trop bas" plutôt que "les onglets sont mal placés"). Maximum 8 puces.`;

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

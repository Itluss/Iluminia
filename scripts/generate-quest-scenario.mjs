// Génère un scénario de quête structuré (univers + narration + plusieurs
// manches à difficulté croissante) via GPT, sur le même principe que la
// génération de planches (scripts/generate-image.mjs) : GPT produit la
// matière, Claude Code l'implémente fidèlement dans spike3d-village.html.
//
// Usage :
//   node scripts/generate-quest-scenario.mjs --subject "Maths" \
//     --subtheme "Nombres entiers jusqu'à 100 000" --mechanic CUEILLETTE \
//     --out art/scenarios/maths-nombres-entiers.json
//
// Corrige directement le problème constaté sur la 1ère quête (Astra) :
// une seule manche = ~20-30s de jeu réel une fois sur place. Le schéma
// impose plusieurs manches à difficulté croissante.
import { writeFileSync, mkdirSync } from 'node:fs';
import { resolve, dirname } from 'node:path';

const key = process.env.OPENAI_API_KEY;
if (!key) throw new Error('OPENAI_API_KEY absente.');

const args = process.argv.slice(2);
const opt = {};
for (let i = 0; i < args.length; i++) {
  const a = args[i];
  if (a.startsWith('--')) { opt[a.slice(2)] = args[++i]; }
}
if (!opt.subject || !opt.subtheme || !opt.mechanic) {
  console.error('Usage : --subject "..." --subtheme "..." --mechanic CUEILLETTE|CARTE|TRI|APPARIEMENT|DIALOGUE|CIRCUIT|SAUT|CONSTRUCTION [--out chemin.json]');
  process.exit(1);
}
const outPath = resolve(opt.out || `art/scenarios/${opt.subject.toLowerCase()}-${opt.subtheme.toLowerCase().replace(/[^a-z0-9]+/g, '-')}.json`);

const MECHANIC_NOTES = {
  CUEILLETTE: 'le joueur ramasse dans le monde 3D les objets/cristaux correspondant au bon critère parmi un mélange correct/incorrect ; le contenu de chaque manche = une liste "pieces" de {label, correct}',
  CARTE: 'le joueur doit désigner/atteindre la bonne réponse parmi plusieurs repères directionnels ou spatiaux ; chaque manche = une consigne + la bonne réponse parmi des options nommées',
  TRI: 'le joueur porte des objets un par un jusqu’au bon panier/catégorie ; chaque manche = une liste d’objets avec leur catégorie correcte',
  APPARIEMENT: 'le joueur associe des paires (objet ↔ fonction, mot ↔ sens...) parmi des cartes mélangées ; chaque manche = une liste de paires',
  DIALOGUE: 'un PNJ pose des questions à choix multiples, une seule bonne réponse par question ; chaque manche = une liste de questions/choix/index correct',
  CIRCUIT: 'le joueur remet des éléments dans le bon ordre/sens pour activer un mécanisme ; chaque manche = une séquence à reconstituer',
  SAUT: 'le joueur saute/choisit la bonne réponse parmi plusieurs, contre le temps',
  CONSTRUCTION: 'le joueur assemble des éléments selon une quantité/mesure donnée',
};

const prompt = `Tu es game designer pour Eluminia, un jeu éducatif 3D (Three.js, style toon/cel-shading bas-poly, palette bonbon) pour des enfants de CM1 (9-10 ans, France). Le monde est une prairie magique villageoise ; chaque quête est une petite zone optionnelle, découverte en explorant (pas listée d'avance), avec sa propre identité visuelle et narrative.

Contraintes non négociables (retours déjà obtenus de la personne qui dirige le projet) :
- AMBIANCE chaleureuse et rassurante, jamais sombre/inquiétante — jeu pour enfants.
- VRAI ENJEU obligatoire : chrono et/ou tolérance d'erreurs limitée sur chaque manche — "si ça prend 30 secondes, ça n'a aucun intérêt" (retour direct).
- PLUSIEURS MANCHES à difficulté croissante dans la même quête (temps plus court, cible plus haute, ou moins d'erreurs tolérées à chaque manche) — une quête à manche unique dure ~20-30s une fois sur place, ce qui est jugé trop court pour l'investissement visuel/narratif qui l'entoure.
- Contenu pédagogique EXACT et vérifiable pour le sous-thème demandé (pas d'approximation).
- Mécanique de jeu : ${opt.mechanic} — ${MECHANIC_NOTES[opt.mechanic] ?? 'mécanique personnalisée, décris son fonctionnement dans "mechanicNotes"'}.

Matière : ${opt.subject}
Sous-thème CM1 : ${opt.subtheme}

Génère un scénario de quête complet. Réponds UNIQUEMENT en JSON valide, avec exactement cette forme :
{
  "questId": "slug-court",
  "universe": {
    "name": "nom de la zone/lieu",
    "characterName": "nom d'un PNJ ou d'une figure évoquée par le lore, ou null si aucun",
    "lorePitch": "2-3 phrases de contexte/scénario, en français, ton chaleureux",
    "moodKeywords": ["3-5 mots-clés d'ambiance/couleur en anglais, pour guider une génération d'image"],
    "boardPrompt": "prompt en anglais, prêt à l'emploi pour un générateur d'images (gpt-image-1), décrivant une planche de concept art pour cette zone : composition, éléments clés, ambiance — PAS de description de style (elle vient d'une image de référence séparée)"
  },
  "narrative": {
    "loreOnEnter": "texte affiché la 1ère fois que le joueur entre dans la zone, français",
    "doneText": "message de réussite finale, français"
  },
  "difficultyRounds": [
    {
      "roundNumber": 1,
      "instruction": "consigne affichée au joueur pour cette manche, français, peut inclure des <b>...</b> pour les valeurs clés",
      "timeLimitSeconds": nombre,
      "maxErrors": nombre,
      "content": [ /* liste d'objets dont la forme dépend de la mécanique ${opt.mechanic}, voir la note ci-dessus — reste cohérent d'une manche à l'autre */ ]
    }
    /* 3 manches minimum, difficulté strictement croissante (timeLimitSeconds qui diminue et/ou maxErrors qui diminue et/ou plus d'items/plus proche du seuil de discrimination) */
  ],
  "finishReward": { "xp": nombre, "coins": nombre }
}`;

const res = await fetch('https://api.openai.com/v1/chat/completions', {
  method: 'POST',
  headers: { Authorization: `Bearer ${key}`, 'Content-Type': 'application/json' },
  body: JSON.stringify({
    model: 'gpt-4o',
    messages: [{ role: 'user', content: prompt }],
    response_format: { type: 'json_object' },
    max_tokens: 2200,
  }),
});
const json = await res.json();
if (!res.ok) throw new Error(`API OpenAI ${res.status} : ${json?.error?.message ?? 'réponse illisible'}`);
const scenario = JSON.parse(json.choices[0].message.content);

mkdirSync(dirname(outPath), { recursive: true });
writeFileSync(outPath, JSON.stringify(scenario, null, 2));
console.log(`Scénario écrit : ${outPath}`);
console.log(JSON.stringify(scenario, null, 2));

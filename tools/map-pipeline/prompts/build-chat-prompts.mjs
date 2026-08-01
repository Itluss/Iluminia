// Construit les prompts textuels envoyés à ChatGPT — brief avant génération,
// grille de revue après assemblage. Aucun réseau ici (texte pur, testable en
// --dry-run), même philosophie que build-prompt.mjs. Réutilise
// formatConnectors()/specLines() plutôt que de dupliquer leur logique.
import { formatConnectors, specLines } from './build-prompt.mjs';

export function buildBriefPrompt({ spec, connectors, theme, direction }) {
  return `You are the art director for the Eluminia game world map (a 2D painterly RPG for children). A new region is about to be painted by outpainting an existing map.

Direction of extension: ${direction}
New region theme: ${theme}

Required border continuities:
${formatConnectors(connectors)}

Measured world constants (must be respected):
${specLines(spec)}

In 4-8 short bullet points, write a concise art-direction brief for this new region: what should be painted, which natural transition elements to use, what must be avoided, and any continuity risk specific to this direction/theme. Add judgment, do not just restate the constants above. Plain text bullets only, no markdown headers, no preamble.`;
}

export function buildReviewPrompt({ theme, direction, spec, attempt }) {
  return `You are reviewing an assembled Eluminia map extension (existing map + newly generated region, already composited into one image). This is attempt ${attempt} of up to 3.

Region theme: ${theme}
Direction of extension: ${direction}

Measured world constants that must have been respected:
${specLines(spec)}

Score this image from 0 to 100 on how well the new region continues the existing map. Score below 95 if there is ANY visible seam, broken road/river continuity, perspective shift, lighting mismatch, abrupt biome cut, or any cut-off element at the border. Be strict — this is a children's game, visual inconsistency is very noticeable to a young player. Respond using only the requested structured fields.`;
}

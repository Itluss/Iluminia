// Construit le prompt Nano Banana à partir du gabarit imposé, complété avec
// map-generation-spec.json et les connecteurs de world.json.
const BASE_TEMPLATE = `Extend the supplied Eluminia game map only into the transparent area.

The existing map is immutable reference material and must not be recreated, repainted, resized, shifted or altered.

Continue the environment seamlessly from the visible border.

Preserve exactly:
- camera projection;
- apparent camera height;
- perspective;
- object scale;
- road width;
- river width;
- lighting direction;
- color palette;
- saturation;
- shadow softness;
- vegetation density;
- architectural proportions;
- illustration style;
- level of detail.

Required border continuities:
{{connectors}}

New region theme:
{{theme}}

Direction of extension:
{{direction}}

The extension must feel like it was painted as part of the same original image.

Do not add:
- UI;
- labels;
- text;
- HUD;
- borders;
- frames;
- duplicated buildings from the old area;
- abrupt biome cut;
- perspective changes.

Use natural transition elements where useful:
- forest;
- bridge;
- river bend;
- rocky passage;
- small gate;
- cliff;
- tunnel;
- gradual vegetation change.

Generate only the missing extension area.`;

export function formatConnectors(connectors) {
  if (!connectors || connectors.length === 0) {
    return '- (aucun connecteur déclaré sur ce bord dans world.json : à traiter comme une bordure fermée, prolonger le décor de clôture — forêt/falaise/rivière — plutôt que d\'inventer une sortie)';
  }
  return connectors
    .map(c => `- ${c.type}, position ${Math.round(c.position * 100)}% le long du bord, largeur ${c.widthPx}px, ${c.required ? 'obligatoire' : 'optionnel'}${c.transitionTheme ? `, thème : ${c.transitionTheme}` : ''}`)
    .join('\n');
}

export function specLines(spec) {
  return [
    `projection: ${spec.projection}`,
    `camera direction: ${spec.cameraDirection}`,
    `light: ${spec.lightDirection} (${spec.colorTemperature}, saturation ${spec.saturation}, ${spec.shadowSoftness})`,
    `road width: ~${spec.roadWidthPx}px`,
    `river width: ~${spec.riverWidthPx}px`,
    `tree style: ${spec.treeStyle}`,
    `river style: ${spec.riverStyle}`,
    `fence style: ${spec.fenceStyle}`,
    `level of detail: ${spec.levelOfDetail}`,
  ].join('\n');
}

export function buildPrompt({ spec, connectors, theme, direction, artBrief }) {
  const filled = BASE_TEMPLATE
    .replace('{{connectors}}', formatConnectors(connectors))
    .replace('{{theme}}', theme)
    .replace('{{direction}}', direction);
  // les valeurs mesurées de la spec sont ajoutées en annexe explicite plutôt
  // qu'interpolées dans le gabarit imposé, pour garder le texte du gabarit
  // intact et auditable indépendamment des données mesurées.
  let out = `${filled}\n\nMeasured world constants (do not deviate):\n${specLines(spec)}`;
  // artBrief (facultatif) : annexe supplémentaire, même logique — le gabarit
  // imposé n'est jamais modifié, comportement inchangé si artBrief est omis.
  if (artBrief) out += `\n\nArt direction brief for this region:\n${artBrief}`;
  return out;
}

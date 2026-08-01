// Prompts de génération des pièces (Phase 5). Le prompt de base est enrichi
// par pièce. Le fond est MAGENTA (détourage fiable, cf. png-keying).
export const BASE = (partLabel, detail) =>
  'Create a clean isolated 2D game-character body part from the supplied canonical character reference sheet. ' +
  'Preserve exactly: character identity, proportions, costume colors (petrol blue and gold), lighting direction (soft warm top-left), ' +
  'painterly-but-clean Eluminia style, warm rounded shapes, consistent line weight, material appearance. ' +
  'The asset is designed for skeletal 2D animation. Requirements: ' +
  'centered in the canvas, complete hidden geometry (rebuild covered areas entirely), clean edges, no cropped pixels, ' +
  'neutral pose, no perspective distortion, no unrelated body parts, no text, no labels, no frame, no extra accessories, ' +
  'consistent scale with the canonical character, generous overlap around joints for rotation, readable at small game size. ' +
  `Target part: ${partLabel}. ${detail} ` +
  'Plain flat uniform pure magenta (#ff00ff) background, no shadow, no glow, nothing else in the image.';

export const PART_PROMPTS = {
  master_front: {
    label: 'vue avant canonique (personnage entier)',
    size: '1024x1536',
    prompt:
      'Redraw the main hero character from the reference sheet as ONE clean canonical FRONT view, full body, game-ready: ' +
      'same identity (brown hair in a few large readable locks, soft smiling face, petrol-blue and gold outfit with compass emblem on the cape, ' +
      'leather belt simplified, big readable boots, slightly bigger hands and forearms), slight natural asymmetry in the idle stance ' +
      '(weight on one leg, head very slightly tilted), simple large volumes, few big folds instead of many small ones, ' +
      'strong readable silhouette designed to stay clear at 116 px tall in game. Arms slightly away from the torso (A-pose relaxed) ' +
      'so limbs can be separated for rigging. Painterly-but-clean Eluminia style, warm rounded shapes. ' +
      'Plain flat uniform pure magenta (#ff00ff) background, no shadow, no text, nothing else.',
  },
  head_base: { label: 'head with face (no hair fringe)', size: '1024x1024', detail: 'The complete head and face WITHOUT the front hair fringe: skull covered by short flat base hair, ears, full face with skin, soft nose, NO eyes, NO mouth (bare face areas where they attach), neck stub with overlap.' },
  hair_front: { label: 'front hair fringe', size: '1024x1024', detail: 'Only the front hair: a few large readable brown locks forming the fringe and top volume, designed to overlay the head, slight overlap margin all around.' },
  hair_back: { label: 'back hair volume', size: '1024x1024', detail: 'Only the back hair volume that sits BEHIND the head silhouette.' },
  eyes_open: { label: 'both eyes open', size: '1024x1024', detail: 'Both eyes open with eyebrows, warm brown iris, friendly directed gaze, as a single overlay strip positioned as on the face.' },
  eyes_closed: { label: 'both eyes closed (blink)', size: '1024x1024', detail: 'ONLY a small horizontal strip with the two CLOSED eyes: two gentle downward-curved eyelid lines with lashes and the two eyebrows above, on a small patch of skin. STRICTLY NOTHING ELSE: no head, no hair, no face outline, no shoulders, no character — just the two closed eyelids and eyebrows, like a sticker.' },
  mouth_smile: { label: 'smiling mouth', size: '1024x1024', detail: 'A small warm closed smile, single overlay element.' },
  mouth_open: { label: 'open mouth (talking)', size: '1024x1024', detail: 'A small open rounded mouth for talking, single overlay element.' },
  mouth_neutral: { label: 'neutral mouth', size: '1024x1024', detail: 'ONLY a tiny relaxed neutral cartoon mouth: one simple soft dark-brown line, slightly curved, in the same simple cartoon style as the smiling mouth of the reference character. STRICTLY no realistic lips, no lipstick, no teeth, no face, no skin patch bigger than the mouth itself — just the small line mouth like a sticker.' },
  torso: { label: 'torso with tunic', size: '1024x1024', detail: 'The complete torso: petrol-blue tunic with gold trim and simplified belt, COMPLETE behind where the arms overlap, shoulder stubs with overlap margins, neck opening.' },
  pelvis: { label: 'pelvis / hips', size: '1024x1024', detail: 'The pelvis and hip area connecting torso to thighs, complete geometry with overlap top and bottom.' },
  cape_main: { label: 'cape (behind body)', size: '1024x1024', detail: 'The full cape seen from the front (it hangs BEHIND the body): petrol blue with gold compass emblem, simple large readable folds, complete shape (nothing hidden).' },
  left_upper_arm: { label: 'left upper arm', size: '1024x1024', detail: 'The LEFT upper arm segment (shoulder to elbow) with sleeve, rounded overlap at both ends for rotation.' },
  right_upper_arm: { label: 'right upper arm', size: '1024x1024', detail: 'The RIGHT upper arm segment (shoulder to elbow) with sleeve, rounded overlap at both ends for rotation.' },
  left_forearm_hand: { label: 'left forearm with hand', size: '1024x1024', detail: 'The LEFT forearm from elbow to a slightly oversized relaxed open hand with glove, rounded elbow overlap.' },
  right_forearm_hand: { label: 'right forearm with hand', size: '1024x1024', detail: 'The RIGHT forearm from elbow to a slightly oversized relaxed open hand with glove, rounded elbow overlap.' },
  left_thigh: { label: 'left thigh', size: '1024x1024', detail: 'The LEFT thigh segment (hip to knee) with trouser, rounded overlap at both ends, complete behind the tunic.' },
  right_thigh: { label: 'right thigh', size: '1024x1024', detail: 'The RIGHT thigh segment (hip to knee) with trouser, rounded overlap at both ends, complete behind the tunic.' },
  left_lower_leg_boot: { label: 'left lower leg with boot', size: '1024x1024', detail: 'The LEFT lower leg from knee down, ending in a slightly oversized readable leather boot, rounded knee overlap.' },
  right_lower_leg_boot: { label: 'right lower leg with boot', size: '1024x1024', detail: 'The RIGHT lower leg from knee down, ending in a slightly oversized readable leather boot, rounded knee overlap.' },
};

export function buildPrompt(partId) {
  const p = PART_PROMPTS[partId];
  if (!p) throw new Error(`pièce inconnue : ${partId}`);
  return { prompt: p.prompt ?? BASE(p.label, p.detail), size: p.size };
}

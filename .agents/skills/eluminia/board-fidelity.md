# Reproduction fidèle d'une planche de référence

Standard à appliquer CHAQUE FOIS que Camille fournit une planche/image de
référence en demandant une reproduction fidèle d'un élément d'UI (pas une
simple inspiration). Vient en complément du pipeline de `SKILL.md` — la
capture, la revue, l'historique et le rapport final s'appliquent
normalement ; ce document précise comment mener les Phases C/D/G quand une
planche fait foi.

## Principe

La planche est la SOURCE DE VÉRITÉ. Priorité absolue : fidélité visuelle,
pas de réinterprétation, simplification ou modernisation. Critère
d'acceptation : à vue d'œil, Camille doit reconnaître immédiatement
l'interface de la planche dans le jeu.

## 0. Analyser avant de coder

Identifier la stack et les patterns UI déjà en place (HUD/modales/boutons
existants) et les réutiliser au maximum — ne jamais créer un système UI
parallèle. Ne rien casser de l'existant (voir aussi `visual-quality.md`).

## 1. Construire en passes, pas tout d'un coup

1. Structure/dimensions/proportions — pour tout élément graphique pas
   encore disponible, utiliser un placeholder neutre (rond de couleur uni),
   JAMAIS un mauvais asset existant recyclé juste pour combler.
2. Couleurs/bordures/arrondis/ombres échantillonnés visuellement sur LA
   PLANCHE elle-même (pas les tokens de palette déjà en place dans le jeu
   si la planche a une palette différente).
3. Assets/icônes finaux — voir §3, point d'arrêt obligatoire.
4. Interactions.
5. Comparaison et correction — voir §6, minimum 2 passes.

## 2. Données, jamais de code en dur

Tout catalogue d'objets (items, états, rareté, équipé...) = une structure
de données générique + un rendu piloté par ces données (classes CSS
génériques du type `.rarity-rare`, jamais une couleur codée en dur par
objet individuel).

## 3. Génération d'icônes — point d'arrêt + recette qui marche

Générer une série d'icônes (plus de 2-3) est une action coûteuse : après
avoir construit toute la fenêtre en placeholders, **s'arrêter et demander
l'accord explicite de Camille avant de lancer le lot final**, même si sa
demande presse d'aller vite (règle budget de `CLAUDE.md`, absolue).

Recette qui a fonctionné (outil `generate_image`, moteur `gpt-image-1`) :

- `engine: "openai"`, `use_style_base: false` (PAS de référence de style —
  la bible graphique `interface.png` fait hériter un halo/vignette
  brunâtre aux générations, constaté à plusieurs reprises), `transparent:
  true`.
- Prompt = décrire l'objet seul + toujours ce gabarit anti-halo : « cel-
  shaded/toon style, one soft highlight, one hard-edged AO shadow directly
  under it, thin dark outline. Output ONLY the object as fully opaque
  pixels; every pixel outside its silhouette must be 100% transparent
  alpha with a hard edge, max 2px anti-aliasing. No background, no glow,
  no halo, no vignette, no ground plane, no card, no frame. »

Ne JAMAIS retenter un color-key/découpe maison depuis la planche (rejeté
explicitement par Camille — « tes icônes sont horribles »). Génération IA
avec la recette ci-dessus, ou fourniture directe des fichiers par Camille.

## 4. Vérifier la transparence PAR CALCUL, jamais à l'œil

L'outil de lecture d'image peut afficher un PNG réellement transparent
avec un fond coloré factice (noir, dégradé brun) qui ressemble à un halo —
ce n'est PAS fiable pour juger la transparence réelle. Toujours vérifier
par un script qui charge l'image dans un vrai `<canvas>` Chromium (via
Playwright, image servie par le dev server) et échantillonne le canal
alpha aux coins et sur une coupe de l'image. Alpha = 0 aux coins et pas de
plage opaque étendue au-delà de la silhouette = OK à intégrer.

## 5. Capture déterministe

Neutraliser toute animation CSS d'ouverture avant la capture
(`page.addStyleTag` pour forcer `animation: none !important` sur
l'élément concerné) — sinon la capture fige l'élément en plein pop-in
(ex. ~55 % de sa taille finale), ce qui fausse tout jugement visuel
ultérieur. Toujours vérifier qu'une capture reflète l'état final stable,
pas un état transitoire.

## 6. Comparaison visuelle automatisée — minimum 2 passes

Script GPT vision (`gpt-4o`, chat completions, images en base64,
cf. `scripts/compare-inventory.mjs` comme gabarit) comparant capture vs
planche. Le prompt doit préciser quelle section de la planche fait foi si
elle en contient plusieurs, et demander une note de fidélité + une liste
d'écarts concrets, quantifiés, classés par impact visuel décroissant.

Traiter la note comme indicative (variance normale d'une passe à l'autre,
pas forcément une régression) mais vérifier chaque écart suggéré contre la
planche soi-même avant de l'appliquer — le modèle peut se tromper (ex.
inverser le sens d'un écart). Corriger, recapturer, comparer à nouveau. Ne
jamais s'arrêter juste parce que tous les composants sont présents : la
ressemblance visuelle est le seul critère de validation qui compte.

## 7. Après coup

Historique (Phase I du pipeline standard) + mise à jour de
`art/generated/manifest.json` pour toute nouvelle icône générée.

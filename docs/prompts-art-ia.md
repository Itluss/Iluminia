# Prompts de génération d'art IA — Direction « Guild Wars × Axie »

**Objectif (2026-07-28)** : décors peints atmosphériques (esprit concept-art Guild Wars 2) habités par des personnages ronds, mignons, aux contours nets (esprit Axie Infinity). Les prompts sont en anglais — les générateurs y répondent mieux.

## Méthode pour la cohérence (à lire avant de générer)

1. Génère d'abord **l'image d'ancrage** (prompt 1). Régénère jusqu'au coup de cœur.
2. Réutilise-la ensuite comme **référence de style** pour toutes les autres :
   - Midjourney : ajoute `--sref <URL de l'image d'ancrage>` à chaque prompt.
   - ChatGPT : joins l'image d'ancrage et écris « in the exact same art style as this reference ».
3. Génère large (paysages en 16:9, éléments isolés en carré), garde plusieurs variantes.
4. Dépose tes sélections dans `C:\Users\camille\Eluminia\art-ia\` (peu importe les noms de fichiers).

## 1. Image d'ancrage — Fondvallon (le style du jeu)

> 2D adventure game scene, a charming riverside village in a lush green valley, a broken wooden bridge over a sparkling river, warm golden afternoon light. Painterly watercolor backgrounds with soft atmospheric depth in the style of fantasy concept art, inhabited by cute rounded characters with clean bold outlines and big expressive eyes. A giant glowing tree with golden fruits overlooks the village. Rich saturated colors, storybook fantasy feeling, no text, no UI. --ar 16:9

## 2. Panorama en couches (pour la parallaxe)

Trois images séparées, même style (référence d'ancrage à chaque fois) :

> Distant background layer for a 2D game: soft rolling green mountains under a summer sky with puffy clouds, painterly watercolor style, hazy atmospheric perspective, no foreground elements, no text. --ar 21:9

> Middle layer for a 2D game: a riverside fantasy village with round cozy houses, red and blue roofs, a stone bakery with a smoking chimney, painterly storybook style, isolated on plain light background, no sky, no text. --ar 21:9

> Foreground layer for a 2D game: wildflower meadow edge with tall grass and glowing golden-fruit tree branches framing the view, painterly storybook style, isolated on plain light background, no text. --ar 21:9

## 3. Le pont effondré (l'objet central du POC)

> Game asset: a broken wooden bridge over a river, two remaining stumps with a missing middle section, one thick horizontal wooden beam with carved measurement notches, painterly storybook fantasy style with clean outlines, isolated on plain white background, no text. --ar 16:9

## 4. Les personnages (un prompt par PNJ, fond neutre pour la découpe)

> Cute chibi game character: a cheerful round baker woman with rosy cheeks, flour-dusted apron and a tray of pies, big expressive eyes, clean bold outlines, painterly shading, front view, full body, isolated on plain white background, no text.

> Cute chibi game character: a burly friendly carpenter with a big beard, leather tool belt and a wooden mallet, big expressive eyes, clean bold outlines, painterly shading, front view, full body, isolated on plain white background, no text.

> Cute chibi game character: a calm young ferryman with a green bandana holding a long oar, big expressive eyes, clean bold outlines, painterly shading, front view, full body, isolated on plain white background, no text.

> Cute chibi game character: a brave child explorer with a small red cape and a glowing lantern, big expressive eyes, clean bold outlines, painterly shading, front view, full body, isolated on plain white background, no text.

## 5. L'interface (boutons et cadres)

> Game UI kit: rounded wooden buttons, a parchment dialog panel, a golden lantern progress gauge, fantasy storybook style with clean outlines, warm colors, arranged on plain white background, no text on the buttons.

## 6. BATCH PRIORITAIRE — le défi du pont en 100 % peint

Règle apprise le 2026-07-28 : aucun élément dessiné par code ne doit se poser sur une image peinte (effet « autocollant sur un tableau »). Tout ce qui est à l'écran doit sortir du générateur ; les scènes jouables se génèrent AVEC leur zone de jeu prévue.

**6a. La scène du chantier (le décor jouable)** :

> Side-view 2D game background: a wide calm river gap between two grassy banks, one single thick horizontal wooden beam spanning straight across the entire gap at mid-height, waiting for planks to be nailed on it. The riverside village and the giant tree with golden fruits stand in the soft blurred background. Uncluttered, clear open space above and below the beam for gameplay. Painterly storybook style, warm afternoon light, no characters, no text, no UI. --ar 16:9

**6b. Une planche de bois (l'objet que l'enfant manipule)** :

> Game asset: a single vertical wooden plank, warm honey-colored wood with painterly texture, slightly worn edges, a blank clear area in its center for a number, isolated on plain white background, storybook style, no text. --ar 2:3

**6c. Bram le charpentier** (section 4, prompt du charpentier).

**6d. Le héros** (prompt du petit explorateur, section 4 — version validée : l'animal à capuche de l'image d'ancrage).

En option : **6e. le kit UI** (section 5) pour les bulles et boutons peints.

Les chiffres et fractions sur les planches et graduations resteront ajoutés par code (les générateurs ratent le texte), mais dans une typographie et des couleurs assorties au bois peint — c'est invisible si la matière de fond est peinte.

## Ce que j'en ferai ensuite

- Découpe et détourage des éléments (fond blanc → transparence).
- Assemblage en scène avec parallaxe, eau animée, particules, lumière — le mouvement reste procédural, c'est là que mes maquettes gardent leur valeur.
- Personnages animés par marionnettage simple (balancement, rebond, retournement gauche/droite) — pas besoin de sprites d'animation dessinés à ce stade.

## Pièges connus

- **Les mains et les outils** des personnages sortent parfois déformés → régénérer, c'est normal.
- **Du texte fantôme** apparaît parfois malgré « no text » → à régénérer ou je le gommerai.
- **La cohérence dérive** au fil des générations → toujours repartir de l'image d'ancrage en référence de style.

# Prompts d'images en attente de génération

Aucun générateur d'images n'est connecté au projet. Les prompts ci-dessous sont
prêts à être utilisés dans l'outil de génération de Camille. Consignes
générales pour TOUTES les générations :

- style de référence : `public/art/image.png` (bible « Les Gardiens du Savoir ») ;
- FOND TRANSPARENT (ou uni clair si impossible) — jamais de fond décoratif ;
- AUCUN texte, titre ou cadre incrusté dans l'image ;
- un seul élément par image (pas de planches multi-éléments si possible) ;
- livrer dans `public/art/generated/` puis mettre à jour
  `art/generated/manifest.json`.

---

## Backlog permanent (améliorations connues)

### hero-walk-frames (prioritaire)
> Cute chibi boy hero with blue cape from the reference image, walk cycle
> sprite sheet, 4 frames side view (contact, down, passing, up), consistent
> proportions and lighting, transparent background, no text.
> 4 frames de 224×316 alignées horizontalement, même cadrage exact.

### village-fractions-hd
> Regenerate the exact same village scene as the reference (fountain, two
> houses, bridge over river, fences, banners) at 1350×824 or higher, same
> composition and palette, no border frame, no text.
> Objectif : remplacer l'upscale ×1,7 actuel par un affichage ≤ ×1.

(Compléter ce fichier à chaque itération qui identifie un asset manquant.)

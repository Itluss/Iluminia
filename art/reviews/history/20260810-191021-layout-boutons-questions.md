# Fiche d'itération — layout question/boutons sans chevauchement

Retour Camille (2026-08-10) : « les boutons doivent toujours être
visibles SOUS les questions, rassemblés en bas à droite, les questions
en haut à droite, AUCUN chevauchement — et si le bloc des questions
disparaît, les boutons ne doivent pas bouger. »

## Changements (public/spike3d-arena.html, CSS uniquement)

1. **Les boutons ne bougent plus jamais** : suppression du décalage
   `body.q-open #ability-zone { translateX(…) }` (c'est lui qui glissait
   l'arc vers le centre à l'ouverture du panneau sur téléphone) et de la
   transition associée.
2. **Cluster compact bas droite** : les 3 boutons suivent le bord bas
   (💥 coin, ⚡ à gauche +12 px, 🛡️ encore à gauche +30 px) — hauteur
   totale ≈ 110 px au lieu de ≈ 190 px (le 🛡️ montait trop vers le
   panneau).
3. **Le panneau question ne peut plus recouvrir les boutons** :
   `max-height: calc(100dvh − haut − 148px)` (118 px sur écrans
   ≤ 480 px de haut où les boutons sont plus petits) + `overflow-y:
   auto` — si l'écran est vraiment trop court, le panneau défile à
   l'intérieur au lieu de déborder.
4. Rangées de réponse compactées sous 480 px de haut pour que la
   question + les 4 réponses tiennent entières au-dessus des boutons.

## Vérifié (probes Playwright, 0 erreur console)

- 844×390 (iPhone paysage) : 4 réponses entières sans défilement,
  0 chevauchement, 32 px d'écart panneau→boutons, boutons STRICTEMENT
  immobiles à l'ouverture/fermeture du panneau.
- 740×360 : 0 chevauchement, boutons immobiles, panneau défile en
  interne (dégradation voulue).
- 1280×720 : 0 chevauchement (339 px d'écart), boutons immobiles.

## Signalé

- L'indicateur 🐉 en bord d'écran peut passer près des boutons en bas à
  droite (cosmétique, préexistant).

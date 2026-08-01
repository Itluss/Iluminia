# Critères d'acceptation d'une itération — Eluminia

Une itération est ACCEPTÉE uniquement si TOUTES les conditions suivantes sont
vérifiées (constats, pas d'impressions) :

1. `npm run build` réussit (TypeScript strict inclus), zéro erreur.
2. `npm run capture` produit `art/reviews/latest.png` sans erreur.
3. `art/reviews/browser-errors.json` ne contient aucune erreur critique.
4. La capture a été ANALYSÉE (outil Read) et la revue écrite dans
   `art/reviews/latest-review.md`.
5. Aucun défaut bloquant (liste dans `visual-quality.md`) ne subsiste sur la
   DERNIÈRE capture.
6. La demande utilisateur initiale est visible à l'écran (conformité point 30).
7. Aucune régression : déplacement, collisions, dialogue, question, XP,
   inventaire fonctionnent comme avant.
8. Aucun placeholder visible, aucun asset déformé, aucun texte de planche
   incrusté à l'écran.
9. Le manifest `art/generated/manifest.json` reflète la réalité des assets
   (existing/generated/missing).
10. L'historique est archivé dans `art/reviews/history/` avec timestamp.

Si un critère échoue après 3 cycles de correction : livrer quand même le
rapport final, en listant honnêtement les défauts restants et les assets
bloquants — ne jamais maquiller un échec en réussite.

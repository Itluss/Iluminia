# Critères d'acceptation d'une itération — Eluminia (spike 3D)

Une itération est ACCEPTÉE uniquement si TOUTES les conditions suivantes sont
vérifiées (constats, pas d'impressions) :

1. La page cible (`spike3d-village.html` et/ou `spike3d-planet2.html`) se
   charge sans erreur console (`art/reviews/browser-errors.json` vide ou
   sans erreur critique).
2. `npm run capture` (avec `GAME_URL` pointé sur le bon fichier) produit
   `art/reviews/latest.png`.
3. La capture a été ANALYSÉE (sous-agent `eluminia-visual-reviewer`, ou
   lecture directe si le budget d'un sous-agent est déjà consommé) et la
   revue écrite dans `art/reviews/latest-review.md`.
4. Aucun défaut bloquant (liste dans `visual-quality.md`) ne subsiste sur la
   DERNIÈRE capture, sauf s'il est explicitement hors périmètre et signalé
   pour décision de Camille.
5. La demande utilisateur initiale est visible/vérifiable à l'écran ou dans
   le comportement du jeu.
6. Aucune régression : déplacement, collisions, dialogue PNJ, mini-jeu du
   pont, portail, HUD fonctionnent comme avant.
7. Aucun élément temporaire visible (capsule de debug, forme non stylée).
8. Caméra orthographique isométrique inchangée, sauf demande explicite.
9. L'historique est archivé dans `art/reviews/history/` avec timestamp.
10. Le FPS n'est PAS jugé sur la base de la capture headless (cf. piège gravé
    dans `SKILL.md`/`visual-quality.md`).

Si un critère échoue après 1 cycle de correction : livrer quand même le
rapport final, en listant honnêtement les défauts restants — ne jamais
maquiller un échec en réussite.

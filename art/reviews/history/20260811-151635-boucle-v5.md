# Fiche d'itération — BOUCLE V5 : la question AVANT l'action

Spec complète Camille 2026-08-11 (« FLUIDE, SIMPLE, SANS QUESTION
PENDANT L'ACTION ») — voir docs/mecaniques-arene.md pour la boucle
détaillée.

## Machine d'état (public/spike3d-arena.html)

`manchePhase` : 'IDLE' → 'QUESTION' → 'PLAYING' → (fin) 'IDLE'.
Par entité (userData) : `selectedLetter` (bots ; le joueur garde
`selectedZoneLetter`), `eliminatedLetters []` (réponses testées,
INDIVIDUELLES), `frozenUntil` (gel).

- `startQuestionPhase()` : question + zones + panneau CENTRÉ (classe
  `qb-center`) + barre de décompte, gel général, bots choisissent
  (`botPickAnswer`, précision `botAnswerAccuracy`).
- `endQuestionPhase()` : panneau masqué (pilule « ? » si sans réponse),
  dragon spawné, chrono de manche affiché (pilule 🐉 haut centre).
- `resolveWrongZone()` réécrite : élimination INDIVIDUELLE (plus de
  zone morte globale), ❌ + drop du dragon + gel 2 s + re-question
  centrée avec réponses barrées (`qa-dead`) pour le joueur / re-choix
  automatique post-gel pour les bots.
- `resolveMancheTimeout()` : chrono à 0 → porteur gagne (+100) ; dragon
  au sol → personne ne marque (signalé, choix le plus simple).
- Gates : déplacement joueur, updateBot et activateAbility bloqués en
  phase QUESTION ; compétences bloquées pendant un gel.

## Réglages (LUMIN_CONFIG)

- `questionCountdown` : 6 s (phase question)
- `mancheDuration` : 45 s (chrono de manche)
- `wrongFreezeSeconds` : 2 s (gel après erreur)

## Vérifié (probes Playwright, 0 erreur console)

Scénario 1 complet : phase question centrée sans dragon → choix B →
lancement (panneau disparu, dragon, chrono 45 s) → mauvaise zone
(❌, lettre éliminée, gel actif, dragon libre, retry centré, réponse
barrée incliquable) → nouveau choix (panneau se ferme) → fin du gel →
re-capture → bonne zone → manche terminée → NOUVELLE phase question.
Scénario 2 : bot porteur + chrono forcé à 0 → manche terminée.
Transition naturelle de la phase question mesurée à 6,0 s pile.
Captures téléphone : phase question / action pure / retry.

## Signalé (§3/§19 de la spec)

- Sans réponse au décompte : la partie démarre, pilule « ? » toujours
  accessible, et la capture sans réponse rouvre le petit panneau.
- Dragon au sol au chrono 0 : manche terminée sans vainqueur.
- Le 3-2-1 inter-manches est remplacé par la phase question elle-même.

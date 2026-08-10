# Revue — voir fiche ci-dessous (auto-vérifiée par probes + captures, 0 erreur)

Décisions de Camille (2026-08-10) :
1. Supprimer le décompte de vie automatique (« on ne comprend pas
   pourquoi on perd de la vie »).
2. Les deux compétences doivent attaquer, éventuellement à distance, et
   la portée doit se voir à l'appui.

## Changements (public/spike3d-arena.html)

1. `passiveEnergyDrainPerSecond` 1,5 → 0 : l'énergie ne baisse plus que
   sur attaque subie ou mauvaise réponse ; cristaux = soin principal.
2. Chat 🐱 reworké : aimant → ÉCLAT MAGIQUE à distance (projectile rose
   ligne droite, portée 9, 22 dégâts au premier ennemi, extinction pile à
   portée max). Le vol du dragon reste réservé à la poussée du Renard.
3. Portée visible : arc blanc de LIMITE à la portée exacte au cast de la
   poussée ; l'éclat matérialise sa portée par sa trajectoire.
4. Écran d'accueil et docs/mecaniques-arene.md mis à jour.

## Vérifié

- Vie 100 → 100 après 4 s d'inactivité (drain bien supprimé).
- Éclat tiré, vol rectiligne, extinction, dégâts via damageLife (même
  chemin que la poussée, flash rouge + « -22 » inclus), 0 erreur console.
- Captures : éclat lumineux en vol + anneau de cast nets.

## Signalé / hors périmètre

- Les bots n'utilisent pas encore l'éclat (ils poussent seulement) — à
  décider.
- Dragon porté enfoui dans Max (toujours n°1 en attente).

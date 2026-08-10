# Fiche d'itération — kit V1 : 3 pouvoirs à cooldown (spec Camille 2026-08-10)

Spec « GAMEPLAY V1 COMPÉTENCES » : remplacer le système de pets/charges
par exactement 3 pouvoirs — 💥 Onde de choc, ⚡ Dash, 🛡️ Bouclier — en
pur cooldown (pas de mana), valeurs centralisées, bots utilisateurs
simples, structure prête pour des variantes futures (pas de boutique).

## Changements (public/spike3d-arena.html)

1. `ABILITY_CONFIG` : toutes les valeurs (cooldowns 4/5/7 s, onde
   force 2,6 / portée 3,2 / cône 78° / 10 dégâts, dash 6 u à 26 u/s,
   bouclier 2 s) au même endroit.
2. `equippedAbilities` { offense: 'shockwave', mobility: 'dash',
   defense: 'shield' } + `ABILITY_DEFINITIONS` + `activateAbility`
   (gate cooldown, secousse « denied » sur le bouton du joueur).
3. Onde = délégation au handler de poussée existant (vol du dragon,
   arc de portée, flash/dégâts inclus) avec dégâts paramétrés à 10.
4. Dash **basé distance** (`dashRemaining`, décompté frame par frame) :
   exactement 6 u quel que soit le framerate ; coupé net par un K.O.
5. Bouclier : réutilise `shieldedUntil`/`isShielded` (déjà respecté par
   dégâts/poussées/vols) + bulle violette AVEC anneau équatorial net
   (la sphère additive seule disparaissait sur le sol lavande).
6. 3 boutons (arc bas droite) avec anneau de charge + décompte
   secondes ; bots : onde ≤ 3,5 u du porteur, dash > 9 u, bouclier en
   portant si menace < 3,2 u.
7. Debug : `forceAbility(family, botName?)` + `getShieldInfo()`.

## Vérifié (probes Playwright, 0 erreur console)

- Dash : déplacement mesuré = 6,00 u pile, bouton cooldown 5 s → ready.
- Bouclier : `forceKO()` (9999 dégâts) absorbé pendant les 2 s, dégâts
  repassent après expiration ; bulle + anneau rendus (capture).
- Onde : bot Nova a frappé le porteur (100 → 90, -10) ET volé le dragon
  en ~5 s de jeu — IA bots + dégâts + vol validés en une passe.
- Boutons : décomptes « 2.4 » / « 5.4 » visibles sur la capture.

## Signalé / hors périmètre

- Les ✨ étincelles n'ont plus d'effet (recharge = temps pur) → à
  réaffecter ou retirer, décision Camille.
- L'indicateur 🐉 en bord d'écran peut frôler les boutons en bas à
  droite (cosmétique, préexistant).

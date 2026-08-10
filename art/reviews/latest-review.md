# Fiche d'itération — boutons au ras du coin + le vol du dragon marche

Retour Camille (2026-08-10, 4e passe) : « les boutons sont encore trop
haut, baisse-les vraiment en bas à droite. J'arrive pas à voler le
dragon. »

## Changements (public/spike3d-arena.html)

1. **Boutons abaissés au ras du coin** : ancre 16→6 px des bords,
   écarts internes 8→6 px. Le bas du bouton 💥 est à 6 px du bord bas
   et 6 px du bord droit.
2. **Vol du dragon — cause n°1 trouvée** : le bot porteur activait son
   bouclier INSTANTANÉMENT dès qu'on entrait à 3,2 u (= pile la portée
   de l'onde) → chaque tentative de vol du joueur était contrée.
   Désormais réaction PROBABILISTE (~50 %/s sous menace) : une fenêtre
   de vol existe toujours. L'onde des bots devient probabiliste aussi
   (~1,2/s) pour la symétrie.
3. **Vol du dragon — cause n°2** : viser le porteur au joystick pile au
   moment du tap est très dur (le cône fait ~78°). VISÉE ASSISTÉE pour
   le joueur : au cast de l'onde, si une cible est à portée (porteur du
   dragon en priorité, sinon l'ennemi le plus proche), le personnage
   pivote automatiquement vers elle avant de tirer. Les bots ne passent
   pas par là (ils visent déjà leur cible).

## Vérifié (probes Playwright, 0 erreur console)

- Vol : joueur placé à 2,2 u du porteur DOS TOURNÉ → onde → dragon volé
  (2/2 sur les tentatives valides ; les autres essais annulés par la
  partie vivante — bots qui déposent —, pas par un échec du vol).
- Layout 844×390 : bas du cluster à 6 px des deux bords, question la
  plus longue entière, 0 chevauchement, boutons immobiles.

## Réglages faciles (équilibrage du vol)

- `ABILITY_CONFIG.SHOCKWAVE_RANGE` (3,2) : portée du vol.
- `dt * 0.5` (bouclier bot) et `dt * 1.2` (onde bot) dans updateBot :
  réactivité des bots.
- Immunité au vol 1 s : `LUMIN_CONFIG` (anti ping-pong).

# Recensement des mécaniques — Arène « Chasse au dragon »

État au 2026-08-10 (demandé par Camille : « il faudrait qu'on recense un
petit peu les mécaniques »). Toutes les valeurs sont dans
`public/spike3d-arena.html` (`ENERGY`, `LUMIN_CONFIG`, `KO_CONFIG`,
`PET_DEFINITIONS`, `SPARK_CONFIG`, `ENERGY_CRYSTAL_CONFIG`).

## Boucle principale (GAMEPLAY V4, spec Camille 2026-08-10)

**La question est visible dès le top départ** (pas d'attente de capture),
sans timer de réponse — la pression vient du jeu. Le joueur peut choisir
sa réponse À TOUT MOMENT (avant ou après la capture) ; le choix est
VERROUILLÉ pour la tentative. Guidage SÉQUENTIEL : tant qu'on ne porte
pas le dragon → indicateur 🐉 (vers le dragon libre OU son porteur) ;
une fois porteur + réponse choisie → chevrons + distance vers SA zone.
Jamais deux directions à l'écran. Les badges de zones sont supprimés ;
seule la colonne de lumière de la zone choisie s'allume.

### Ancienne boucle (pré-V4, pour mémoire)

1. Un **dragon** apparaît (loin des joueurs, souvent hors écran — suivre
   l'indicateur 🐉 en bord d'écran avec la distance en mètres).
2. **L'attraper = marcher dessus** (contact, rayon 1,1).
3. Dès la 1re capture, une **question** s'affiche (bandeau du haut) et
   **4 zones de réponse A/B/C/D** apparaissent (colonnes de lumière
   colorées, réponse affichée dans la colonne en mode court).
4. **Amener le dragon dans la bonne zone** : +100 points, la manche se
   termine, nouveau dragon après un compte à rebours.
5. **Mauvaise zone** : la zone est éliminée (grisée), le porteur est
   repoussé + étourdi 0,75 s, le dragon tombe DANS la zone, libre.

## Prendre le dragon à un adversaire (2 façons)

- **Vol propre** : toucher le porteur avec la **poussée du Renard** → le
  dragon change de mains instantanément (si le porteur survit au coup).
- **Vol lourd** : mettre le porteur **K.O.** (3 poussées sur une cible à
  pleine énergie) → le dragon tombe **sur place**, libre pour tous.
- **Immunité au vol : 1 s** après toute prise (anti ping-pong). Les
  dégâts passent quand même pendant cette fenêtre.
- Le porteur est signalé par un **anneau doré** à ses pieds, et le dragon
  est **visible devant lui** (pose « dans les bras », planche 2026-08-10).

## Énergie, dégâts, K.O.

- Énergie max 100. **Plus de drain passif** (décision 2026-08-10) : on ne
  perd de l'énergie QUE sur une attaque subie ou une mauvaise réponse.
- **Poussée = 34 dégâts** (« -34 » rouge flottant sur la cible, flash
  rouge du personnage touché, secousse caméra + « ⚔️ X t'attaque ! » si
  c'est toi).
- **K.O.** (énergie à 0) : pénalité -5 points, 3 s d'attente, réapparition
  **aléatoire parmi les 4 points les plus éloignés du dragon**, énergie
  pleine, **bouclier 1,5 s** (les attaques glissent dessus).
- Récupérer de l'énergie : **bonne réponse +15**, mauvaise -10,
  **cristal d'énergie 💎 +20** (apparaît périodiquement sur la carte) —
  c'est le soin principal maintenant que le drain a disparu.

## Compétences — kit V1 (spec Camille 2026-08-10, remplace les pets)

3 pouvoirs fixes, **pur cooldown** (plus de charges, plus d'étincelles,
pas de mana). Toutes les valeurs dans `ABILITY_CONFIG` ; les familles
équipées dans `equippedAbilities` (offense/mobility/defense — prêt pour
des variantes futures, PAS de boutique pour l'instant).

- **💥 Onde de choc** (cooldown 4 s, portée 3,2, cône ~78°, **10 dégâts**) :
  repousse fort tout ce qui est dans le cône (force 2,6), **vole le
  dragon au porteur touché**. Arc blanc = limite de portée au cast.
  Pouvoir de contrôle, pas d'exécution (10 ≪ 34 d'avant).
- **⚡ Dash** (cooldown 5 s, **distance exactement 6 u**, vitesse 26 u/s
  ≈ 0,23 s) : burst dans la direction du regard, traînée cyan. La
  distance est décomptée frame par frame (`dashRemaining`) → identique
  quel que soit le framerate ; un K.O. coupe le dash net.
- **🛡️ Bouclier** (cooldown 7 s, **durée 2 s**) : bulle violette +
  anneau lumineux ; dégâts, poussées ET vols glissent dessus
  (`isShielded` dans `damageLife`/poussée/vol).
- Boutons (arc bas droite) : anneau de charge circulaire + décompte en
  secondes dans le bouton ; appui à vide = secousse « denied » ; 💥
  pulse en doré quand le porteur adverse est à portée de vol.
- **Bots** : onde si le porteur est à ≤ 3,5 u, dash s'ils sont à > 9 u de
  leur cible, bouclier quand ils portent le dragon avec une menace à
  < 3,2 u — mêmes cooldowns que le joueur.
- Héritage : les ✨ étincelles n'ont **plus d'effet** sur la recharge
  (décision en attente : les réaffecter ou les retirer). L'Éclat magique
  du Chat est retiré du kit V1 (candidat variante future).

## Interface

- Bloc de question (planche Camille 2026-08-10) : panneau sombre à
  droite, question + réponses EMPILÉES CLIQUABLES ; taper une réponse
  fait apparaître une traînée de chevrons-boussole (couleur de la zone)
  qui guide vers la zone choisie, avec un **marqueur de distance** (« 23 m »)
  au bout de la traînée. Le bandeau du haut ne sert plus qu'aux
  annonces. Tableau des scores supprimé (même décision).
- Indicateurs de bord d'écran : 🐉 dragon et zones A/B/C/D hors champ,
  avec distance ; jamais par-dessus le bandeau.
- Toast pédagogique « 🦊 Pousse le porteur pour lui voler le dragon ! »
  quand un adversaire prend le dragon (max une fois / 20 s).
- Jauge de vie : pulse sous 25 %, flash rouge quand tu es attaquée.
- Score seul détermine le classement (l'énergie est une ressource).

## Chantiers connus / réglages ouverts

- Équilibrage ouvert : 34 dégâts / K.O. 3 s / immunité 1 s / aimant 9 u.
- Visuel dédié pour le bouclier de réapparition (invisible aujourd'hui).

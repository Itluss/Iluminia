# Recensement des mécaniques — Arène « Chasse au dragon »

État au 2026-08-10 (demandé par Camille : « il faudrait qu'on recense un
petit peu les mécaniques »). Toutes les valeurs sont dans
`public/spike3d-arena.html` (`ENERGY`, `LUMIN_CONFIG`, `KO_CONFIG`,
`PET_DEFINITIONS`, `SPARK_CONFIG`, `ENERGY_CRYSTAL_CONFIG`).

## Boucle principale

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
- Le porteur est signalé par un **anneau doré** à ses pieds.

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

## Compétences (2 boutons, bas droite)

- **Charges pleines au top départ**, puis recharge : passive (lente) +
  **étincelles ✨** ramassées au sol (+10 % par étincelle et par pet).
- Bouton prêt = halo cyan ; appui à vide = secousse + message ; le bouton
  Renard **pulse en doré** quand le porteur adverse est à portée de vol.
- **🦊 Renard — Poussée** (portée 3,2, cône ~78°) : petit dash, onde de
  choc orientée, repousse + 34 dégâts + vole le dragon au porteur touché.
- **🐱 Chat — Éclat magique** (2026-08-10) : projectile rose en ligne
  droite (portée 9, extinction pile à portée max = la portée se voit),
  **22 dégâts** au premier ennemi touché. Ne vole PAS le dragon.
- **Portée visible** : au cast du Renard, l'onde s'étend jusqu'à la
  portée exacte et un **arc blanc marque la limite** ; l'éclat du Chat
  matérialise sa portée par sa trajectoire.

## Interface

- Bandeau du haut : question + correspondance lettre/couleur/réponse.
- Indicateurs de bord d'écran : 🐉 dragon et zones A/B/C/D hors champ,
  avec distance ; jamais par-dessus le bandeau.
- Toast pédagogique « 🦊 Pousse le porteur pour lui voler le dragon ! »
  quand un adversaire prend le dragon (max une fois / 20 s).
- Jauge de vie : pulse sous 25 %, flash rouge quand tu es attaquée.
- Score seul détermine le classement (l'énergie est une ressource).

## Chantiers connus / réglages ouverts

- Dragon porté enfoui dans la tête du modèle Max (n°1 de la liste).
- Équilibrage ouvert : 34 dégâts / K.O. 3 s / immunité 1 s / aimant 9 u.
- Visuel dédié pour le bouclier de réapparition (invisible aujourd'hui).

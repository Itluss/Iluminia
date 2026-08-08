# Idées futures — Eluminia

Backlog d'idées de gameplay/produit décidées comme importantes mais **pas
implémentées maintenant** — capturées ici au fil des sessions pour ne pas
les reperdre, à reprendre une par une quand le moment sera venu. Ne pas
implémenter un point de cette liste sans que Camille ne le redemande
explicitement au moment voulu.

## 1. Implication du parent — suivi de la progression (2026-08-04)

**Statut : idée fondamentale, pas encore conçue en détail.**

Constat de Camille : sans un mécanisme qui oblige le parent à revenir
régulièrement sur l'application, le jeu reste "vaguement éducatif" — le
parent ne sait pas ce que fait son enfant, ne cautionne rien, il n'y a pas
de vrai suivi. Elle considère ça comme **primordial**, pas une option
secondaire.

**Idée centrale** : une interface dédiée au parent, séparée du jeu, où il
peut voir les courbes de progression/apprentissage de l'enfant (quelles
notions vues, quels résultats, évolution dans le temps).

**Pistes de mécanismes pour FORCER le retour régulier du parent** (aucune
tranchée, à choisir/affiner plus tard) :
- Le parent doit valider quelque chose pour débloquer le temps de jeu de
  l'enfant.
- Le parent doit cliquer/valider pour que l'enfant obtienne un cadeau
  supplémentaire (l'enfant est incité à aller solliciter le parent
  lui-même pour débloquer ce coffre — le jeu pousse activement cette
  interaction).
- Autre mécanisme à imaginer, tant que le résultat est le même : le
  parent est obligé de revenir régulièrement voir où en est son enfant,
  pas juste autoriser l'installation une fois et oublier.

**Pourquoi c'est jugé essentiel** : ça légitime le temps de jeu aux yeux du
parent (cautionne l'usage), et ça rejoint directement la conclusion de la
discussion business de cette session — le vrai acheteur/décideur, c'est le
parent, et ce qu'il achète n'est pas "un jeu fun" mais "je peux suivre ce
que mon enfant apprend" (voir aussi la discussion sur le positionnement
face à Boddle/Prodigy).

## 2. Équipes + spécialisation de rôle (2026-08-04)

**Statut : idée de gameplay, pas encore conçue en détail.**

Constat de Camille : l'arène actuelle est purement individuelle (chacun
pour soi). Elle propose de créer un mode par **équipes** (ex. rouges vs
bleus), avec un **compteur de score collectif par équipe** plutôt
qu'uniquement individuel — l'objectif devient faire gagner l'équipe.

**Idée centrale associée : spécialisation des joueurs par poste**, façon
foot américain — chaque joueur choisit/obtient un rôle avec des
compétences/statistiques différentes plutôt qu'un personnage générique
identique pour tous. Exemples cités par Camille :
- un poste "tanky" pour bloquer/encaisser
- un poste plus rapide/mobile pour courir

Camille précise explicitement : **pas besoin d'une quinzaine de rôles**,
une poignée de spécialisations suffirait pour que ce soit intéressant.

**À trancher plus tard (rien n'est décidé)** : nombre de joueurs par
équipe, comment les rôles sont attribués/débloqués, comment ça s'articule
avec le système de compétences (❄️⚡🔥) déjà en place, si les rôles sont liés
à la progression/collection (cf. idée n°1 et la discussion Clash Royale sur
les cartes à débloquer).

## 3. Sélection de l'établissement scolaire (2026-08-04)

**Statut : idée de gameplay/produit, pas encore conçue en détail.**

Constat de Camille : l'utilisateur pourrait sélectionner son établissement
(son école) dans le jeu — un peu comme une guilde, mais par défaut/rattachée
à une identité réelle plutôt que choisie librement. Elle explicite que
l'intérêt n'est **pas** de mettre en valeur l'établissement en soi, mais les
mécaniques sociales que ça permettrait :
- rassembler les joueurs d'un même établissement (rejoindre les potes/l'école
  dans une même arène) ;
- comparer les établissements entre eux, façon "guerres"/battles inter-
  établissements ;
- un leaderboard des joueurs au sein d'un même établissement, pour les
  mettre en avant et les classer.

**Idée d'implémentation évoquée** : une carte interactive avec
géolocalisation (à confirmer plus tard) pour que l'utilisateur sélectionne
son établissement dessus.

**À trancher plus tard (rien n'est décidé)** : mécanique exacte de
sélection (carte géolocalisée vs recherche/liste), comment on obtient une
base d'établissements fiable, si c'est optionnel ou obligatoire à
l'inscription, comment ça s'articule avec le multijoueur réel (cf. le point
de vigilance déjà noté : l'arène ne joue aujourd'hui que contre des PNJ).
Camille évoque aussi des "déclinaisons" possibles sur ce sujet, non
précisées.

## 4. Remplacer les compétences élémentaires par les familiers (2026-08-05)

**Statut : LE point de départ prévu pour la prochaine session — pas une
idée lointaine, la suite directe de ce soir.**

Contexte : longue discussion en fin de session sur "qu'est-ce qui manque
pour que le joueur ait vraiment envie de revenir" (comparaison Clash
Royale : diversité + combinaisons + collection qui rend plus fort). Camille
a convergé sur une conclusion précise après avoir écarté plusieurs pistes
(tours à détruire, quiz en flux continu, etc. — toutes rejetées ce soir).

**L'idée centrale** : aujourd'hui on a DEUX systèmes parallèles qui se
marchent un peu dessus — les 6 compétences élémentaires (❄️⚡🔥💧🌫️⛰️, choix de
3 avant la manche, mais "figées", ne progressent pas individuellement) ET
la collection de familiers (œufs/soin/cartes, qui elle progresse mais reste
à côté du vrai combat, juste un bouton central isolé). Camille veut
**fusionner les deux** : les familiers REMPLACENT les compétences comme
mécanique de combat.

**Concrètement, ce que ça veut dire** :
- Le joueur possède plusieurs familiers (collection existante : œufs →
  éclosion → cartes → niveaux, système déjà construit et à garder tel
  quel pour l'acquisition).
- Avant une manche, il **choisit lesquels emmener** (comme le choix actuel
  de 3 compétences sur 6, mais avec ses familiers possédés à la place).
- Chaque familier a son propre effet de combat (reprendre les mécaniques
  déjà construites : gel/ralentissement/aveuglement/repousse — à répartir
  par espèce plutôt que par élément abstrait).
- **Les familiers évoluent** : pas juste un chiffre qui monte, un vrai
  changement de forme/style ET de compétences à certains paliers de
  niveau, façon Pokémon (cf. la mécanique Boddle déjà étudiée : nouvel
  équipement/pouvoir à des niveaux clés, pas une progression lisse).
- **Référence de conception ajoutée par Camille : Guild Wars (2)** — leurs
  compétences ont de vrais paramètres RPG (temps de rechargement, portée,
  coût en énergie, puissance des dégâts) qui permettent de vraies
  combinaisons/builds réfléchis, pas juste un effet plat. Camille veut
  décliner ça directement au niveau des pets : donner à chaque familier
  ces mêmes paramètres (cooldown/portée/coût/puissance) plutôt qu'un
  simple effet binaire, pour que le choix des familiers emmenés devienne
  un vrai exercice de composition de build, façon Guild Wars.

**Explicitement mis de côté pour plus tard (Camille a été claire
là-dessus)** :
- Les **fusions** de familiers (façon Pokémon, combiner deux familiers en
  un nouveau) — "on pourrait les faire fusionner à terme", mais pas
  maintenant, pas conçu.
- Les **combos** entre effets pendant un combat (ex. glace + feu =
  effet spécial ensemble) — "de combos, peut-être plus tard".
- Le lien avec la **place de marché** — Camille sent que ça se rejoint
  ("ça rejoint un peu la place de marché derrière") mais dit explicitement
  ne pas avoir encore le système : à concevoir, pas à deviner.

**Ce qui reste vrai et ne change pas** : le système d'acquisition des
familiers (œufs rares, soin, cartes, montée de niveau) reste tel qu'il a
été construit ce soir — c'est uniquement la partie "utilisation en combat"
qui change de mécanisme (familiers au lieu d'éléments abstraits).

**Prévisualisation rapide faite le 2026-08-05** : boutons de compétence de
`spike3d-arena.html` recouverts par 4 icônes pets générées (loutre, poussin,
renardin, dracoeuf — mêmes espèces que la collection), en remplacement des
icônes élémentaires générées la veille. Camille a jugé les icônes
élémentaires (style toon/peint) "particulièrement moche" — préférence
confirmée pour un style mascotte chibi/sticker (gros yeux, contours nets,
rond et mignon) plutôt que peint/toon réaliste. Pas une intégration
fonctionnelle (pas de vraie logique familier-par-bouton, juste un
recouvrement visuel 1 pet ↔ plusieurs boutons), à concevoir vraiment lors de
l'implémentation réelle de ce point 4.

**Précision de conception ajoutée le 2026-08-05 (soir) — mécanique de
sélection en cours de partie, le vrai "pourquoi" derrière l'élevage** :
Camille a fourni une planche de référence visuelle (sauvegardée dans
`art/reviews/mockup-familiar-ui-2026-08-05.png`) montrant une colonne de 4
icônes de familiers sur le bord droit de l'écran, à côté de l'arc de
compétences actuel (avec des badges numériques sur les boutons évoquant
charges/recharge, cf. la référence Guild Wars déjà notée plus haut).

L'idée précise : les familiers possédés restent affichés sur le côté PENDANT
la manche, **interchangeables en cours de partie** (pas figés au moment du
choix pré-manche comme les compétences aujourd'hui). Sélectionner un
familier donne accès à SES 3 compétences propres (son "kit"). Comme le
joueur peut changer de familier actif en cours de manche, le pool de
pouvoirs réellement accessibles sur une partie n'est plus un total fixe de
3, mais **3 × N** (N = nombre de familiers possédés, ex. 4 familiers → 12
pouvoirs potentiels sur une seule partie, en switchant). Camille : "ça
commence sérieusement à avoir de la tronche."

**Pourquoi c'est le point clé** : c'est cette mécanique qui donne enfin un
vrai sens gameplay à l'élevage/l'évolution des familiers (jusqu'ici surtout
une collection à côté du combat) — plus on possède/développe de familiers,
plus le pool de pouvoirs accessibles EN PARTIE s'élargit. Lien direct avec
la profondeur de build façon Guild Wars déjà notée ci-dessus.

Reste à trancher lors de l'implémentation (rien décidé ce soir) : le
mécanisme exact de switch en cours de manche (coût ? cooldown de switch ?
zone dédiée ? touche direct comme aujourd'hui pour les 3 slots ?), si les 3
compétences par familier sont fixes par espèce ou personnalisables, et
l'articulation avec le système de charge/énergie actuel.

---

## Rappel technique en attente (pas une idée de design)

- **Taux de drop des œufs remis à 100% pour les tests** (`spike3d-arena.html`
  `endRound()`/`finishQuiz()`, `spike3d-menu.html` `claimGift()` hebdo/mensuel)
  — retour de Camille (2026-08-04), le temps qu'elle teste le flux
  couvaison/éclosion en vrai. **À redescendre aux vrais taux** (4% fin de
  manche, 6% quiz, 8% cadeau hebdo, 20% cadeau mensuel) une fois le test
  terminé — chaque endroit modifié porte un commentaire "TEST" dans le code
  pour le retrouver facilement.

# Prompt — Construire les 20 premières heures de jeu sur la planète 1

À utiliser comme brief pour une (ou plusieurs) session(s) `/eluminia` dédiée(s).
Ne pas tout exécuter d'un coup dans une seule itération — voir "Méthode
d'exécution" plus bas. Contexte complet dans `CLAUDE.md`,
`docs/programme-cm1-quetes.md` et l'historique de
`art/reviews/history/`.

## Objectif

La planète 1 (`public/spike3d-village.html`) doit pouvoir occuper un enfant
CM1 pendant ~20h de jeu réel, réparties sur ~40 sessions de 15-30 min
(1 planète ≈ 1/10 de l'année scolaire, voir `docs/programme-cm1-quetes.md`
§ Tenue sur l'année). **20h ne veut pas dire 20h de contenu inédit** : c'est
une boucle (exploration + quêtes + habillage narratif) suffisamment riche et
rejouable pour supporter ~40 visites courtes sans lasser, pas 40 heures de
script à écrire.

## Ce qui existe déjà (ne pas reconstruire)

- Fil principal : Elda → pont des fractions (mécanique SAUT/CONSTRUCTION,
  `MISSION_PONT_ELDA`) → portail vers planète 2.
- Activité indépendante : défi des grands nombres (mécanique CUEILLETTE,
  `NUMBERS_CHALLENGE`) — **actuellement pas fun** (aucun enjeu réel, pas de
  guidage de découverte) : à corriger en le construisant, voir plus bas.
- Système de découverte déjà présent (`discovery.places`, `discovery.npcs`,
  compteurs HUD "X/12 lieux", "X/3 PNJ") — infrastructure GW2-like
  (points d'intérêt à trouver en explorant) déjà là, sous-utilisée.
- Bibliothèque de 8 mécaniques réutilisables (SAUT, TRI, CONSTRUCTION,
  APPARIEMENT, CUEILLETTE, DIALOGUE, CIRCUIT, CARTE) et mapping aux
  63 sous-thèmes CM1 : `docs/programme-cm1-quetes.md`.

## Périmètre planète 1 (~6-8 quêtes, une par sujet pour démarrer)

63 sous-thèmes / ~10 planètes ≈ 6-7 par planète. Pour la planète 1, prendre
le sous-thème le plus facile de chaque matière retenue (Maths, Français,
Anglais, Géo, Sciences, Techno) :

| Matière   | Sous-thème (le plus facile) | Mécanique | État |
|-----------|------------------------------|-----------|------|
| Maths     | Nombres entiers jusqu'à 100 000 | CUEILLETTE | Fait, à muscler (enjeu) |
| Maths     | Fractions simples | SAUT/CONSTRUCTION | Fait (pont) |
| Français  | Nature des mots | CUEILLETTE | À faire |
| Anglais   | Salutations, se présenter | DIALOGUE | À faire |
| Géographie| Points cardinaux, légende | CARTE | À faire |
| Sciences  | Le vivant : classification | TRI | À faire |
| Technologie| Objet technique et sa fonction | APPARIEMENT | À faire |

Ne PAS dépasser cette liste sans validation de Camille — pas de 2e sous-thème
par matière tant que le premier tour n'est pas joué/validé (voir Playtest).

## Exigence n°1 : un vrai enjeu par activité (non négociable)

Retour direct de Camille sur le défi des nombres actuel : « si ça prend 30s,
aucun intérêt ». Chaque quête doit avoir au moins UN des ingrédients
suivants, pas juste "marcher jusqu'au bon objet" :
- un chrono (échec si le temps s'écoule, on recommence) ;
- une tolérance d'erreur limitée (ex. 2 erreurs max avant échec) ;
- une contrainte de ciblage/mouvement (cibles qui dérivent, ordre à
  respecter, obstacle à contourner).
Choisir l'ingrédient adapté à la mécanique (ex. CARTE → temps limité pour
suivre un itinéraire ; TRI → pénalité si mauvais ordre ; DIALOGUE → un seul
bon enchaînement de réponses, pas de retry infini).

## Exigence n°2 : découverte, pas menu

Chaque nouvelle quête doit être trouvée en explorant (marqueur visuel discret
ou PNJ dans le monde, ajoutée à `discovery.places`/`discovery.npcs`), PAS
listée d'avance dans `quest-box` comme le fil principal Elda/pont. Objectif
ressenti : « je tombe dessus », pas « je coche une liste ».

## Exigence n°3 : habillage narratif différent à chaque zone

Mécanique réutilisée ≠ zone identique. Chaque quête a son propre coin de
décor (palette/props distincts, cf. leçon du défi des nombres ci-dessous),
son propre prétexte narratif (PNJ ou pancarte), même si le code du mini-jeu
est partagé.

## Leçons techniques de l'itération précédente (défi des nombres)

- **Placement de zone** : vérifier la distance à `scene.fog` (near/far,
  actuellement ~70/170) depuis la position de caméra réelle avant de choisir
  des coordonnées — une zone trop excentrée blanchit l'arrière-plan
  (défaut constaté, non corrigé). Rester repérable sans voile.
- **Ne pas chevaucher les structures existantes** (portail, hameaux, totem,
  pont, présentoir de leçon) — vérifier les coordonnées connues avant de
  placer une nouvelle zone (liste dans le fichier, section décor).
- **Capturer via le hook de debug** (téléportation `heroLogical.set()`,
  pas marche simulée — la marche est lente et peut se bloquer sur un
  obstacle placé aléatoirement, `Math.random()` non seedé).
- Étendre `window.__spikeDebug` d'un `gotoXxx` par nouvelle zone, pour
  QA/capture reproductible.

## Méthode d'exécution (obligatoire)

1. **Une itération `/eluminia` par quête**, pas une seule itération géante :
   chaque quête suit le pipeline complet (fiche → implémentation → capture
   → revue → correction si bloquant → archive → rapport). Respecte le
   budget d'1 capture + 1 revue + 1 cycle de correction par itération.
2. **Playtest après les 2-3 premières quêtes** (pas après les 7) : faire
   jouer un enfant réel avant de continuer — risque identifié que le jeu ne
   soit pas fun, à vérifier tôt, pas après avoir tout construit.
3. **Une nouvelle session dédiée** si le contexte de la session en cours
   devient lourd (règle du projet : une tâche = une session) — ce prompt est
   conçu pour être repris tel quel dans une session fraîche.
4. Cocher au fur et à mesure dans ce fichier (section suivante) — ne pas
   avancer sur la matière suivante tant que la précédente n'a pas une
   quête jouable et validée visuellement.

## Suivi

- [x] Maths — Fractions (pont, SAUT/CONSTRUCTION)
- [x] Maths — Nombres entiers (CUEILLETTE) — repris avec chrono (25s) +
      2 erreurs max + hook découverte
- [x] Français — Nature des mots (CUEILLETTE)
- [x] Anglais — Salutations (DIALOGUE à choix, PNJ Sam)
- [x] Géographie — Points cardinaux (CARTE, rose des vents chronométrée)
- [x] Sciences — Classification du vivant (TRI, paniers chronométrés)
- [x] Technologie — Objet technique (APPARIEMENT, paires chronométrées)
- [ ] **Playtest checkpoint — à faire par Camille ce soir avant toute suite**
      (les 7 quêtes sont posées mais aucune n'a été jouée par un enfant réel)

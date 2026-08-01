# Prompt pour la prochaine session — Prototype monde en tuiles

## Contexte (résumé de la session précédente)

Le monde actuel d'Eluminia (`VillageScene.ts`) est une seule image peinte
(`public/art/generated/village-world.png`, 2544×3792, Place + Bourg-nord)
avec des colliders posés à la main sous forme de rectangles mesurés à l'œil
sur des captures grillagées.

Deux problèmes de fond ont été identifiés, tous deux liés au fait qu'une
illustration peinte ne porte aucune information de jeu :

1. **Aucun raccord fiable entre deux images générées séparément.** Testé sur
   3 itérations (moteurs différents, même moteur, mesure précise, fondu de
   luminosité) : toujours une jonction visible. Une génération unique (une
   seule image continue) fonctionne, mais plafonne autour de ~2500×3800 px
   (limite du générateur d'image, gpt-image-1 comme Banana/Nano Banana Pro).
2. **Le franchissable est fragile et manuel.** Chaque forme organique (une
   rivière qui serpente) doit être approximée par des rectangles mesurés à la
   main sur une capture grillagée — lent, sujet à erreur (le héros a pu
   marcher sur l'eau lors de cette session), et à refaire à chaque nouvel
   élément.

Test réalisé et confirmé non concluant : l'outpainting/inpainting avec masque
via l'API OpenAI (gpt-image-1, `/v1/images/edits`) ne préserve PAS les pixels
protégés par le masque (testé dans les deux sens de convention transparent/
opaque) — le modèle régénère toute la zone à chaque appel. Ce n'est donc pas
une voie viable pour étendre une image existante pixel par pixel.

## Objectif de cette session : tester un système de tuiles

Prototyper (PAS migrer tout le jeu) une architecture de monde en tuiles
(Tilemap Phaser natif), qui est la technique standard des jeux 2D à grande
échelle (Stardew Valley, Zelda 2D, etc.) : un petit jeu de tuiles réutilisable
porte nativement l'info franchissable/non-franchissable, et se compose à
l'infini sans jamais créer de raccord (c'est toujours la même tuile qui se
répète).

### Étapes proposées

1. **Générer un petit tileset** dans le style actuel (référencer
   `public/art/image.png` la bible graphique + `village-world.png` pour la
   continuité de palette) : herbe (sol de base), chemin (au moins tout droit
   + virage), eau, berge/transition eau-herbe, lisière de forêt. Rester
   MINIMAL pour ce test (5-8 tuiles), pas un jeu d'autotile complet de 47
   tuiles.
2. **Générer 2-3 sprites de décor isolés** (fond transparent) : un arbre, une
   maison ou la fontaine — avec une zone de collision notée une fois pour
   toutes (pas à remesurer à chaque pose).
3. **Construire une scène de test isolée** (ex. `TileTestScene`, PAS dans
   `VillageScene` tant que le prototype n'est pas validé) :
   - charge le tileset + une petite carte de tuiles (tableau 2D écrit à la
     main pour le test, via `this.make.tilemap` / `addTilesetImage` /
     `createLayer` de Phaser) ;
   - active la collision par propriété de tuile (tuile "eau" = bloquante) ;
   - pose 2-3 sprites de décor avec leur boîte de collision ;
   - vérifie que le héros (réutiliser l'entité `Player` existante) marche
     normalement sur herbe/chemin, est bloqué par l'eau automatiquement, et
     que le motif de tuiles s'étend sans AUCUN raccord visible.
4. **Évaluer honnêtement le rendu** : une carte en tuiles est par nature plus
   répétitive qu'un diorama peint sur mesure — vérifier que ça garde
   l'identité visuelle chaleureuse d'Eluminia à cette échelle, pas un rendu
   plat/générique. Le signaler clairement si le résultat déçoit.

### Contraintes

- Test isolé : ne pas toucher `VillageScene.ts` ni supprimer
  `village-world.png` tant que Camille n'a pas validé le prototype.
- Un seul sous-agent maximum (règle du projet), génération d'images
  raisonnable (quelques tuiles + quelques sprites, pas une série).
- Utiliser le moteur Banana (`engine: "banana"`) pour rester cohérent avec le
  style déjà validé cette session (gpt-image-1 donne un rendu différent,
  confirmé par 3 échecs de raccord).
- Rapport honnête en fin de session : la technique tient-elle, à quel prix
  (nombre d'assets, complexité), et est-ce que ça vaut une vraie migration ?

# Iluminia — Chasse au dragon (version Godot)

Conversion **Godot 4.3 en vraie 3D** du cœur de jeu d'Iluminia : l'arène
« Chasse au dragon » (spike Three.js `public/spike3d-arena.html`) — caméra
isométrique orthographique (l'angle validé du spike), toon shading bandé,
contours peints par coque inversée, ciel dégradé, ombres, glow, particules,
palette bonbon. **Menu d'accueil façon jeu mobile premium** : diorama 3D
animé des héros, logo doré, gros bouton JOUER qui pulse. Tactile d'abord.
Export HTML5 automatique par GitHub Actions, publié sur GitHub Pages.

**▶ Jouer :** https://itluss.github.io/Iluminia/godot/

## L'univers graphique Iluminia — la « nuit lumineuse »

Identité propre au jeu, ancrée sur le design system existant
(`public/ui/theme.css` + planche `public/ui/style-guide-fantasypop.png`) :

- **`scripts/identite.gd` est la source de vérité du style** : surfaces
  marine profond, contours BD épais, accents néon (or, bleu, cyan, violet,
  magenta), rayons et bords. Pour faire évoluer le style, on ne touche que
  ce fichier (+ les fiches de personnages).
- **Les Lumins** (`personnage3d.gd`) : nos personnages signature — petits
  porteurs de lumière ronds et joufflus, écharpe au vent, et leur
  **crête-lumière** émissive qui les identifie en un coup d'œil dans la
  nuit (Max : étoile or — l'écho du logo ; Zep : éclair cyan + hoverboard ;
  Nova : goutte ; Ficelle : flamme). **Évolutif** : un nouveau héros = une
  nouvelle FICHE (couleurs, crête, accessoire), rien d'autre.
- **L'arène** : une **île flottante bioluminescente** dans la nuit —
  pelouse sombre-turquoise, lisière-lumière cyan, falaise de roche violette
  hérissée de cristaux, arbres-lanternes, fleurs-lumen, lucioles, rochers
  en orbite. Les zones A/B/C/D sont des anneaux néon aux couleurs des
  boutons de réponse (vert/bleu/or/magenta).
- **L'interface** (`ui.gd`) : le kit de la planche porté en code —
  panneaux marine, boutons joufflus glossy, hexagone « ? » violet, jauge
  d'énergie à éclair, bannière VICTOIRE à rubans, fenêtres à titre + ✕,
  coffre de récompense, indicateurs, badges NEW, podium à pastilles de
  rang, JOUER doré pulsé.

## LE SYSTÈME DE JEU — pourquoi on rejoue

Structure inspirée de l'étude des références du genre (Brawl Stars,
Clash Royale) : une colonne vertébrale de progression visible, des
personnages qui sont eux-mêmes des récompenses, des quêtes quotidiennes
qui ramènent chaque jour, et de la montée en puissance à acheter.

- **Route des Trophées** (Trophy Road) : 17 paliers de 20 à 1000
  trophées, chacun à RÉCLAMER — pièces, œufs, dragons garantis… et
  surtout LES HÉROS : on démarre avec Max seul, **Zep se gagne à 40
  trophées, Nova à 120, Ficelle à 280**.
- **Quêtes du jour** : 3 quêtes tirées chaque matin (gagner des matchs,
  déposer, voler, bonnes réponses, cristaux…), suivies en direct pendant
  les parties (« QUÊTE TERMINÉE ! »), récompenses en pièces au lobby.
- **Puissance des héros** (power levels) : 1 → 5 en pièces
  (100/200/400/800), +3 %% de vitesse et −3 %% de recharge par niveau.
- **3 ambiances d'arène** tirées au sort par match : Nuit lumineuse,
  Crépuscule doré, Aurore magenta.
- Lobby réorganisé façon Brawl Stars : héros au centre, JOUER en bas à
  droite, colonne d'écrans à gauche, QUÊTES avec badge au-dessus.

La boucle du joueur (`profil.gd`, tout est persisté) :

- **Trophées & Ligues** : chaque match rapporte ou coûte des trophées
  selon le rang (+30/+15/+5/−10) → Bronze, Argent (100), Or (250),
  Cristal (450), Légende (700). L'insigne de ligue s'affiche au lobby.
- **Pièces d'or** : gagnées à chaque match (10 + score/5, +20 au 1er) et
  au cadeau du jour ; dépensées en boutique (œufs 150 P, couleurs 80 P).
- **Œufs & Sanctuaire** : finir 1er = un œuf garanti (2e : 30 %). L'œuf
  éclot au Sanctuaire en l'une des 6 ESPÈCES de dragons (Lueur commun,
  Braise/Givre rares, Orage épique, Solaire légendaire, Éclipse
  mythique). Doublon = +50 pièces. La collection est LE but long terme.
- **Compagnon** : un dragon de ta collection vole à tes côtés EN PARTIE,
  visible par tous — c'est lui qu'on t'envie.
- **Niveaux de héros** : l'XP du match va au héros joué et ouvre ses
  couleurs par paliers (Niv 2/4/6).

En manche : **dépôt canalisé** (tenir 1,5 s dans la zone, interrompu si
on te vole le dragon) → de vraies batailles de zone ; **flèche-boussole**
permanente vers le dragon (or = libre, rouge = porté par un adversaire) ;
le dragon apparaît loin des zones et porte une balise dorée ; les bots
« lisent » 1,2-2,5 s avant de partir.

## Le lobby et ses sous-écrans (`menu.gd`)

- **Accueil** : logo étoilé, badge **niveau/XP de compte**, indicateur
  d'**étoiles**, JOUER doré, boutons PERSONNAGES / POUVOIRS / CADEAUX
  (badge NEW quand le coffre est prêt), boutons son et aide.
- **Personnages** (mode focus) : le héros en grand au centre du diorama,
  flèches ‹ › pour changer, **niveau de héros + barre d'XP** (gagnés en
  jouant avec lui), garde-robe de 4 couleurs avec **paliers affichés**
  (« Niv 2 », « Niv 4 », « Niv 6 » — ou coffre quotidien), JOUER AVEC LUI.
- **Pouvoirs** : le kit équipé en slots (Onde/Dash/Bouclier) + slots « + ».
- **Sanctuaire** : la collection des 6 dragons (cartes « ??? » tant
  qu'ils ne sont pas obtenus), éclosion des œufs, choix du compagnon.
- **Boutique** : cadeau du jour (pièces ou œuf), achat d'œufs.
- **Aide** : la boucle du jeu et les contrôles.

La méta est persistée par l'autoload **`profil.gd`** (`user://profil.cfg`,
IndexedDB sur le web) : personnage choisi, variantes débloquées, **XP par
héros** et niveau/XP de compte (gagnés au podium : 20 + score/2, étoiles
selon le rang), tutoriel vu, son. Un **tutoriel guidé** (3 consignes
contextuelles) accompagne la toute première manche.

Confort et fun : résolution de référence 864×486 (interface nettement
plus grande), caméra rapprochée (14,5), arène équilibrée (rayon 15,5 u),
match de 4 minutes, bots ralentis avec temps de réaction, le dragon
s'essouffle après 8 s de fuite et porte une BALISE dorée (faisceau +
flèche rebondissante) quand il est libre, traînée dorée derrière le
porteur, célébration à la capture, annonce à chaque apparition.
Crochet de dev : `ILUMINIA_ECRAN=personnages|pouvoirs|cadeaux|aide` ouvre
un sous-écran directement (captures automatisées).

Tout est 100 % procédural (aucun asset externe, sons synthétisés) : le jeu
entier pèse ~34 Mo. Threads désactivés à l'export → fonctionne sur GitHub
Pages sans en-têtes COOP/COEP, mobile compris.

## La boucle (V6 — la question se traite AVANT l'action)

1. **QUESTION (6 s)** — question de maths CM1 en grand, tout le monde est
   figé, chacun choisit sa réponse (modifiable jusqu'au départ, bots
   compris — précision 0,5).
2. **JEU (manche de 60 s, CONTINUE)** — le dragon apparaît loin des
   chasseurs et **s'enfuit** (plus lent qu'eux). L'attraper = marcher
   dessus. Le porteur suit ses chevrons-boussole vers la zone A/B/C/D de
   SA réponse et doit **canaliser 1,5 s** dans la zone pour déposer.
3. **Dépôt réussi = +100… et la manche continue** : le dragon renaît
   ailleurs 2 s plus tard et une **nouvelle question** tombe — tout le
   monde re-choisit sa réponse en pleine action (format « Gem Grab »).
   Au gong des 60 s, tenir le dragon rapporte **+50**.
4. **Mauvaise zone** — refus, dragon lâché sur place, fautif gelé 2 s,
   réponse barrée POUR LUI seulement ; la partie continue pour les autres.

Match en **3 manches de 60 s**, podium et récompenses, on rejoue d'un
toucher.

## Voler le dragon

- **Vol propre** : toucher le porteur avec l'**Onde de choc** → le dragon
  change de mains (immunité 1 s anti ping-pong).
- **Vol lourd** : mettre le porteur **K.O.** (énergie à 0) → le dragon
  tombe sur place. K.O. : -5 points, 3 s, réapparition loin du dragon avec
  bouclier 1,5 s.
- Énergie (100 max) : perdue uniquement sur attaque subie (-10) ou mauvaise
  réponse (-10) ; bonne réponse +15, **cristal 💎 +20** (le soin principal).

## Les trois pouvoirs (recharge pure, boutons ≥ 76 px)

| Pouvoir | Recharge | Effet | Touche |
|---|---|---|---|
| 💥 Onde de choc | 4 s | cône ~78°, portée 3,2 u, 10 dégâts, repousse et **vole le dragon** ; visée assistée | `E` |
| ⚡ Dash | 5 s | exactement 6 u à 26 u/s, décompté frame par frame | `R` |
| 🛡️ Bouclier | 7 s | bulle 2 s : dégâts, poussées ET vols glissent dessus | `Espace` |

Mobile : joystick flottant (pouce, moitié gauche) + boutons avec anneau de
recharge (secousse « denied » à vide, l'Onde pulse en doré quand le vol est
possible). Clavier : ZQSD/WASD/flèches, réponses au 1-4.

## Personnages

Max (joueur, menthe), et les bots **Zep** (violet), **Nova** (mauve),
**Ficelle** (rose) — mêmes pouvoirs et cooldowns que le joueur, réflexes du
spike (onde à ≤ 3,5 u, dash à > 9 u, bouclier sous menace en portant).

## Architecture (un script = une responsabilité)

| Script | Rôle |
|---|---|
| `scripts/menu.gd` | écran d'accueil : diorama 3D animé + interface premium (JOUER) |
| `scripts/main.gd` | scène de jeu : caméra iso, ambiance, câblage des couches |
| `scripts/arene.gd` | machine d'états de manche, monde 3D, zones, dragon, cristaux, podium |
| `scripts/chasseur.gd` | joueur ET bots : énergie, pouvoirs, vol, K.O. ; IA des bots |
| `scripts/dragon.gd` | fuite (détection 5,5 u, panique 2,6 u), pose « dans les bras » |
| `scripts/questions.gd` | générateur maths CM1 (fractions, opérations, conversions) |
| `scripts/hud.gd` | question, réponses cliquables, joystick, boutons, indicateurs de bord, podium |
| `scripts/fx.gd` | particules en étoiles, textes flottants 3D, anneaux, traînées, screen shake |
| `scripts/personnage3d.gd` | chibis toon procéduraux (héros + dragon), squash, flash, anneau doré |
| `scripts/materiaux.gd` | matériaux toon, contours coque inversée, émissifs, primitives |
| `scripts/ambiance.gd` | ciel dégradé, soleil + ombres, appoint froid, glow |
| `scripts/audio.gd` | autoload : sons 100 % synthétisés (AudioStreamWAV) |
| `scripts/reseau.gd` | **squelette multijoueur v2** (WebSocket) — commenté, non actif |
| `scripts/pedagogie.gd` | **branchement Eluminia** : photos → IA → missions (remplace questions.gd) |

Toutes les valeurs de gameplay viennent du spike (mêmes unités), source :
`docs/mecaniques-arene.md`.

## Remplacer les visuels code par des sprites

Chaque entité possède un nœud `Sprite2D` vide à côté de son `VisuelCartoon` :

```gdscript
$Sprite2D.texture = preload("res://assets/mon_sprite.png")
visuel.visible = false
```

Déposez les images dans `assets/` (voir `assets/README.md`).

## Lancer en local / exporter

```bash
godot --path godot                # jouer (éditeur ou binaire 4.3+)
godot --headless --path godot --export-release "Web" build/web/index.html
```

L'export CI (`.github/workflows/deploy-pages.yml`, image
`barichello/godot-ci:4.3`) publie le jeu sous `/godot/` avec le site
existant à chaque push sur main, puis vérifie que les URL répondent 200.

## Activer le multijoueur (v2)

Tout est balisé dans `scripts/reseau.gd` : déployer un relais WebSocket
(Render/Fly.io, WSS), instancier `Reseau` dans `main.gd`, transformer en RPC
les intentions (pouvoirs, choix de réponse, tentative de zone). L'arène est
déjà l'autorité unique et les bots sont des `Chasseur` comme le joueur —
aucun autre fichier à réécrire.

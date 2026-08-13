# Iluminia — Chasse au dragon (version Godot)

Conversion **Godot 4.3 en vraie 3D** du cœur de jeu d'Iluminia : l'arène
« Chasse au dragon » (spike Three.js `public/spike3d-arena.html`) — caméra
isométrique orthographique (l'angle validé du spike), toon shading bandé,
contours peints par coque inversée, ciel dégradé, ombres, glow, particules,
palette bonbon. **Menu d'accueil façon jeu mobile premium** : diorama 3D
animé des héros, logo doré, gros bouton JOUER qui pulse. Tactile d'abord.
Export HTML5 automatique par GitHub Actions, publié sur GitHub Pages.

**▶ Jouer :** https://itluss.github.io/Iluminia/godot/

Aucun asset externe : monde et personnages 100 % procéduraux, sons
synthétisés au démarrage. Threads désactivés à l'export → fonctionne sur
GitHub Pages sans en-têtes COOP/COEP, mobile compris.

## La boucle (V5 — la question se traite AVANT l'action)

1. **QUESTION (6 s)** — question de maths CM1 en grand, tout le monde est
   figé, chacun choisit sa réponse (modifiable jusqu'au départ, bots
   compris — précision 0,5).
2. **JEU (45 s)** — le dragon apparaît loin des chasseurs et **s'enfuit**
   (plus lent qu'eux). L'attraper = marcher dessus. Le porteur suit ses
   chevrons-boussole vers la zone A/B/C/D de SA réponse.
3. **Fins de manche** — bonne zone déposée : **+100**, fin immédiate.
   Chrono à 0 : le porteur actuel gagne (+100) — garder le dragon reste un
   objectif quand on doute. Dragon au sol : personne ne marque.
4. **Mauvaise zone** — refus, dragon lâché sur place, fautif gelé 2 s,
   réponse barrée POUR LUI seulement ; la partie continue pour les autres.

Match de 3 minutes, podium, on rejoue d'un toucher.

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

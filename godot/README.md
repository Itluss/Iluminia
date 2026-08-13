# Iluminia — Terres d'Émeraude (région Godot)

Action-RPG 2D vue du dessus, **tactile d'abord**, style cartoon aux couleurs
saturées et gros contours — première région d'Iluminia convertie en
**Godot 4.3**, exportée en HTML5 par GitHub Actions et publiée sur GitHub
Pages.

**▶ Jouer :** https://itluss.github.io/Iluminia/godot/

Aucun asset externe : visuels dessinés par code (formes vectorielles),
sons synthétisés au démarrage. Fonctionne sur mobile depuis un simple lien
(threads désactivés à l'export : pas besoin d'en-têtes COOP/COEP).

## Contrôles

| | Mobile | Clavier |
|---|---|---|
| Déplacement | joystick flottant (pouce, moitié gauche) | ZQSD / WASD / flèches |
| Auto-attaque | automatique à portée (~80 px) | automatique |
| Tourbillon (zone 110 px, 5 s) | bouton bleu | `E` |
| Nova (zone 190 px, 9 s) | bouton orange | `R` |
| Roulade (0,32 s d'invincibilité, 1,6 s) | bouton vert | `Espace` |

## Le monde

Disque de 2600 px de rayon, 4 zones concentriques : **Clairière** (niv. 1,
sangliers), **Forêt** (niv. 3, loups + araignées tireuses), **Marais**
(niv. 6, zombies + scorpions tireurs), **Terres Brûlées** (niv. 10, ogres +
**boss dragon** 1200 PV, enragé à 50 % : vitesse ×1,5 et salves circulaires
de 8 projectiles / 2,2 s — une boussole pointe vers lui).

12 orbes de lumière secrets (+PV max, +XP), % d'exploration, minimap
circulaire, butin à 5 raretés (Commun ×1 → Mythique ×12) auto-équipé s'il
est meilleur, courbe d'XP `40 × 1,4^niveau`, mort = retour au sanctuaire.

## Architecture (un script = une responsabilité)

| Script | Rôle |
|---|---|
| `scripts/main.gd` | assemble les couches, câble les références, actions clavier |
| `scripts/monde.gd` | zones, décor procédural déterministe (graine fixe), secrets, exploration, apparitions |
| `scripts/joueur.gd` | déplacement, auto-attaque, compétences, stats, équipement |
| `scripts/ennemi.gd` | 6 types configurés dans `TYPES`, IA repos/poursuite/retour |
| `scripts/boss_dragon.gd` | dragon : rage, salves circulaires |
| `scripts/projectile.gd` / `objet_loot.gd` | projectiles ennemis / butin et raretés |
| `scripts/hud.gd` | joystick, boutons tactiles, barres glossy, minimap, boussole, messages |
| `scripts/fx.gd` | squash & stretch, chiffres flottants, étoiles, anneaux, screen shake |
| `scripts/audio.gd` | autoload : sons 100 % synthétisés (AudioStreamWAV) |
| `scripts/visuel.gd` | tout le dessin cartoon par code |
| `scripts/reseau.gd` | **squelette multijoueur v2** (WebSocket) — commenté, non actif |
| `scripts/pedagogie.gd` | **squelette Eluminia** : branchement photos → IA → missions |

## Remplacer les visuels code par des sprites

Chaque entité possède un nœud `Sprite2D` vide à côté de son `VisuelCartoon` :

```gdscript
$Sprite2D.texture = preload("res://assets/mon_sprite.png")
visuel.visible = false
```

Déposez les images dans `assets/` (voir `assets/README.md`). Le décor se
remplace dans `monde.gd` (`ChunkDecor._draw`).

## Lancer en local / exporter

```bash
godot --path godot                # jouer (éditeur ou binaire 4.3+)
godot --headless --path godot --export-release "Web" build/web/index.html
```

L'export CI (`.github/workflows/deploy-pages.yml`) utilise l'image
`barichello/godot-ci:4.3` puis publie sur Pages avec le site existant.
Préréglage web : `thread_support=false` (SharedArrayBuffer non requis),
canvas redimensionnable, orientation paysage.

## Activer le multijoueur (v2)

Tout est balisé dans `scripts/reseau.gd` : déployer un relais WebSocket
(Render/Fly.io, WSS), instancier `Reseau` dans `main.gd`, transformer les
appels directs listés en RPC (`MultiplayerSynchronizer` pour les joueurs,
`MultiplayerSpawner` pour le monde). La séparation joueur/monde/interface
est déjà en place — aucun autre fichier à réécrire.

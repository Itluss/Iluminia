# Eluminia — Design system 2D

Système de design pour le HUD/menu 2D d'Eluminia. Zéro build : deux fichiers
statiques (`theme.css`, `icons.js`) liés depuis chaque écran (`spike3d-*.html`).
Aucune image utilisée pour les boutons/barres/badges — tout est CSS (dégradés,
box-shadow superposées) + SVG (sprite d'icônes injecté en JS).

Référence vivante : [`/ui-styleguide.html`](../ui-styleguide.html) — montre
tous les composants et leurs états, à garder à jour à chaque ajout.

## Intégration dans un écran

```html
<link rel="stylesheet" href="ui/theme.css" />
...
<script src="ui/icons.js"></script>
```

## Tokens (`theme.css`, bloc `:root`)

- **Couleurs** : `--el-gold/orange/magenta/purple/blue/cyan` (palette principale),
  `--el-success/danger/warning` (statut), `--el-bg-deep/panel/panel-light`
  (surfaces sombres), `--el-outline` (contour marine épais commun à tous les
  composants), `--el-text-main/muted/on-light`.
- **Forme** : `--el-radius-sm/md/lg/pill`, `--el-border-w`.
- **Espacement** : `--el-space-1` à `--el-space-6` (4px → 32px).
- **Contrôles** : `--el-control-min` (56px, taille tactile mini), `--el-icon-sm/md/lg`.
- **Élévation** : `--el-elev-1/2/3` — profondeur du "socle" sous les boutons
  (voir `.el-btn`, technique décrite plus bas).
- **Rythme** : `--el-fast`/`--el-med` (respectent `prefers-reduced-motion`).

Changer une valeur dans `:root` se répercute partout — aucune couleur ne doit
être écrite en dur dans un écran, seulement les tokens ou une nouvelle variante
de composant si un vrai nouveau rôle apparaît.

## Composants

| Composant | Classe de base | Variantes |
|---|---|---|
| Bouton | `.el-btn` | `--primary/secondary/purple/danger/success/neutral`, `--sm/lg`, `--icon`, `--circle` |
| États bouton | `.is-pressed`, `.is-selected`, `:disabled`/`.is-disabled` | |
| Barre de statut | `.el-bar` + `.el-bar-track` + `.el-bar-fill` | `--health/energy/xp/gold/success`, `.is-low` |
| Progression segmentée | `.el-segments` + `.seg`/`.seg.is-filled` | |
| Compteur | `.el-chip` | |
| Notification | `.el-notif-dot` (sur `.has-notif`) | |
| Étiquette | `.el-tag` | couleur via `background` inline ou nouvelle variante |
| Compétence | `.el-skill-slot` + `.el-skill-slot-icon` | `.is-ready/.is-locked/.is-empty`, `--charge` (0-100) |
| Joystick | `.el-joystick-base` + `.el-joystick-thumb` | positionnement laissé à l'écran (fixed) |
| Fenêtre | `.el-modal-backdrop.show` + `.el-modal-card` | `--reward` |
| Toast | `.el-toast.show` | |
| Panneau question | `.el-question-panel` + `.el-question-icon/text/timer` | |
| Réponses | `.el-answers` + `.el-answer` | `.is-correct/.is-wrong` |
| Classement | `.el-rank-row` + `.el-rank-pos/avatar/name/score` | `.is-mine` |

`.el-question-timer` affiche le compte à rebours en secondes avant expiration
de la question (pas un score) — icône éclair par convention visuelle avec les
barres d'énergie, à ne pas confondre avec un gain de points.

### Technique du bouton "gomme" (volume simulé, sans image)

`.el-btn` combine deux effets CSS :
1. Un **socle plein** via `box-shadow: 0 <élévation> 0 <couleur-socle>` — un
   bloc de couleur uni sous le bouton qui simule l'épaisseur.
2. Un **reflet glacé** via le pseudo-élément `::before` (dégradé blanc→transparent
   en haut du bouton).

À l'appui (`:active`/`.is-pressed`), le bouton descend de la hauteur du socle
(`translateY`) et le socle repasse à 0 — sensation réelle d'enfoncement, sans
sprite d'état séparé.

## Icônes

`icons.js` injecte un sprite `<symbol>` unique au chargement de la page.
Utilisation :

```html
<svg class="el-icon"><use href="#icon-play"></use></svg>
```

`currentColor` hérite la couleur du texte du parent — pas de variante par
couleur à maintenir. Liste actuelle : voir `ELUMINIA_ICON_NAMES` dans la
console, ou la section Palette/Boutons de la styleguide.

**Remplacer une icône temporaire par un asset définitif** (ex. illustration 3D
future) : remplacer le contenu du `<symbol>` correspondant dans `icons.js`
(ou, pour un asset plus riche qu'un symbole vectoriel simple, remplacer le
`<svg><use></svg>` par une balise `<img>` pointant vers le nouvel asset — les
classes `.el-icon`/`.el-icon--sm/--lg` gèrent déjà le dimensionnement dans les
deux cas). Aucun composant CSS n'a besoin d'être modifié.

## Ajouter un nouvel écran

1. Lier `ui/theme.css` et `ui/icons.js` (voir intégration ci-dessus).
2. Réutiliser les classes `.el-*` existantes — ne pas réécrire un bouton/une
   barre en CSS ad hoc si un composant équivalent existe déjà.
3. Un vrai nouveau rôle (ex. une nouvelle couleur de bouton) → ajouter une
   variante dans `theme.css` (`.el-btn--xxx`), pas un style local dans l'écran.
4. Ajouter le nouveau composant/variante à `ui-styleguide.html` pour qu'il
   reste visible dans la référence.

## Ce qui reste hors de ce système (volontaire)

Le monde 3D (Three.js, `spike3d-*.html`) reste 100% procédural — ce design
system ne couvre que le HUD/menu DOM par-dessus. `spike3d-village.html` et
`spike3d-planet2.html` ont encore leur propre palette `--el-*` historique
(non alignée) — prévu en phase d'harmonisation, pas encore fait.

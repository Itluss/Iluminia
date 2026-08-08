# illuminia-design

Ce dossier contient les **références graphiques validées** d'Illuminia —
la source de vérité pour le design de chaque écran du jeu.

Ce n'est **pas du code applicatif**. Le jeu réel vit dans `public/` (voir
le `CLAUDE.md` racine pour l'architecture du spike 3D). `illuminia-design`
ne tourne jamais dans le jeu — il sert uniquement de référence de
comparaison.

## Structure

```
illuminia-design/
  README.md
  components/              (futur — composants de référence transverses)
  screens/
    home/
      reference.html
      reference.css
    pets/                  (futur)
    inventory/             (futur)
    character/             (futur)
```

Chaque écran validé a son propre dossier sous `screens/<screen-name>/`
avec un `reference.html` + `reference.css`.

## Règles absolues

- **Les références sont IMMUTABLES après validation par Camille.** Une
  fois qu'un écran a son `reference.html`/`reference.css` créés depuis un
  contenu fourni explicitement par Camille, ces fichiers ne sont plus
  modifiés — ni pour corriger un détail, ni pour les faire évoluer avec
  l'application. Toute évolution du design passe par une nouvelle
  validation de Camille (nouvelle référence ou mise à jour explicitement
  demandée).
- **Claude Code doit consulter la référence de l'écran concerné avant
  toute modification graphique de cet écran** dans l'application. En cas
  de doute sur une couleur, une géométrie ou un composant, la référence
  fait foi — pas une impression visuelle, pas une planche externe.
- **Les références ne sont jamais utilisées comme assets** (pas de
  capture d'écran de la référence intégrée au jeu, pas de crop, pas
  d'iframe la chargeant en prod). Elles sont **reproduites** en vrais
  composants HTML/CSS/SVG dans l'application, avec les données/handlers
  réels du jeu branchés dessus.
- Si un écart entre la référence et l'application est nécessaire
  (fonctionnalité inexistante côté jeu, contrainte technique), l'écart se
  traite **dans les fichiers de l'application** — jamais en modifiant la
  référence pour la faire correspondre à l'application.

## Écrans disponibles

- `screens/home/` — Home Screen / lobby (intégrée dans
  `public/spike3d-menu.html`).

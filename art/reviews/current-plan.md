# Fiche d'itération — Refonte inventaire : icônes découpées depuis la planche

## Objectif utilisateur
Nouveau processus validé avec Camille : quand elle fournit une planche de
référence, ses éléments graphiques doivent être DÉCOUPÉS (crop + fond
transparent) depuis les pixels réels du fichier, jamais régénérés par IA.
Elle a déposé `art/board/image.png` (1402×1122px, planche « inventaire »)
et veut que le style/structure de son menu inventaire matche cette planche
à la lettre.

## Constat sur l'existant
Les icônes actuellement utilisées (`public/ui/generated/icon-backpack.png`,
`icon-helmet.png`) sont des générations IA défectueuses : fond opaque avec
halo/vignette brunâtre au lieu d'un vrai fond transparent — visible
nettement une fois les icônes agrandies (dernière itération de grossissement
de la barre d'accès rapide). Les onglets du menu inventaire utilisent des
formes CSS approximatives (dégradés/clip-path) au lieu de vraies icônes.

## Décision explicite de Camille sur le contenu
Structure/style de la planche = à respecter à la lettre. Contenu de la
grille = PAS les items RPG génériques de la planche (épée/bouclier/potions),
mais les vraies ressources du jeu. Seules ressources réellement trackées
actuellement : `progress.coins` et `progress.stars`
(`spike3d-village.html` ~L475, L616-619). Pas d'invention de quantités
fictives pour fragments/lanterne (aucune mécanique de collecte réelle) —
hors périmètre pour cette itération.

## Fichier concerné
`public/spike3d-village.html` uniquement (HUD DOM, menu inventaire absent de
`spike3d-planet2.html`). Nouveaux fichiers d'icônes dans `public/ui/`.

## Assets — découpe depuis la planche (pas de génération IA)
Script Playwright ponctuel : charge `art/board/image.png` sur un canvas,
crop une zone, color-key du fond (échantillonnage aux coins + tolérance),
rognage automatique aux pixels non-transparents restants. Sortie en PNG,
remplace les fichiers existants du même nom pour ne pas casser les
références HTML :
- Sac à dos (planche section 1, grande, propre) → `icon-backpack.png`
- Casque (planche section 5 « Équipement ») → `icon-helmet.png`
- Potion (section 5 « Consommables ») → nouvelle icône onglet Consommables
- Gemme (section 5 « Ressources ») → nouvelle icône onglet Ressources
- Parchemin (section 5 « Quêtes ») → nouvelle icône onglet Quêtes (au lieu
  de réemployer `icon-book.png`, qui sert déjà à autre chose dans le HUD)
- Pochette (section 5 « Autres ») → remplace `icon-pouch.png` si le style
  diverge nettement de la planche
- Carte, engrenage (section 2, seule source dispo, plus petite) →
  `icon-map.png`, `icon-gear.png`

## Changements fonctionnels
- Grille peuplée avec 2 entrées réelles seulement : Pièces (`res-coin.png`,
  quantité = `progress.coins`) et Étoiles (`res-star.png`, quantité =
  `progress.stars`), sélectionnables au clic → panneau de détail (icône,
  nom, catégorie, description courte, sans fausses stats Défense/Agilité).
  Reste des cases vides (pointillés), comme sur la planche.
- Les 5 autres onglets restent désactivés (aucune mécanique équipement/
  consommables/quêtes/ressources triées n'existe) — mais avec les VRAIES
  icônes découpées à la place des formes CSS.
- Pas de système de rareté (section 6 planche) : hors périmètre, aucun objet
  du jeu n'a de rareté. Seul un état "sélectionné" simple au clic.

## Changements visuels
CSS de `#inventory-modal` ajusté pour matcher la planche section 3 :
header, tabs (icônes réelles), grille (badge quantité, coin arrondi, état
sélectionné), panneau de détail, footer (déjà conforme).
Quick-access-bar : icônes remplacées par les découpes fidèles.

## Risques
- Color-key imparfait → liseré résiduel autour d'une icône : à vérifier
  visuellement après découpe avant intégration.
- Carte/engrenage en résolution plus faible (seule source = petite vignette
  planche) — acceptable vu leur taille d'affichage en jeu.

## Critères d'acceptation
- Icônes du quick-access-bar et du menu inventaire réellement transparentes
  (plus de halo brunâtre visible).
- Structure du panneau inventaire visuellement alignée sur la planche.
- Pièces/Étoiles avec vraies valeurs, sélectionnables.
- Aucune régression : ouverture/fermeture inventaire, reste du HUD,
  déplacement, dialogue, pont, portail.

## Hors périmètre (explicite)
- Rareté des objets, mécaniques équipement/consommables/quêtes.
- Tracking des fragments de fraction / lanterne comme objets d'inventaire.

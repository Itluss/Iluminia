# Fiche d'itération — écran PERSONNAGES (v1)

Spec Camille (2026-08-12) : reproduire quasi pixel-perfect la grande
maquette « ÉCRAN PERSONNAGES - ILLUMINIA » (pas la planche de doc autour),
avec le MÊME design system que la Home. Précision en cours de route :
« je ne suis pas attaché au personnage mais au graphisme de la page » —
les tenues sont pour l'instant de simples couleurs de pull.

## Ce qui est en place (public/personnages.html)

- Même architecture que la Home : scène logique 1536×864, échelle
  uniforme, colonnes ancrées aux vrais bords (--edge-x), fond peint
  identique, zéro scroll, zéro emoji.
- Top bar copiée de la Home (carte joueur, XP, monnaies, burger).
- ZONE A : 5 boutons de nav au style Home ; PERSONNAGES en état
  sélectionné (bleu lumineux, contour cyan, halo, badge orange « ! »).
- ZONE B : Max seul sur socle de pierre circulaire — asset pré-rendu
  `ui/max-pedestal.png` (+ 3 variantes de couleur de pull), généré
  depuis le GLB avec socle procédural. Le clic sur une vignette de
  tenue change réellement la couleur du pull du grand Max.
- ZONE C : panneau marine (MAX + badge ÉPIQUE, RÔLE : AVENTURIER,
  description, 4 barres de stats segmentées bleu/vert/orange/violet,
  3 cartes de compétences cerclées de couleur avec glow, carrousel
  TENUES avec sélection dorée + coche verte + flèche >).
- Bas : AMÉLIORER (philosophie exacte du bouton JOUER) +
  PERSONNALISER bleu avec pinceau (→ spike3d-menu.html, la garde-robe).
- Icônes SVG ajoutées au sprite : tshirt, sword, brush, arrowUp,
  chevronRight, chart, shield, flame, swirl, target, evolve, sparkle.
- Home : le bouton PERSONNAGE pointe désormais vers personnages.html.
- Retour discret : la carte joueur (haut gauche) ramène à l'accueil.

## Vérifié (0 erreur console)

- Captures 1536×864 et 844×390 (iPhone paysage) : tout visible, aucune
  coupure, colonnes au bord de l'écran, TENUES ancré en bas du panneau.

## À surveiller / suite possible

- Les vignettes de tenues sont des recolorations du pull (choix validé
  « nous changerons simplement la couleur du pull pour commencer ») ;
  de vraies tenues (casquette, lunettes…) demanderont des modèles.
- AMÉLIORER / compétences / autres onglets de nav : « Bientôt
  disponible ! » en attendant les mécaniques.

# Fiche d'itération — écran SÉLECTION DE PERSONNAGES (v1)

Spec Camille (2026-08-12, maquette 3) : reproduction quasi pixel-perfect,
Home = référence de style, maquette = référence de layout.

- public/selection-personnages.html : top bar (retour + titre/sous-titre,
  monnaies, burger), profil joueur, nav gauche (PERSONNAGES sélectionné),
  PUISSANCE TOTALE, TRIER PAR + Rareté, panneau principal (filtres
  TOUS/ÉPIQUE/RARE/COMMUN fonctionnels, compteur 8/16, grille 5×2),
  footer OBTENEZ PLUS DE HÉROS + VOIR LES COFFRES (style JOUER).
- MAX : vrai portrait 3D, carte sélectionnée (or + glow + coche).
- AXEL/MIRA verrouillés (grayscale + cadenas + Débloquer avec 50 gemmes).
- Pas de clé d'API image dans la session cloud → les 9 autres héros sont
  des placeholders SVG propres (public/ui/heroes/hero-*.svg), à remplacer
  par de vraies illustrations quand la génération sera à nouveau possible.
- Navigation : Home → sélection ; carte MAX → écran détail personnages ;
  retour → Home. Vérifié en 1536×864, 932×430, 844×390, 667×375
  (0 erreur console, aucun scroll, aucune coupure).

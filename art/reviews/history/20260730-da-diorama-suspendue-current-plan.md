# Fiche d'itération — da-diorama (2026-07-30)

- Demande : changer la direction artistique — village miniature stylisé
  jeunesse (référence = maquette « Village des Décimaux » d'image1.png),
  remplacer le décor réaliste/sombre, caméra plus haute/éloignée, personnages
  relativement plus grands, palette organisée (vert lumineux, orange chaud,
  beige clair, turquoise, ombres bleutées), UI illustrée (plus de bandeau
  sombre), lisibilité enfant.
- Interdits actés : aucun filtre/saturation/overlay pour « tricher » — le
  DÉCOR est remplacé par un nouvel asset généré conforme.
- Étapes : (1) référence = découpe de la maquette ; (2) génération
  1536×1024 mots-clés imposés + palette + composition compacte multi-lieux
  + portail magique ; (3) vérification visuelle vs référence ; (4) remap
  complet du monde (collisions, occlusion, spawns, FX, carte) ; (5) bandeau
  interface → bois/parchemin illustré ; (6) HERO_HEIGHT 96→106 (échelle
  relative) ; (7) capture comparée à la référence (critères d'acceptation
  de la demande).
- Risques : composition générée ≠ maquette → 2e génération possible ;
  remap = re-dérivation manuelle de toutes les coordonnées.
- Hors périmètre : gameplay, dialogues, quêtes.

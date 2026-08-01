# Fiche d'itération — décor diorama B2-clean (2026-07-30)

## Objectif utilisateur
Remplacer le décor `village-fractions-hd.png` (1536×1024) par
`village-diorama-B2-clean.png` (2528×1696), décor DA-diorama généré par
Nano Banana Pro et choisi par Camille (match A/B), en conservant tout le
gameplay. Clôt l'itération da-diorama suspendue (archivée).

## Expérience joueur attendue
Même boucle (déplacement, Lina, question, récompenses, panneaux) dans un
monde plus grand et fidèle à `ref-village-diorama.png` : encrage marqué,
verts profonds, eau turquoise saturée, lanternes chaudes, cercle magique.

## Scènes/systèmes concernés
`VillageScene` (monde, collisions, spawns, occlusion), `BootScene`
(chargement + découpes), `fx/environment` (effets localisés), `MapPanel`
(minimap).

## Changements fonctionnels
- Monde 2528×1696 (bornes caméra + physique).
- Remap complet des collisions (maisons, échoppe, appentis, clôtures,
  arbres, berges/eau, fontaine) sur la nouvelle composition.
- Remap des spawns héros / Lina / renard.
- Échelle du héros adaptée (portes ≈ 100 px dans le nouveau décor).

## Changements visuels
- Décor affiché en natif ×1, aucun étirement.
- Occlusion fontaine re-découpée depuis le nouveau décor.
- Rayon lumineux localisé recalé sur la nouvelle fontaine.
- Minimap du panneau Carte re-découpée depuis le nouveau décor.

## Assets nécessaires
- `public/art/generated/village-diorama-B2-clean.png` (existe, 2528×1696,
  vérifié visuellement : personnage parasite retiré, enseignes muettes).
- Aucune génération nouvelle.

## Risques
- Collisions estimées visuellement (décor peint) → capture d'analyse.
- Échelle héros vs portes → vérification sur capture.
- Caméra montrant trop de monde → personnages trop petits.

## Critères d'acceptation
- Build strict OK, aucune erreur console à la capture.
- Capture : décor B2-clean non déformé, non terni vs référence,
  personnages ancrés et à l'échelle, HUD/boutons intacts.
- Aucune régression : déplacement, dialogue, question, XP, inventaire, carte.

## Hors périmètre
- Planche de marche (étape 4), pont/combat (étape 6), autres assets.

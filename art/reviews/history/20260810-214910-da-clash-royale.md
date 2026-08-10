# Fiche d'itération — refonte DA de l'arène (« rivaliser avec Clash Royale »)

Demande Camille (2026-08-10) : « je veux que les décors rivalisent avec
un Clash Royale ». Identité « caverne de cristal » violette conservée,
caméra/UI/gameplay intouchés, zéro asset externe (tout en canvas 2D +
géométrie toon).

## Changements (public/spike3d-arena.html)

1. **Sol entièrement refait** : damier de grandes dalles violettes à
   fort contraste (clair 0x553c9a / sombre 0x1f1344, peints ~40 % plus
   sombres que la teinte voulue car la lumière de la scène surexpose
   ×1,8), biseaux cartoon, joints sombres, dalles accent bleu nuit à
   lueur cyan, dalles-runes (3 glyphes, rotations aléatoires), losanges
   d'or sertis (contour sombre + cœur clair), fissures gravées 2 passes
   (ombre + arête claire), mousse cristalline. Texture 2048 px (à 1024,
   la magnification rendait tout flou) + anisotropy 8.
2. **Hiérarchie de valeurs** : centre plus clair et chaud, vignette
   sombre marquée aux bords, bande d'occlusion au pied des remparts.
3. **Liseré doré incrusté** autour de la zone jouable (contour brun-or
   sombre + cœur clair) ; **médaillon runique central** affirmé (disque
   sombre + anneaux or opaques + 4 studs éclatants + anneau cyan).
4. **Remparts crénelés** beige sur les 4 côtés + **4 tours d'angle**
   (fût pierre, couronne, toit violet, pointe dorée émissive, drapeau
   cyan qui claque) + **12 torches** à flamme vacillante ET halo chaud
   au sol (pulse synchronisé) + **7 arbres-champignons** luminescents.
5. **Ombres portées réparées** : la shadow camera (±14) ne couvrait
   qu'une fraction de l'arène — élargie à tout le plateau (±46,
   map 2048) : chaque personnage est ancré au sol.
6. **Lumière** : ambiante 1,05 → 0,78, soleil 1,3 → 1,18 et plus chaud
   (0xfff2dc) — fini le rendu pastel délavé.

## Cycle de revue

Sous-agent DA senior (références Clash Royale/Brawl Stars) sur 2
captures → TOP 3 appliqué : ancrage lumière (ombres + AO + halos de
torche), hiérarchie de valeurs (gradient central + vignette ×2 +
contraste dalles), nettoyage micro-détails (fissures gravées, losanges
sertis, médaillon opaque, accent intégré au damier, netteté 2048).

## Vérifié

- 0 erreur console sur toutes les captures (desktop + téléphone).
- Damier net (plus de flou), médaillon lisible à la première seconde,
  ombres sous les personnages, halos de torche visibles au bord.

## À surveiller (téléphone réel)

- FPS avec texture 2048 + shadow map 2048 : si ça rame chez Camille,
  redescendre `sun.shadow.mapSize` à 1024 et la texture à 1024.
- Étincelles ✨ blanches : la revue les trouve « taches grises » — leur
  sort (réaffecter/retirer) est une décision gameplay en attente.

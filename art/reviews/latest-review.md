# Fiche d'itération — sol V2 « illustration peinte »

Retour Camille (2026-08-10) : « c'est mieux mais pas encore ça — même
en 2D tu devrais être capable de faire mieux en 2026. » Le damier
uniforme ne suffisait pas : le sol est désormais une VRAIE scène 2D
peinte, avec des lieux différenciés partout où la caméra passe.

## Le nouveau sol (public/spike3d-arena.html, makeGroundTexture V2)

1. **Pavés peints un à un** : quinconce irrégulier, 3 tons de violet +
   jitter, coins arrondis, arête claire / assise sombre par pavé — fini
   la grille mécanique.
2. **Chemins de grès chaud** : grand anneau en super-ellipse + 4
   connecteurs vers les bords, peints en 3 passes (creux sombre, corps
   sable, cœur clair) + galets épars — le contraste chaud/froid qui
   structure les arènes Clash Royale.
3. **Place centrale en mosaïque** : disque rayonnant à 16 secteurs,
   anneaux de pierre + anneau cyan, médaillon d'or à 8 studs sertis,
   spirale-dragon gravée au centre.
4. **2 bassins de cristal** : margelle de pierre, eau en dégradé
   turquoise profond → lumineux, reflets en arcs, étincelles-croix,
   cristaux de berge violets/cyan.
5. **6 massifs de mousse sauvage** : blobs organiques verts foncés
   (2 passes + cœur sombre pour le volume), touffes en arcs clairs,
   fleurs de cristal roses/dorées.
6. Conservés de la V1 : liseré doré incrusté, vignette + centre chaud,
   bande d'occlusion au pied des remparts, remparts/tours/torches/
   arbres-champignons, ombres portées plein plateau.

Toutes les couleurs restent peintes ~40 % plus sombres que la teinte
cible (l'éclairage de la scène multiplie l'albédo par ≈ 1,8).

## Vérifié (0 erreur console)

- Captures centre / bassin / mousse : chaque écran de jeu traverse au
  moins deux « matériaux » différents (pavés + chemin, mousse, bassin,
  place) — plus aucun plan monotone.
- Correction en cours de route : la mousse V1 rendait « nuage menthe »
  délavé → verts foncés, blobs plus petits, cœur sombre.

## À surveiller (téléphone réel)

- FPS : texture 2048 + shadow map 2048 (redescendre à 1024 si besoin).
- Les bassins/mousse sont purement visuels (aucune collision) — dire si
  ça prête à confusion en jeu.

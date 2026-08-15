#!/usr/bin/env python3
"""TERRAIN INITIAL D'ILLUMINIA — une île-clairière sculptée.

Fini le rectangle vert : un plateau organique aux bordures dessinées,
strates de terre et de falaise, chemin de sable qui invite vers le
centre, taches d'herbe, éboulis. La zone constructible (grille 12×12,
y = 0) reste parfaitement plate et lisible.
"""
import math
import sys

import numpy as np
from shapely.geometry import LineString, Polygon
from shapely.ops import unary_union

sys.path.insert(0, __file__.rsplit("/", 1)[0])
from artkit import (Asset, R, S, T, blob, contour_organique, extrusion,
                    rocher, trimesh, util)


def superellipse(a, n=3.4, points=72, graine=3, bruit=0.22):
    """Carré arrondi organique : couvre les coins de la grille sans
    devenir un disque géant."""
    rng = np.random.default_rng(graine)
    phases = rng.uniform(0, math.tau, size=3)
    pts = []
    for i in range(points):
        t = math.tau * i / points
        c, s = math.cos(t), math.sin(t)
        r = a * (abs(c) ** n + abs(s) ** n) ** (-1.0 / n)
        for f, ph in zip((3, 5, 8), phases):
            r += bruit * math.sin(f * t + ph) / f * a * 0.08
        pts.append((r * c, r * s))
    return Polygon(pts)


asset = Asset("terrain_ile", emprise=19.0, budget_tris=14000)

# ---------------------------------------------------------------- strates
ile = superellipse(7.55)
# herbe : nappe supérieure, top EXACTEMENT à y=0 (la grille de jeu).
herbe = extrusion(ile, 0.4)
R(herbe, (1, 0, 0), -math.pi / 2)
T(herbe, 0, -0.4, 0)         # dessus exactement à y = 0
asset.poser("grass", herbe)
# lisière d'herbe sombre : un liseré qui épaissit la silhouette du bord.
lisiere = extrusion(ile.buffer(0.06).difference(ile.buffer(-0.55)), 0.1)
R(lisiere, (1, 0, 0), -math.pi / 2)
T(lisiere, 0, -0.02, 0)
asset.poser("grass_dark", lisiere)
# terre : strate qui déborde légèrement (surplomb sculpté).
terre = extrusion(superellipse(7.75, graine=5, bruit=0.5), 0.62)
R(terre, (1, 0, 0), -math.pi / 2)
T(terre, 0, -0.92, 0)        # sous l'herbe, léger surplomb sculpté
asset.poser("dirt", terre)
# falaise : cône de roche évasé (enveloppe de deux contours).
haut_f = extrusion(superellipse(7.6, graine=8, bruit=0.6), 0.02)
bas_f = extrusion(superellipse(6.1, graine=11, bruit=0.8), 0.02)
T(bas_f, 0, 0, -1.9)
falaise = trimesh.convex.convex_hull(util.concatenate([haut_f, bas_f]))
R(falaise, (1, 0, 0), -math.pi / 2)
T(falaise, 0, -0.9, 0)
asset.poser("cliff", falaise)
# socle de roche sombre qui ferme le dessous.
socle = extrusion(superellipse(6.2, graine=11, bruit=0.8), 1.2)
R(socle, (1, 0, 0), -math.pi / 2)
T(socle, 0, -2.9, 0)
asset.poser("rock_dark", socle)

# --------------------------------------------- éboulis accrochés au bord
rng = np.random.default_rng(2026)
for i in range(10):
    a = rng.uniform(0, math.tau)
    r = 7.5 + rng.uniform(-0.25, 0.3)
    caillou = rocher(rng.uniform(0.3, 0.62), graine=100 + i, aplati=0.8)
    T(caillou, r * math.cos(a), rng.uniform(-1.15, -0.3), r * math.sin(a))
    asset.poser("rock", caillou)

# --------------------------------------------------- chemin de sable doré
trace = LineString([(1.1, 7.4), (1.3, 5.2), (0.4, 3.4), (0.5, 1.9), (0.2, 0.9)])
bande = trace.buffer(0.52, resolution=8)
chemin = extrusion(bande, 0.05)
R(chemin, (1, 0, 0), -math.pi / 2)
T(chemin, 0, 0.001, 0)
asset.poser("path_sand", chemin)
# pierres de gué le long du chemin (dalles arrondies plates).
for (px, pz, pr) in [(1.15, 6.6, 0.2), (1.28, 5.6, 0.16), (0.95, 4.4, 0.19),
                     (0.42, 3.0, 0.15), (0.52, 2.2, 0.18)]:
    dalle = blob(pr, graine=int(pz * 10), amplitude=0.18, sub=2, aplati=0.22)
    T(dalle, px, 0.05, pz)
    asset.poser("stone_mid", dalle)

# ------------------------------------------ taches d'herbe & terre battue
# Taches d'herbe : la MÊME famille de vert, à peine plus sombre —
# des nuances de prairie, jamais des ronds de couleurs aléatoires.
for i, (gx, gz, gr) in enumerate([
        (-3.6, -3.2, 1.6), (3.9, -2.6, 1.2), (-2.4, 3.8, 1.3),
        (-4.9, 0.8, 1.0), (1.2, -4.8, 1.1)]):
    tache = extrusion(contour_organique(gr, graine=40 + i, amplitude=0.5, points=22), 0.028)
    R(tache, (1, 0, 0), -math.pi / 2)
    T(tache, gx, 0.001, gz)
    asset.poser("grass_dark", tache)
# clairière de terre battue (le futur coin ferme, près du chemin).
clairiere = extrusion(contour_organique(1.35, graine=77, amplitude=0.5, points=24), 0.04)
R(clairiere, (1, 0, 0), -math.pi / 2)
T(clairiere, 3.4, 0.0005, 4.6)
asset.poser("dirt", clairiere)

asset.exporter("/workspace/iluminia/godot/assets/artkit/terrain/terrain_ile.glb",
               marge=2.2, pivot_sol=False)

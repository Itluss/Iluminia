#!/usr/bin/env python3
"""NORMALISATION — maillon entre un asset BRUT et le jeu.

Un modèle qui arrive d'un fournisseur externe (Meshy, une place de
marché, un artiste) ne respecte aucune de nos conventions : il est à
une échelle arbitraire, centré n'importe où, orienté n'importe comment.
Ce script le conforme AUX CONVENTIONS D'ILLUMINIA, sans jamais toucher
au jeu :

  1. ORIENTATION   — la façade regarde +Z (rotation par quarts de tour)
  2. ÉCHELLE       — uniforme, pour tenir dans son emprise (1 case = 1 u)
  3. PIVOT         — centre de l'emprise, posé AU SOL (y = 0)
  4. VALIDATION    — triangles, matériaux, dimensions, emprise

Usage :
  python3 normaliser.py entree.glb sortie.glb --emprise 3 --hauteur 4.2
                        [--rot 1] [--tris-max 20000]
"""
import argparse
import math
import os

import numpy as np
import trimesh


def _bornes(scene):
    b = scene.bounds
    return np.array(b[0], dtype=float), np.array(b[1], dtype=float)


def normaliser(entree, sortie, emprise=3.0, hauteur_max=None, quarts=0,
               marge=0.06, tris_max=20000):
    scene = trimesh.load(entree, force="scene")
    tris = sum(len(g.faces) for g in scene.geometry.values())
    mini, maxi = _bornes(scene)
    print("BRUT      %d triangles, %d matériaux, dims %.2f × %.2f × %.2f"
          % (tris, len(scene.geometry), *(maxi - mini)))

    # Tout aplatir en un seul maillage : les transformations de nœuds du
    # fournisseur ne survivent pas toujours à l'import Godot.
    parties = []
    for nom, geo in scene.geometry.items():
        m = geo.copy()
        for noeud in scene.graph.nodes_geometry:
            t, g = scene.graph[noeud]
            if g == nom:
                m.apply_transform(t)
                break
        parties.append((nom, m))

    def _appliquer(fn):
        for _, m in parties:
            fn(m)

    # 1 · ORIENTATION : quarts de tour autour de Y (façade vers +Z).
    if quarts:
        rot = trimesh.transformations.rotation_matrix(
            math.pi / 2 * quarts, (0, 1, 0))
        _appliquer(lambda m: m.apply_transform(rot))

    # 2 · ÉCHELLE UNIFORME : l'emprise au sol commande ; la hauteur peut
    # la contraindre davantage (un bâtiment ne doit pas crever le ciel).
    mini = np.min([m.bounds[0] for _, m in parties], axis=0)
    maxi = np.max([m.bounds[1] for _, m in parties], axis=0)
    dims = maxi - mini
    cible = emprise - 2 * marge
    facteur = min(cible / max(dims[0], 1e-6), cible / max(dims[2], 1e-6))
    if hauteur_max:
        facteur = min(facteur, hauteur_max / max(dims[1], 1e-6))
    _appliquer(lambda m: m.apply_scale(facteur))

    # 3 · PIVOT : centre de l'emprise, posé au sol.
    mini = np.min([m.bounds[0] for _, m in parties], axis=0)
    maxi = np.max([m.bounds[1] for _, m in parties], axis=0)
    centre = (mini + maxi) / 2.0
    decalage = np.array([-centre[0], -mini[1], -centre[2]])
    _appliquer(lambda m: m.apply_translation(decalage))

    propre = trimesh.Scene()
    for nom, m in parties:
        propre.add_geometry(m, node_name=nom, geom_name=nom)

    # 4 · VALIDATION
    mini, maxi = _bornes(propre)
    dims = maxi - mini
    print("NORMALISÉ %d triangles, échelle ×%.4f, dims %.2f × %.2f × %.2f"
          % (tris, facteur, *dims))
    alertes = []
    if tris > tris_max:
        alertes.append("BUDGET : %d triangles (max %d) — à décimer"
                       % (tris, tris_max))
    if abs(mini[1]) > 0.01:
        alertes.append("PIVOT : y_min = %.3f" % mini[1])
    demi = emprise / 2.0 + 0.01
    if maxi[0] > demi or -mini[0] > demi or maxi[2] > demi or -mini[2] > demi:
        alertes.append("EMPRISE dépassée")
    for a in alertes:
        print("  !! " + a)
    if not alertes:
        print("  OK  conventions Illuminia respectées")

    os.makedirs(os.path.dirname(sortie) or ".", exist_ok=True)
    propre.export(sortie)
    print("→ %s (%d Ko)" % (sortie, os.path.getsize(sortie) // 1024))
    return {"tris": tris, "facteur": facteur, "dims": dims.tolist(),
            "alertes": alertes}


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("entree")
    p.add_argument("sortie")
    p.add_argument("--emprise", type=float, default=3.0)
    p.add_argument("--hauteur", type=float, default=None)
    p.add_argument("--rot", type=int, default=0, help="quarts de tour Y")
    p.add_argument("--tris-max", type=int, default=20000)
    a = p.parse_args()
    normaliser(a.entree, a.sortie, a.emprise, a.hauteur, a.rot,
               tris_max=a.tris_max)

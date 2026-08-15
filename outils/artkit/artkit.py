"""ILLUMINIA ART KIT — la chaîne de production 3D partagée.

Tout asset du monde d'Illuminia passe par ici :
  SPÉCIFICATION → GÉNÉRATION (ces helpers) → NORMALISATION (conventions)
  → VALIDATION (budgets, emprise, pivot) → EXPORT .glb → IMPORT GODOT.

CONVENTIONS (identiques au moteur) : 1 case = 1 unité Godot, pivot au
centre de l'emprise AU SOL (y = 0), façade +Z, échelle uniforme.

DIRECTION ARTISTIQUE « JOUR ENCHANTÉ » : un monde chaleureux et lumineux
(verts lumineux, pierre claire, ciel bleu royal profond) où la MAGIE DE
LA CONNAISSANCE (cyan, or, violet) circule dans l'architecture. Formes
généreuses, silhouettes caricaturées, biseaux francs, zéro bruit visuel.
"""
import json
import math
import os

import numpy as np
import trimesh
from shapely.geometry import Point, Polygon
from shapely.geometry import box as sbox
from shapely.ops import unary_union
from trimesh import creation, transformations, util
from trimesh.visual.material import PBRMaterial
from trimesh.visual.texture import TextureVisuals

# ═══════════════════════════════════════════════ PALETTE (sRGB, nommée)
# La bibliothèque de MATÉRIAUX Illuminia : chaque asset choisit ici,
# jamais de couleur inventée localement.
PALETTE = {
    # pierre & bois
    "stone_light":  ((0.93, 0.88, 0.78), 0.9, None),
    "stone_mid":    ((0.78, 0.72, 0.62), 0.9, None),
    "stone_dark":   ((0.55, 0.50, 0.44), 0.9, None),
    "wood":         ((0.62, 0.44, 0.28), 0.85, None),
    "wood_dark":    ((0.42, 0.29, 0.18), 0.85, None),
    # toitures
    "roof_blue":    ((0.23, 0.35, 0.85), 0.7, None),
    "roof_blue_dk": ((0.13, 0.19, 0.55), 0.7, None),
    "roof_violet":  ((0.48, 0.33, 0.82), 0.7, None),
    # métaux & magie
    "gold":         ((0.98, 0.76, 0.26), 0.4, None),
    "gold_dark":    ((0.76, 0.54, 0.16), 0.5, None),
    "cyan_magic":   ((0.16, 0.6, 0.85), 0.6, (0.3, 0.85, 1.0)),
    "violet_magic": ((0.42, 0.3, 0.8), 0.6, (0.55, 0.4, 1.0)),
    "ember":        ((0.9, 0.62, 0.22), 0.6, (1.0, 0.66, 0.25)),
    "banner_violet": ((0.5, 0.34, 0.86), 0.8, None),
    # nature — verts LUMINEUX (jamais fluorescents : légèrement chauds)
    "grass":        ((0.42, 0.72, 0.34), 0.95, None),
    "grass_dark":   ((0.36, 0.64, 0.30), 0.95, None),
    "plant_green":  ((0.36, 0.66, 0.3), 0.95, None),
    "plant_dark":   ((0.22, 0.46, 0.24), 0.95, None),
    "leaf_warm":    ((0.62, 0.76, 0.3), 0.95, None),
    "flower_gold":  ((0.99, 0.8, 0.32), 0.8, None),
    "flower_cyan":  ((0.45, 0.85, 0.95), 0.8, None),
    "flower_pink":  ((0.93, 0.5, 0.72), 0.8, None),
    # sols
    "dirt":         ((0.56, 0.4, 0.27), 0.95, None),
    "dirt_dark":    ((0.4, 0.28, 0.19), 0.95, None),
    "path_sand":    ((0.87, 0.72, 0.48), 0.9, None),
    "rock":         ((0.52, 0.5, 0.58), 0.95, None),
    "rock_dark":    ((0.36, 0.34, 0.42), 0.95, None),
    "cliff":        ((0.62, 0.54, 0.5), 0.95, None),
    "water":        ((0.3, 0.75, 0.9), 0.3, (0.2, 0.6, 0.8)),
    "cream":        ((0.96, 0.92, 0.82), 0.9, None),
}


def lin(c):
    """Couleur pensée en sRGB → facteur glTF (espace linéaire)."""
    return [v ** 2.2 for v in c]


_MATERIAUX = {}


def materiau(nom):
    if nom not in _MATERIAUX:
        base, rough, emission = PALETTE[nom]
        m = PBRMaterial(baseColorFactor=[*lin(base), 1.0],
                        metallicFactor=0.0, roughnessFactor=rough)
        if emission is not None:
            m.emissiveFactor = lin(emission)
        m.name = nom
        _MATERIAUX[nom] = m
    return _MATERIAUX[nom]


# ═══════════════════════════════════════════════════════════ ASSEMBLAGE
class Asset:
    """Un asset en cours d'assemblage : des maillages groupés par
    matériau, exportés en un .glb (un nœud nommé par matériau)."""

    def __init__(self, nom, emprise=1.0, budget_tris=4000):
        self.nom = nom
        self.emprise = emprise          # côté logique en cases (x et z)
        self.budget = budget_tris
        self.groupes = {}

    def poser(self, nom_mat, mesh, noeud=None):
        """`noeud` nomme le nœud exporté (accroches d'animation : Roue,
        Cheminee, Fanion, Portail…) — sinon le nom du matériau."""
        self.groupes.setdefault((nom_mat, noeud), []).append(mesh)
        return mesh

    # ---- validation + export -------------------------------------
    def exporter(self, chemin, marge=0.18, flat=True, pivot_sol=True):
        scene = trimesh.Scene()
        total = 0
        for (nom_mat, noeud), morceaux in self.groupes.items():
            fusion = util.concatenate(morceaux)
            if flat:
                fusion.unmerge_vertices()
            fusion.visual = TextureVisuals(material=materiau(nom_mat))
            total += len(fusion.faces)
            nom_noeud = noeud if noeud else nom_mat
            scene.add_geometry(fusion, node_name=nom_noeud, geom_name=nom_noeud)
        # NORMALISATION/VALIDATION : pivot au sol, emprise, budget.
        b = scene.bounds
        rapport = {"nom": self.nom, "tris": total, "budget": self.budget,
                   "y_min": round(float(b[0][1]), 3),
                   "x": [round(float(b[0][0]), 2), round(float(b[1][0]), 2)],
                   "z": [round(float(b[0][2]), 2), round(float(b[1][2]), 2)],
                   "h": round(float(b[1][1]), 2)}
        demi = self.emprise / 2.0 + marge
        erreurs = []
        if total > self.budget:
            erreurs.append("BUDGET dépassé (%d > %d tris)" % (total, self.budget))
        if pivot_sol and abs(rapport["y_min"]) > 0.02:
            erreurs.append("PIVOT pas au sol (y_min=%.3f)" % rapport["y_min"])
        for axe in ("x", "z"):
            if rapport[axe][0] < -demi - 1e-6 or rapport[axe][1] > demi + 1e-6:
                erreurs.append("EMPRISE dépassée en %s %s (±%.2f)" % (axe, rapport[axe], demi))
        rapport["erreurs"] = erreurs
        os.makedirs(os.path.dirname(chemin), exist_ok=True)
        scene.export(chemin)
        etat = "OK " if not erreurs else "!! "
        print("%s%-28s %5d tris  h=%.2f  %s" % (etat, self.nom, total,
              rapport["h"], "; ".join(erreurs)))
        return rapport


# ═══════════════════════════════════════════ OPÉRATIONS DE MODELAGE
def T(mesh, x=0.0, y=0.0, z=0.0):
    mesh.apply_translation((x, y, z))
    return mesh


def R(mesh, axe, angle):
    mesh.apply_transform(transformations.rotation_matrix(angle, axe))
    return mesh


def S(mesh, x=1.0, y=1.0, z=1.0):
    mesh.apply_scale((x, y, z))
    return mesh


def boite(w, h, d):
    return creation.box(extents=(w, h, d))


def _rect_arrondi(w, d, rayon, resolution=5):
    return sbox(-w / 2, -d / 2, w / 2, d / 2).buffer(
        rayon, join_style=1, resolution=resolution).buffer(
        -0.0)  # normalise


def dalle_arrondie(w, h, d, rayon=0.08):
    """Plaque à coins verticaux arrondis (extrusion), posée sur y=0."""
    m = creation.extrude_polygon(_rect_arrondi(w - 2 * rayon, d - 2 * rayon, rayon), h)
    R(m, (1, 0, 0), -math.pi / 2)
    T(m, 0, 0, 0)
    # extrude le long de +Z puis bascule : l'épaisseur devient la hauteur.
    return m


def bloc_chanfrein(w, h, d, biseau=0.06, rayon=0.05):
    """Bloc aux arêtes biseautées (enveloppe convexe de deux plaques) :
    le « bevel » qui sépare un volume sculpté d'une boîte brute."""
    bas = creation.extrude_polygon(
        _rect_arrondi(w - 2 * rayon, d - 2 * rayon, rayon), 0.01)
    haut = creation.extrude_polygon(
        _rect_arrondi(w - 2 * rayon - 2 * biseau, d - 2 * rayon - 2 * biseau, rayon), 0.01)
    T(haut, 0, 0, h - 0.01)
    coque = trimesh.convex.convex_hull(util.concatenate([bas, haut]))
    R(coque, (1, 0, 0), -math.pi / 2)
    return coque


def prisme_chanfrein(w, h, d, biseau_haut=0.55, epaule=0.12):
    """Volume en tente aux pans biseautés (toits simples, caisses)."""
    bas = creation.extrude_polygon(_rect_arrondi(w - 0.08, d - 0.08, 0.04), 0.01)
    haut = creation.extrude_polygon(
        _rect_arrondi(max(w * (1 - biseau_haut), 0.08), max(d - 2 * epaule, 0.08), 0.04), 0.01)
    T(haut, 0, 0, h)
    coque = trimesh.convex.convex_hull(util.concatenate([bas, haut]))
    R(coque, (1, 0, 0), -math.pi / 2)
    return coque


def revolution(profil, sections=40):
    """Solide de révolution autour de Y : profil = [(rayon, hauteur)…].
    (trimesh révolutionne autour de Z : on rebascule en Y-up.)"""
    pts = np.array([[max(r, 1e-4), y] for (r, y) in profil], dtype=float)
    m = creation.revolve(pts, sections=sections)
    R(m, (1, 0, 0), -math.pi / 2)
    return m


def sphere(r, sub=3):
    return creation.icosphere(subdivisions=sub, radius=r)


def blob(r, graine=0, amplitude=0.22, frequence=1.6, sub=3, aplati=1.0):
    """Masse ORGANIQUE : icosphère déformée par un bruit doux — feuillages,
    rochers ronds, buissons. Jamais la sphère parfaite d'un prototype."""
    rng = np.random.default_rng(graine)
    m = creation.icosphere(subdivisions=sub, radius=r)
    v = m.vertices.copy()
    deplacement = np.zeros(len(v))
    for _ in range(4):
        k = rng.normal(size=3)
        k = k / np.linalg.norm(k) * frequence
        phase = rng.uniform(0, math.tau)
        deplacement += np.sin(v @ k / max(r, 1e-3) + phase)
    deplacement = deplacement / 4.0 * amplitude * r
    normales = v / np.linalg.norm(v, axis=1, keepdims=True)
    m.vertices = v + normales * deplacement[:, None]
    S(m, 1.0, aplati, 1.0)
    return m


def rocher(r, graine=0, aplati=0.72):
    """Rocher FACETTÉ : blob basse résolution → enveloppe convexe →
    grandes faces franches, silhouette trapue."""
    m = blob(r, graine=graine, amplitude=0.3, frequence=1.3, sub=2)
    m = trimesh.convex.convex_hull(m)
    S(m, 1.0, aplati, 1.0)
    rng = np.random.default_rng(graine + 7)
    R(m, (0, 1, 0), rng.uniform(0, math.tau))
    return m


def extrusion(poly, epaisseur):
    """Extrusion d'un polygone (XY, +Z) — accepte les MultiPolygons."""
    morceaux = list(poly.geoms) if hasattr(poly, "geoms") else [poly]
    return util.concatenate([creation.extrude_polygon(p, epaisseur) for p in morceaux])


def arche(l, h_droit, r):
    return unary_union([sbox(-l / 2, 0, l / 2, h_droit),
                        Point(0, h_droit).buffer(r, resolution=32)])


def etoile(branches, r_ext, r_int, phase=math.pi / 2):
    pts = []
    for i in range(branches * 2):
        a = phase + i * math.pi / branches
        rr = r_ext if i % 2 == 0 else r_int
        pts.append((rr * math.cos(a), rr * math.sin(a)))
    return Polygon(pts)


def contour_organique(demi, graine=0, amplitude=0.35, points=40):
    """Contour d'île : un cercle déformé par un bruit doux — la bordure
    « dessinée à la main » du terrain, jamais un rectangle."""
    rng = np.random.default_rng(graine)
    phases = rng.uniform(0, math.tau, size=4)
    freqs = [2, 3, 5, 7]
    pts = []
    for i in range(points):
        a = math.tau * i / points
        r = demi
        for f, ph in zip(freqs, phases):
            r += amplitude * demi * 0.25 * math.sin(f * a + ph) / f
        pts.append((r * math.cos(a), r * math.sin(a)))
    return Polygon(pts)


def profil_cloche(largeur, y_bas, apex, evase=0.62, avancee=0.14):
    """Polygone du toit signature : cloche à flancs concaves, gouttes
    évasées, rive épaisse."""
    L = largeur / 2.0
    haut = []
    n = 26
    for i in range(n + 1):
        t = i / n
        x = -L + L * t
        haut.append((x, y_bas + (apex - y_bas) * (1 - (1 - t) ** evase)))
    haut += [(-x, y) for (x, y) in reversed(haut[:-1])]
    return Polygon(haut + [(L + avancee, y_bas - 0.1), (L + avancee, y_bas - 0.2),
                           (-L - avancee, y_bas - 0.2), (-L - avancee, y_bas - 0.1)])


def toit_courbe(largeur, profondeur, y_bas, apex, evase=0.62, avancee=0.14):
    """LE toit signature, extrudé et centré sur Z."""
    m = extrusion(profil_cloche(largeur, y_bas, apex, evase, avancee), profondeur)
    T(m, 0, 0, -profondeur / 2.0)
    return m


# ═════════════════════════════════════════════════════════════ MANIFESTE
def ecrire_manifeste(chemin, entrees):
    """Statuts d'assets : PLACEHOLDER | PROTOTYPE | CANDIDATE | VALIDATED
    — jamais « premium » sans validation visuelle en contexte."""
    os.makedirs(os.path.dirname(chemin), exist_ok=True)
    with open(chemin, "w") as f:
        json.dump(entrees, f, indent=2, ensure_ascii=False)
    print("manifeste : %d assets → %s" % (len(entrees), chemin))

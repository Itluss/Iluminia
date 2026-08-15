#!/usr/bin/env python3
"""Génère maison_aventuriers.glb depuis la planche de référence.

Direction : toit bleu nuit courbe (flancs concaves évasés), grand
portail cyan lumineux, pierre claire, tour latérale à dôme bleu,
accents or, bannières violettes, étoile au pignon.
Conventions Illuminia : 1 case = 1 unité, emprise 3x3 (x,z dans
[-1.5, 1.5]), pivot au centre de l'emprise AU SOL (y = 0), façade +Z.
"""
import math
import trimesh
from trimesh.creation import box, cylinder, extrude_polygon, uv_sphere
from trimesh.visual.material import PBRMaterial
from trimesh.visual.texture import TextureVisuals
from shapely.geometry import Polygon, Point, box as sbox
from shapely.ops import unary_union

# ---------------------------------------------------------------- palette
PIERRE = (0.86, 0.82, 0.75)
PIERRE_SOMBRE = (0.6, 0.56, 0.5)
TOIT = (0.17, 0.25, 0.66)
TOIT_SOMBRE = (0.10, 0.13, 0.42)
OR = (0.95, 0.73, 0.25)
OR_SOMBRE = (0.7, 0.5, 0.15)
VIOLET = (0.45, 0.3, 0.82)
GROUPES = {}


def lin(c):
    """Couleurs pensées en sRGB → facteurs glTF (espace linéaire)."""
    return [v ** 2.2 for v in c]


def mat(couleur, emission=None, rough=0.85):
    m = PBRMaterial(baseColorFactor=[*lin(couleur), 1.0], metallicFactor=0.0,
                    roughnessFactor=rough)
    if emission is not None:
        m.emissiveFactor = lin(emission)
    return m


def ajouter(groupe, mesh):
    GROUPES.setdefault(groupe, []).append(mesh)


def rot(mesh, axe, angle):
    mesh.apply_transform(trimesh.transformations.rotation_matrix(angle, axe))
    return mesh


def b(groupe, taille, pos):
    m = box(extents=taille)
    m.apply_translation(pos)
    ajouter(groupe, m)
    return m


def cyl(groupe, r, h, pos, sections=48):
    m = cylinder(radius=r, height=h, sections=sections)
    rot(m, (1, 0, 0), math.pi / 2)   # axe Y
    m.apply_translation(pos)
    ajouter(groupe, m)
    return m


def sph(groupe, r, pos, echelle=(1, 1, 1)):
    m = uv_sphere(radius=r, count=(28, 28))
    m.apply_scale(echelle)
    m.apply_translation(pos)
    ajouter(groupe, m)
    return m


def extru(groupe, poly, epaisseur, pos, ay=0.0):
    morceaux = list(poly.geoms) if hasattr(poly, "geoms") else [poly]
    m = trimesh.util.concatenate(
        [extrude_polygon(mp, epaisseur) for mp in morceaux])
    if ay != 0.0:
        rot(m, (0, 1, 0), ay)
    m.apply_translation(pos)
    ajouter(groupe, m)
    return m


def arche(l, h_droit, r):
    """Contour porte en arche : rectangle + demi-cercle au sommet."""
    return unary_union([sbox(-l / 2, 0, l / 2, h_droit),
                        Point(0, h_droit).buffer(r, resolution=40)])


def etoile4(r_ext, r_int):
    pts = []
    for i in range(8):
        a = math.pi / 2 + i * math.pi / 4
        r = r_ext if i % 2 == 0 else r_int
        pts.append((r * math.cos(a), r * math.sin(a)))
    return Polygon(pts)


# ------------------------------------------------------------------ socle
b("PierreSombre", (3.05, 0.14, 2.85), (0, 0.07, 0))
b("Pierre", (2.85, 0.24, 2.65), (0, 0.26, 0))
for i, (lg, z) in enumerate([(1.7, 1.34), (1.5, 1.24)]):
    b("PierreSombre", (lg, 0.12 + i * 0.12, 0.24), (0, 0.06 + i * 0.06, z))

# ------------------------------------------------------- corps principal
b("Pierre", (2.2, 1.6, 1.9), (-0.3, 1.18, 0.0))
for x in (-1.34, 0.74):
    for z in (-0.89, 0.89):
        b("PierreSombre", (0.24, 1.62, 0.24), (x, 1.19, z))
b("OrDetail", (2.46, 0.1, 2.08), (-0.3, 2.0, 0.0))       # corniche

# ------------------------- grand toit bleu nuit : flancs CONCAVES évasés
L, Y0, APEX = 1.3, 1.95, 3.42
prof = []
for i in range(41):
    t = i / 40.0                       # 0 → 1 (bord gauche → faîte)
    x = -L + L * t
    prof.append((x, Y0 + (APEX - Y0) * (1 - (1 - t) ** 0.62)))
prof += [(-x, y) for (x, y) in reversed(prof[:-1])]        # symétrie
poly_toit = Polygon(prof + [(L, Y0 - 0.16), (-L, Y0 - 0.16)])
toit = extrude_polygon(poly_toit, 2.15)
toit.apply_translation((-0.3, 0, -1.05))
ajouter("Toit", toit)
# liseré sombre du bas de toiture (fin, pas une dalle)
b("ToitSombre", (2.76, 0.1, 2.25), (-0.3, Y0 - 0.2, 0.0))
# bande dorée qui suit la courbe du pignon avant
bande = poly_toit.difference(poly_toit.buffer(-0.12))
bande = bande.intersection(sbox(-L - 1, Y0 + 0.05, L + 1, APEX + 1))
extru("OrDetail", bande, 0.1, (-0.3, 0, 1.06))
# faîtière dorée + boule
faiti = cylinder(radius=0.06, height=2.3, sections=24)     # axe Z natif
faiti.apply_translation((-0.3, APEX + 0.02, 0.0))
ajouter("OrDetail", faiti)
sph("OrDetail", 0.11, (-0.3, APEX + 0.05, 1.12))

# --------------------------- emblème du pignon : anneau or + étoile cyan
cyl_e = cylinder(radius=0.42, height=0.12, sections=48)
cyl_e.apply_translation((-0.3, 2.62, 1.1))
ajouter("OrDetail", cyl_e)
cyl_e2 = cylinder(radius=0.34, height=0.13, sections=48)
cyl_e2.apply_translation((-0.3, 2.62, 1.11))
ajouter("Toit", cyl_e2)
e_or = extrude_polygon(etoile4(0.34, 0.13), 0.1)
e_or.apply_translation((-0.3, 2.62, 1.14))
ajouter("OrDetail", e_or)
e_cy = extrude_polygon(etoile4(0.2, 0.08), 0.08)
e_cy.apply_translation((-0.3, 2.62, 1.2))
ajouter("GemmeCyan", e_cy)

# ------------------------------------------- GRAND portail des étoiles
cadre = arche(1.32, 0.62, 0.64).difference(arche(0.98, 0.62, 0.49))
extru("OrDetail", cadre, 0.2, (-0.3, 0.38, 0.88))
extru("Portail", arche(0.98, 0.62, 0.49), 0.12, (-0.3, 0.38, 0.97))
b("PierreSombre", (1.6, 0.07, 0.46), (-0.3, 0.41, 1.14))  # seuil

# --------------------------------------------------- tour latérale + dôme
cyl("Pierre", 0.48, 3.2, (1.05, 1.6, -0.32), 48)
cyl("OrDetail", 0.56, 0.14, (1.05, 3.06, -0.32), 48)
cyl("Pierre", 0.52, 0.18, (1.05, 3.18, -0.32), 48)
cyl("PierreSombre", 0.54, 0.12, (1.05, 0.5, -0.32), 48)
dome = uv_sphere(radius=0.6, count=(32, 32))
dome.apply_scale((1.0, 0.85, 1.0))
dome.apply_translation((1.05, 3.3, -0.32))
ajouter("Toit", dome)
cyl("OrDetail", 0.055, 0.4, (1.05, 3.95, -0.32), 16)
sph("OrDetail", 0.1, (1.05, 4.16, -0.32))
# fenêtres arche lumineuses de la tour (faces avant et droite)
for (dx, dz, ay) in [(0.0, 0.42, 0.0), (0.42, 0.0, math.pi / 2)]:
    for yy in (1.45, 2.3):
        pf = extrude_polygon(arche(0.15, 0.4, 0.075), 0.12)
        cf = extrude_polygon(
            arche(0.23, 0.4, 0.115).difference(arche(0.15, 0.4, 0.075)), 0.1)
        for m_, grp in ((pf, "FenetresTour"), (cf, "PierreSombre")):
            rot(m_, (0, 1, 0), ay)
            m_.apply_translation((1.05 + dx, yy, -0.32 + dz))
            ajouter(grp, m_)

# --------------------------------------- fenêtres du corps (hublot + arc)
anneau = Point(0, 0).buffer(0.21, resolution=32).difference(
    Point(0, 0).buffer(0.14, resolution=32))
for m_, grp in ((extrude_polygon(anneau, 0.1), "PierreSombre"),
                (extrude_polygon(Point(0, 0).buffer(0.14, resolution=32), 0.08),
                 "FenetresTour")):
    rot(m_, (0, 1, 0), math.pi / 2)
    m_.apply_translation((0.86, 1.3, 0.35))
    ajouter(grp, m_)
extru("PierreSombre", arche(0.28, 0.34, 0.14).difference(arche(0.18, 0.34, 0.09)),
      0.1, (-1.02, 0.95, 0.9))
extru("FenetresTour", arche(0.18, 0.34, 0.09), 0.08, (-1.02, 0.95, 0.97))

# ------------------------------------------------- bannières violettes
def banniere(pos, ay=0.0):
    poly = Polygon([(-0.17, 0.0), (0.17, 0.0), (0.17, -0.78),
                    (0.0, -0.95), (-0.17, -0.78)])
    m = extrude_polygon(poly, 0.05)
    rot(m, (0, 1, 0), ay)
    m.apply_translation(pos)
    ajouter("Violet", m)
    e = extrude_polygon(etoile4(0.09, 0.036), 0.03)
    rot(e, (0, 1, 0), ay)
    decal = (0.0, -0.38, 0.055) if ay == 0.0 else (0.055, -0.38, 0.0)
    e.apply_translation((pos[0] + decal[0], pos[1] + decal[1], pos[2] + decal[2]))
    ajouter("OrDetail", e)
    t = box(extents=(0.42, 0.06, 0.06) if ay == 0.0 else (0.06, 0.06, 0.42))
    t.apply_translation((pos[0], pos[1] + 0.02, pos[2]))
    ajouter("OrSombre", t)


banniere((-1.15, 1.9, 0.98))
banniere((1.05, 2.6, 0.16))
# ---------------------------------------------------- lanternes du parvis
for x in (-1.02, 0.52):
    b("PierreSombre", (0.12, 0.4, 0.12), (x, 0.6, 1.16))
    sph("Lanternes", 0.09, (x, 0.86, 1.16), (1, 1.2, 1))
    sph("OrSombre", 0.06, (x, 1.0, 1.16), (1, 0.6, 1))

# --------------------------------------------------------- fanion sommet
fanion = extrude_polygon(Polygon([(0, 0), (0.32, 0.1), (0, 0.2)]), 0.03)
rot(fanion, (0, 1, 0), math.pi / 4)
fanion.apply_translation((1.05, 4.05, -0.32))
ajouter("Fanion", fanion)

# ------------------------------------------------------------- assemblage
MATS = {
    "Pierre": mat(PIERRE),
    "PierreSombre": mat(PIERRE_SOMBRE),
    "Toit": mat(TOIT, rough=0.7),
    "ToitSombre": mat(TOIT_SOMBRE),
    "OrDetail": mat(OR, rough=0.4),
    "OrSombre": mat(OR_SOMBRE, rough=0.5),
    "Violet": mat(VIOLET),
    "Portail": mat((0.1, 0.5, 0.78), emission=(0.25, 0.8, 1.0)),
    "FenetresTour": mat((0.1, 0.48, 0.72), emission=(0.2, 0.68, 0.86)),
    "GemmeCyan": mat((0.14, 0.55, 0.8), emission=(0.25, 0.8, 1.0)),
    "Lanternes": mat((0.85, 0.6, 0.2), emission=(0.95, 0.62, 0.2)),
    "Fanion": mat(OR, rough=0.4),
}
scene = trimesh.Scene()
total = 0
for nom, morceaux in GROUPES.items():
    fusion = trimesh.util.concatenate(morceaux)
    fusion.unmerge_vertices()          # facettes nettes (cartoon)
    fusion.visual = TextureVisuals(material=MATS[nom])
    total += len(fusion.faces)
    scene.add_geometry(fusion, node_name=nom, geom_name=nom)

sortie = "/workspace/iluminia/godot/assets/3d/buildings/maison_aventuriers/maison_aventuriers.glb"
import os
os.makedirs(os.path.dirname(sortie), exist_ok=True)
scene.export(sortie)
print("GLB écrit :", sortie, "| triangles :", total)

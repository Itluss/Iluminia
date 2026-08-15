#!/usr/bin/env python3
"""ARCHITECTURE D'ILLUMINIA — la première famille de bâtiments.

Un seul langage : pierre claire sculptée, toits en cloche bleu royal,
liserés d'or, magie de la connaissance en cyan. Mais CINQ silhouettes
distinctes — jamais « la même maison avec un autre toit ».

  HERO       maison_aventuriers  3×3  portail du savoir, tour à dôme
  HOUSING    maison_habitation   2×2  trapue, colombages, cheminée
  FOOD       potager             2×2  bacs surélevés, treillis, récolte
  PRODUCTION atelier             2×2  auvent, établi, engrenage doré
  PRODUCTION moulin              2×2  vertical, ailes qui tournent

Nœuds d'ANIMATION exportés (le moteur les retrouve par nom) :
  Portail, FenetresMagie, Fanion, Lanternes, Ailes, Engrenage, Fumee.
"""
import math
import sys

import numpy as np
from shapely.geometry import Point, Polygon
from shapely.geometry import box as sbox

sys.path.insert(0, __file__.rsplit("/", 1)[0])
from artkit import (Asset, R, S, T, arche, blob, bloc_chanfrein, boite,
                    creation, etoile, extrusion, prisme_chanfrein,
                    profil_cloche, revolution, rocher, sphere, toit_courbe,
                    trimesh, util)

RACINE = "/workspace/iluminia/godot/assets/artkit/architecture/"


# ══════════════════════════════════════════ pièces d'architecture communes
def socle_taille(a, w, d, h=0.34, mat="stone_mid"):
    """Le socle POSÉ : deux strates biseautées — rien ne flotte."""
    a.poser("stone_dark", T(bloc_chanfrein(w + 0.16, h * 0.45, d + 0.16, 0.05), 0, 0, 0))
    a.poser(mat, T(bloc_chanfrein(w, h, d, 0.07), 0, h * 0.42, 0))


def marches(a, largeur, z, y=0.0, n=2, mat="stone_mid"):
    for i in range(n):
        a.poser(mat, T(bloc_chanfrein(largeur - i * 0.18, 0.13, 0.3, 0.03),
                       0, y + i * 0.12, z - i * 0.16))


def fenetre_arche(a, l, h, r, pos, ay=0.0, mat_cadre="stone_dark",
                  mat_vitre="cyan_magic", noeud="FenetresMagie", ep=0.1):
    """Fenêtre EN RETRAIT : cadre creusé + vitrail lumineux au fond."""
    cadre = arche(l + 0.14, h, r + 0.07).difference(arche(l, h, r))
    m = extrusion(cadre, ep)
    R(m, (0, 1, 0), ay)
    T(m, *pos)
    a.poser(mat_cadre, m)
    v = extrusion(arche(l, h, r), ep * 0.55)
    R(v, (0, 1, 0), ay)
    T(v, pos[0] + math.sin(ay) * 0.02, pos[1], pos[2] - 0.02 * math.cos(ay))
    a.poser(mat_vitre, v, noeud)


def banniere(a, pos, ay=0.0, l=0.3, h=0.66):
    poly = Polygon([(-l / 2, 0), (l / 2, 0), (l / 2, -h),
                    (0, -h - 0.14), (-l / 2, -h)])
    m = extrusion(poly, 0.045)
    R(m, (0, 1, 0), ay)
    T(m, *pos)
    a.poser("banner_violet", m)
    e = extrusion(etoile(4, l * 0.28, l * 0.1), 0.03)
    R(e, (0, 1, 0), ay)
    dz = 0.05 if abs(ay) < 0.1 else 0.0
    dx = 0.05 if abs(ay) > 0.1 else 0.0
    T(e, pos[0] + dx, pos[1] - h * 0.5, pos[2] + dz)
    a.poser("gold", e)
    tringle = creation.cylinder(radius=0.028, height=l * 1.35, sections=10)
    R(tringle, (0, 1, 0), math.pi / 2 + ay)
    T(tringle, pos[0], pos[1] + 0.02, pos[2])
    a.poser("gold_dark", tringle)


def lanterne(a, x, z, hauteur=0.5, socle=True):
    if socle:
        a.poser("stone_dark", T(bloc_chanfrein(0.16, 0.1, 0.16, 0.02), x, 0, z))
    mat_pied = creation.cylinder(radius=0.038, height=hauteur, sections=10)
    R(mat_pied, (1, 0, 0), math.pi / 2)
    T(mat_pied, x, hauteur / 2 + 0.08, z)
    a.poser("gold_dark", mat_pied)
    cage = revolution([(0.0, 0.0), (0.085, 0.03), (0.105, 0.1),
                       (0.085, 0.19), (0.03, 0.23), (0.0, 0.25)], sections=12)
    T(cage, x, hauteur + 0.06, z)
    a.poser("gold", cage)
    a.poser("ember", T(sphere(0.062, sub=1), x, hauteur + 0.15, z), "Lanternes")


def cheminee(a, x, z, h=0.8, l=0.24):
    a.poser("stone_dark", T(bloc_chanfrein(l, h, l, 0.03), x, 0, z))
    a.poser("stone_mid", T(bloc_chanfrein(l + 0.08, 0.1, l + 0.08, 0.02), x, h - 0.04, z))
    # repère de fumée (invisible : minuscule, sous le conduit)
    a.poser("cream", T(sphere(0.012, sub=0), x, h + 0.12, z), "Fumee")


def toiture(a, largeur, profondeur, y_bas, apex, mat="roof_blue",
            mat_rive="roof_blue_dk", or_liseré=True, evase=0.62):
    """Toit cloche + rive épaisse + liseré d'or qui suit la courbe."""
    a.poser(mat, toit_courbe(largeur, profondeur, y_bas, apex, evase))
    rive = toit_courbe(largeur + 0.1, profondeur + 0.12, y_bas - 0.16, y_bas + 0.02, 1.0, 0.16)
    a.poser(mat_rive, rive)
    if or_liseré:
        prof = profil_cloche(largeur, y_bas, apex, evase, 0.14)
        bande = prof.difference(prof.buffer(-0.075)).intersection(
            sbox(-largeur, y_bas + 0.04, largeur, apex + 1))
        for z in (profondeur / 2 - 0.03, -profondeur / 2 - 0.05):
            m = extrusion(bande, 0.08)
            T(m, 0, 0, z)
            a.poser("gold", m)


# ═══════════════════════════════════════ 1 · MAISON DES AVENTURIERS (HERO)
def maison_aventuriers():
    a = Asset("maison_aventuriers", emprise=3.0, budget_tris=11000)
    socle_taille(a, 2.72, 2.46, 0.36)
    marches(a, 1.34, 1.36, 0.0, 2)
    # corps : bloc chanfreiné + pilastres d'angle + corniche d'or
    a.poser("stone_light", T(bloc_chanfrein(2.24, 1.55, 1.98, 0.09), -0.28, 0.3, 0))
    for x in (-1.32, 0.76):
        for z in (-0.9, 0.9):
            a.poser("stone_mid", T(bloc_chanfrein(0.22, 1.6, 0.22, 0.03), x, 0.3, z))
    a.poser("gold", T(bloc_chanfrein(2.44, 0.1, 2.14, 0.03), -0.28, 1.82, 0))
    # TOUR : fût, anneau d'or, dôme en révolution, flèche, fanion
    fut = revolution([(0.0, 0.0), (0.5, 0.0), (0.47, 1.2), (0.45, 2.6), (0.0, 2.6)], 28)
    T(fut, 1.06, 0.22, -0.3)
    a.poser("stone_light", fut)
    anneau = revolution([(0.0, 0.0), (0.56, 0.0), (0.58, 0.1), (0.5, 0.16), (0.0, 0.16)], 28)
    T(anneau, 1.06, 2.7, -0.3)
    a.poser("gold", anneau)
    dome = revolution([(0.0, 0.0), (0.54, 0.02), (0.56, 0.22), (0.44, 0.5),
                       (0.22, 0.66), (0.0, 0.72)], 28)
    T(dome, 1.06, 2.84, -0.3)
    a.poser("roof_blue", dome)
    fleche = creation.cylinder(radius=0.04, height=0.42, sections=10)
    R(fleche, (1, 0, 0), math.pi / 2)
    T(fleche, 1.06, 3.72, -0.3)
    a.poser("gold", fleche)
    a.poser("gold", T(sphere(0.085, sub=1), 1.06, 3.96, -0.3))
    fanion = extrusion(Polygon([(0, 0), (0.3, 0.08), (0, 0.17)]), 0.028)
    R(fanion, (0, 1, 0), math.pi / 4)
    T(fanion, 1.06, 3.82, -0.3)
    a.poser("gold", fanion, "Fanion")
    for (dx, dz, ay) in [(0.0, 0.44, 0.0), (0.44, 0.0, math.pi / 2)]:
        for yy in (1.05, 1.95):
            fenetre_arche(a, 0.16, 0.34, 0.08, (1.06 + dx, yy, -0.3 + dz), ay, ep=0.08)
    # GRAND TOIT
    toiture(a, 2.68, 2.12, 1.86, 3.32)
    faitiere = creation.cylinder(radius=0.055, height=2.2, sections=12)
    T(faitiere, -0.28, 3.3, 0)
    a.poser("gold", faitiere)
    # médaillon-étoile du pignon (anneau d'or, disque bleu, étoile cyan)
    med_or = creation.cylinder(radius=0.42, height=0.1, sections=32)
    T(med_or, -0.28, 2.5, 1.02)
    a.poser("gold", med_or)
    med_bl = creation.cylinder(radius=0.33, height=0.12, sections=32)
    T(med_bl, -0.28, 2.5, 1.04)
    a.poser("roof_blue_dk", med_bl)
    et_or = extrusion(etoile(4, 0.32, 0.12), 0.08)
    T(et_or, -0.28, 2.5, 1.08)
    a.poser("gold", et_or)
    et_cy = extrusion(etoile(4, 0.18, 0.07), 0.06)
    T(et_cy, -0.28, 2.5, 1.13)
    a.poser("cyan_magic", et_cy, "FenetresMagie")
    # PORTAIL DU SAVOIR : arche d'or en retrait + fond cyan étoilé
    cadre = arche(1.3, 0.62, 0.64).difference(arche(0.96, 0.62, 0.48))
    a.poser("gold", T(extrusion(cadre, 0.2), -0.28, 0.34, 0.86))
    p = extrusion(arche(0.96, 0.62, 0.48), 0.1)
    T(p, -0.28, 0.34, 0.96)
    a.poser("cyan_magic", p, "Portail")
    for (sx, sy, sr) in [(-0.42, 0.72, 0.035), (-0.1, 0.95, 0.028), (-0.34, 1.12, 0.024)]:
        a.poser("cream", T(sphere(sr, sub=1), sx, sy, 1.02), "Portail")
    a.poser("stone_dark", T(bloc_chanfrein(1.5, 0.06, 0.4, 0.02), -0.28, 0.36, 1.1))
    # fenêtres de façade + bannières + lanternes
    fenetre_arche(a, 0.2, 0.36, 0.1, (-1.0, 0.95, 0.94))
    banniere(a, (-1.14, 1.72, 0.99))
    banniere(a, (1.06, 2.42, 0.16), math.pi / 2, 0.26, 0.58)
    lanterne(a, -0.98, 1.2, 0.46)
    lanterne(a, 0.42, 1.2, 0.46)
    return a.exporter(RACINE + "maison_aventuriers.glb")


# ═════════════════════════════════════════ 2 · MAISON D'HABITATION (HOUSING)
def maison_habitation():
    a = Asset("maison_habitation", emprise=2.0, budget_tris=6000)
    socle_taille(a, 1.72, 1.6, 0.26)
    a.poser("cream", T(bloc_chanfrein(1.5, 1.1, 1.36, 0.07), 0, 0.22, 0))
    # colombages : montants + traverse (bois, en relief)
    for x in (-0.58, 0.58):
        a.poser("wood_dark", T(bloc_chanfrein(0.11, 1.12, 0.09, 0.02), x, 0.22, 0.68))
    a.poser("wood_dark", T(bloc_chanfrein(1.5, 0.1, 0.09, 0.02), 0, 0.94, 0.68))
    a.poser("wood_dark", T(bloc_chanfrein(0.09, 1.12, 1.36, 0.02), -0.74, 0.22, 0))
    # toit cloche plus modeste, sans liseré d'or (la maison est humble)
    toiture(a, 1.86, 1.5, 1.3, 2.24, "roof_blue", "roof_blue_dk", False, 0.7)
    # lucarne : petit prisme + fenêtre lumineuse (variation de surface)
    a.poser("cream", T(bloc_chanfrein(0.42, 0.34, 0.4, 0.04), -0.18, 1.62, 0.5))
    luc = prisme_chanfrein(0.54, 0.26, 0.52, 0.7, 0.1)
    T(luc, -0.18, 1.94, 0.5)
    a.poser("roof_blue_dk", luc)
    fenetre_arche(a, 0.14, 0.14, 0.07, (-0.18, 1.72, 0.71), 0.0, "wood_dark", ep=0.07)
    # porte de bois en arche, en retrait
    cadre = arche(0.56, 0.36, 0.28).difference(arche(0.42, 0.36, 0.21))
    m = extrusion(cadre, 0.12)
    T(m, 0.18, 0.2, 0.62)
    a.poser("stone_mid", m)
    porte = extrusion(arche(0.42, 0.36, 0.21), 0.07)
    T(porte, 0.18, 0.2, 0.66)
    a.poser("wood", porte)
    a.poser("gold", T(sphere(0.032, sub=1), 0.3, 0.42, 0.72))
    fenetre_arche(a, 0.17, 0.24, 0.085, (-0.42, 0.6, 0.7))
    fenetre_arche(a, 0.17, 0.24, 0.085, (0.76, 0.62, 0.0), math.pi / 2)
    cheminee(a, 0.52, -0.42, 1.95, 0.22)
    marches(a, 0.6, 0.86, 0.0, 1)
    return a.exporter(RACINE + "maison_habitation.glb")


# ═══════════════════════════════════════════════════ 3 · POTAGER (FOOD)
def potager():
    a = Asset("potager", emprise=2.0, budget_tris=6500)
    rng = np.random.default_rng(11)
    # terre retournée + bordure de pierres (volume bas, généreux)
    a.poser("dirt_dark", T(bloc_chanfrein(1.86, 0.14, 1.7, 0.09), 0, 0, 0))
    for i in range(7):
        ang = math.tau * i / 7
        p = rocher(0.1 + rng.random() * 0.05, graine=i, aplati=0.7)
        T(p, math.cos(ang) * 0.92, 0.1, math.sin(ang) * 0.84)
        a.poser("stone_mid", p)
    # trois bacs de bois surélevés, plants en blobs (jamais des sphères)
    for r_i, zz in enumerate((-0.5, 0.06, 0.62)):
        a.poser("wood", T(bloc_chanfrein(1.5, 0.2, 0.34, 0.03), 0, 0.12, zz))
        a.poser("dirt", T(bloc_chanfrein(1.36, 0.06, 0.24, 0.02), 0, 0.3, zz))
        for c in range(4):
            x = -0.52 + c * 0.35
            feuille = blob(0.15, graine=r_i * 10 + c, amplitude=0.42, sub=1, aplati=0.78)
            T(feuille, x, 0.4, zz)
            a.poser("plant_green" if (c + r_i) % 2 else "leaf_warm", feuille)
            if (c + r_i) % 3 == 0:      # quelques fruits mûrs = récolte
                a.poser("flower_gold", T(sphere(0.05, sub=0), x + 0.05, 0.47, zz + 0.06))
    # treillis + plante grimpante (verticalité, lecture immédiate)
    for x in (-0.86, 0.86):
        a.poser("wood_dark", T(bloc_chanfrein(0.07, 1.05, 0.07, 0.02), x, 0.14, -0.82))
    for y in (0.75, 1.0, 1.18):
        a.poser("wood_dark", T(bloc_chanfrein(1.8, 0.05, 0.05, 0.01), 0, y, -0.82))
    for i in range(7):
        f = blob(0.14, graine=50 + i, amplitude=0.5, sub=1, aplati=0.7)
        T(f, -0.8 + i * 0.27, 0.82 + (i % 3) * 0.16, -0.8)
        a.poser("plant_dark" if i % 2 else "plant_green", f)
    # seau et arrosoir (activité humaine)
    seau = revolution([(0.0, 0.0), (0.11, 0.0), (0.13, 0.2), (0.0, 0.2)], 14)
    T(seau, 0.72, 0.14, 0.78)
    a.poser("wood_dark", seau)
    a.poser("water", T(creation.cylinder(radius=0.115, height=0.02, sections=14), 0.72, 0.32, 0.78))
    return a.exporter(RACINE + "potager.glb")


# ══════════════════════════════════════════════ 4 · ATELIER (PRODUCTION)
def atelier():
    a = Asset("atelier", emprise=2.0, budget_tris=7000)
    socle_taille(a, 1.78, 1.66, 0.24, "stone_dark")
    a.poser("stone_light", T(bloc_chanfrein(1.5, 0.95, 1.3, 0.07), -0.1, 0.2, -0.1))
    a.poser("wood", T(bloc_chanfrein(1.56, 0.12, 1.36, 0.03), -0.1, 1.1, -0.1))
    # toit à faible pente, décalé : silhouette large et trapue
    toit = prisme_chanfrein(1.84, 0.6, 1.6, 0.42, 0.2)
    T(toit, -0.1, 1.18, -0.1)
    a.poser("roof_violet", toit)
    a.poser("gold_dark", T(bloc_chanfrein(1.9, 0.07, 0.1, 0.02), -0.1, 1.14, 0.68))
    # AUVENT sur poteaux : l'atelier est OUVERT, on voit le travail
    a.poser("wood", T(bloc_chanfrein(1.7, 0.08, 0.62, 0.03), -0.05, 0.96, 0.72))
    for x in (-0.78, 0.68):
        a.poser("wood_dark", T(bloc_chanfrein(0.09, 0.96, 0.09, 0.02), x, 0.14, 0.96))
    # établi + outils + caisses (fonction lisible d'un coup d'œil)
    a.poser("wood_dark", T(bloc_chanfrein(0.9, 0.42, 0.36, 0.03), -0.16, 0.14, 0.7))
    a.poser("wood", T(bloc_chanfrein(1.0, 0.08, 0.44, 0.02), -0.16, 0.54, 0.7))
    for (cx, cz, s) in [(0.62, 0.42, 0.3), (0.66, 0.02, 0.24)]:
        caisse = bloc_chanfrein(s, s * 0.85, s, 0.03)
        T(caisse, cx, 0.14, cz)
        a.poser("wood", caisse)
        a.poser("gold_dark", T(bloc_chanfrein(s + 0.02, 0.03, s + 0.02, 0.01),
                               cx, 0.14 + s * 0.55, cz))
    # ENGRENAGE doré (nœud animé) : dents extrudées, moyeu, axe
    dents = etoile(9, 0.3, 0.2)
    eng = extrusion(dents, 0.09)
    T(eng, -0.62, 0.78, 0.78)
    a.poser("gold", eng, "Engrenage")
    a.poser("gold_dark", T(creation.cylinder(radius=0.09, height=0.14, sections=14),
                           -0.62, 0.78, 0.78))
    cheminee(a, 0.44, -0.6, 1.55, 0.24)
    fenetre_arche(a, 0.18, 0.3, 0.09, (-0.72, 0.5, 0.52), 0.0, "wood_dark")
    return a.exporter(RACINE + "atelier.glb")


# ═══════════════════════════════════════════════ 5 · MOULIN (PRODUCTION)
def moulin():
    a = Asset("moulin", emprise=2.0, budget_tris=7000)
    socle_taille(a, 1.6, 1.6, 0.28)
    # fût conique en révolution : la VERTICALITÉ du groupe production
    fut = revolution([(0.0, 0.0), (0.66, 0.0), (0.62, 0.5), (0.52, 1.35),
                      (0.46, 2.05), (0.0, 2.05)], 26)
    T(fut, 0, 0.24, 0)
    a.poser("stone_light", fut)
    # bandeau de pierre + porte en arche + fenêtres
    bandeau = revolution([(0.0, 0.0), (0.6, 0.0), (0.6, 0.12), (0.0, 0.12)], 26)
    T(bandeau, 0, 0.78, 0)
    a.poser("stone_mid", bandeau)
    porte = extrusion(arche(0.4, 0.3, 0.2), 0.1)
    T(porte, 0, 0.26, 0.58)
    a.poser("wood", porte)
    fenetre_arche(a, 0.15, 0.2, 0.075, (0.0, 1.2, 0.52))
    fenetre_arche(a, 0.15, 0.2, 0.075, (0.46, 1.5, 0.0), math.pi / 2)
    # toit conique bleu + épi
    chapeau = revolution([(0.0, 0.0), (0.6, 0.0), (0.56, 0.14), (0.3, 0.6),
                          (0.0, 0.82)], 26)
    T(chapeau, 0, 2.24, 0)
    a.poser("roof_blue", chapeau)
    a.poser("gold", T(sphere(0.08, sub=1), 0, 3.1, 0))
    # AILES (nœud animé) : moyeu + 4 pales à voile, plan XY, axe en +Z
    ailes = []
    moyeu = creation.cylinder(radius=0.11, height=0.16, sections=14)
    ailes.append(moyeu)
    for i in range(4):
        pale = extrusion(Polygon([(0.05, -0.06), (0.98, -0.15), (1.02, 0.15), (0.05, 0.06)]), 0.05)
        R(pale, (0, 0, 1), math.tau * i / 4)
        ailes.append(pale)
    ailes_m = util.concatenate(ailes)
    T(ailes_m, 0, 1.62, 0.62)
    a.poser("wood", ailes_m, "Ailes")
    for i in range(4):
        voile = extrusion(Polygon([(0.3, -0.11), (0.92, -0.16), (0.94, 0.05), (0.32, 0.03)]), 0.03)
        R(voile, (0, 0, 1), math.tau * i / 4 + 0.02)
        T(voile, 0, 1.62, 0.68)
        a.poser("cream", voile, "Ailes")
    return a.exporter(RACINE + "moulin.glb")


if __name__ == "__main__":
    for f in (maison_aventuriers, maison_habitation, potager, atelier, moulin):
        f()

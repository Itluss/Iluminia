#!/usr/bin/env python3
"""FOURNISSEUR D'ASSETS 3D — Meshy.

Maillon « GÉNÉRATION » de la chaîne de production Illuminia :

  SPÉCIFICATION → [ CE FICHIER ] → NORMALISATION → VALIDATION
  → IMPORT GODOT → MATÉRIAUX → ANIMATION → PLACEMENT → CAPTURE

Le fournisseur est REMPLAÇABLE : un autre service (Tripo, Rodin) n'a
qu'à exposer `generer(spec) -> chemin du .glb` pour prendre sa place ;
rien d'autre dans le pipeline ne change.

La clé d'API n'est JAMAIS écrite dans le dépôt : elle vient de la
variable d'environnement MESHY_API_KEY, alimentée par le secret GitHub
au moment de l'exécution du workflow.

Usage :
  MESHY_API_KEY=... python3 meshy.py --nom maison_aventuriers \\
      --prompt "..." [--image reference.png] [--sans-texture]
"""
import argparse
import base64
import json
import mimetypes
import os
import sys
import time
import urllib.error
import urllib.request

API = "https://api.meshy.ai/openapi"
SORTIE = "godot/assets/artkit/genere/"

# Style maison d'Illuminia — ajouté à CHAQUE description pour que tous
# les assets sortent du même monde (la cohérence prime sur la variété).
# Volontairement COURT : l'API plafonne la description à 800 caractères,
# et le budget doit rester au sujet, pas au style.
STYLE = ("stylized mobile game building, Clash of Clans quality, chunky "
         "exaggerated proportions, bold readable silhouette, hand-painted "
         "look, vibrant colors, no photorealism, single centered object")

LIMITE_PROMPT = 800


def _decrire(sujet):
    """Sujet + style, borné à la limite de l'API (le style est préservé,
    c'est le sujet qui est tronqué proprement)."""
    marge = LIMITE_PROMPT - len(STYLE) - 2
    return sujet.strip()[:marge].strip().rstrip(",") + ", " + STYLE


def _requete(chemin, methode="GET", corps=None, cle=""):
    url = API + chemin
    donnees = json.dumps(corps).encode() if corps is not None else None
    req = urllib.request.Request(url, data=donnees, method=methode)
    req.add_header("Authorization", "Bearer " + cle)
    req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            return json.loads(r.read().decode())
    except urllib.error.HTTPError as e:
        detail = e.read().decode()[:500]
        if e.code == 401:
            raise SystemExit("ÉCHEC AUTH (401) : la clé MESHY_API_KEY est "
                             "absente ou invalide.\n" + detail)
        if e.code in (402, 429):
            raise SystemExit("ÉCHEC CRÉDITS/QUOTA (%d) : %s" % (e.code, detail))
        raise SystemExit("ÉCHEC API Meshy (%d) sur %s :\n%s" % (e.code, chemin, detail))


def _attendre(chemin_tache, cle, libelle, max_s=1500):
    """Sonde la tâche jusqu'à SUCCEEDED (les générations prennent des
    minutes) en journalisant la progression."""
    debut = time.time()
    dernier = -1
    while time.time() - debut < max_s:
        t = _requete(chemin_tache, cle=cle)
        statut = t.get("status", "?")
        avance = int(t.get("progress", 0))
        if avance != dernier:
            print("  %-10s %3d%%  (%ds)" % (libelle, avance, time.time() - debut),
                  flush=True)
            dernier = avance
        if statut == "SUCCEEDED":
            return t
        if statut in ("FAILED", "CANCELED", "EXPIRED"):
            raise SystemExit("Tâche %s : %s — %s"
                             % (libelle, statut, t.get("task_error", {})))
        time.sleep(10)
    raise SystemExit("Délai dépassé sur %s (%d s)" % (libelle, max_s))


def _data_uri(chemin):
    type_mime = mimetypes.guess_type(chemin)[0] or "image/png"
    with open(chemin, "rb") as f:
        return "data:%s;base64,%s" % (type_mime, base64.b64encode(f.read()).decode())


def generer(nom, prompt, image=None, texturer=True, cle=None):
    """Produit un .glb et retourne son chemin. IMAGE-to-3D si une
    référence visuelle est fournie (fidélité à la planche), sinon
    TEXT-to-3D."""
    cle = cle or os.environ.get("MESHY_API_KEY", "")
    if not cle:
        raise SystemExit("MESHY_API_KEY absente de l'environnement.")

    if image:
        print("Image-to-3D depuis %s" % image, flush=True)
        rep = _requete("/v1/image-to-3d", "POST", {
            "image_url": _data_uri(image),
            "enable_pbr": False,
            "should_remesh": True,
            "should_texture": texturer,
            "topology": "triangle",
            "target_polycount": 12000,
        }, cle)
        tache = rep["result"] if isinstance(rep.get("result"), str) else rep.get("id")
        fini = _attendre("/v1/image-to-3d/" + tache, cle, "image-3D")
    else:
        description = _decrire(prompt)
        print("Text-to-3D (aperçu) — %d caractères" % len(description), flush=True)
        # « realistic » est le seul style accepté par l'API : la
        # stylisation vient donc entièrement de la description.
        rep = _requete("/v2/text-to-3d", "POST", {
            "mode": "preview",
            "prompt": description,
            "art_style": "realistic",
            "should_remesh": True,
            "topology": "triangle",
            "target_polycount": 12000,
        }, cle)
        tache = rep["result"] if isinstance(rep.get("result"), str) else rep.get("id")
        fini = _attendre("/v2/text-to-3d/" + tache, cle, "aperçu")
        if texturer:
            print("Text-to-3D (texturage)", flush=True)
            rep2 = _requete("/v2/text-to-3d", "POST", {
                "mode": "refine",
                "preview_task_id": tache,
                "enable_pbr": False,
            }, cle)
            tache2 = rep2["result"] if isinstance(rep2.get("result"), str) else rep2.get("id")
            fini = _attendre("/v2/text-to-3d/" + tache2, cle, "texture")

    lien = (fini.get("model_urls") or {}).get("glb")
    if not lien:
        raise SystemExit("Aucun .glb dans la réponse :\n"
                         + json.dumps(fini, indent=2)[:800])
    os.makedirs(SORTIE, exist_ok=True)
    chemin = os.path.join(SORTIE, nom + ".glb")
    with urllib.request.urlopen(lien, timeout=300) as r, open(chemin, "wb") as f:
        f.write(r.read())
    print("→ %s (%d Ko)" % (chemin, os.path.getsize(chemin) // 1024), flush=True)
    return chemin


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--nom", required=True)
    p.add_argument("--prompt", default="")
    p.add_argument("--image", default="")
    p.add_argument("--sans-texture", action="store_true")
    a = p.parse_args()
    if not a.prompt and not a.image:
        sys.exit("Fournir --prompt et/ou --image")
    generer(a.nom, a.prompt, a.image or None, not a.sans_texture)

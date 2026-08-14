class_name Identite
extends RefCounted
## SOURCE DE VÉRITÉ du style « Fantasy Pop » d'Iluminia — la nuit lumineuse.
##
## Alignée sur le design system existant du projet :
##   - public/ui/theme.css (tokens du HUD web)
##   - public/ui/style-guide-fantasypop.png (planche ILLUMINIA validée)
## Principes de la planche : univers coloré et lisible, formes rondes et
## joufflues, contours marine épais façon BD, accents néon sur fond nuit,
## finition « studio mobile premium ».
##
## COMMENT FAIRE ÉVOLUER LE STYLE : modifier les tokens ICI (et seulement
## ici) — toute l'interface (ui.gd), l'arène, le menu et les personnages
## (fiches de personnage3d.gd) les consomment. Un nouveau personnage =
## une nouvelle fiche ; une nouvelle ambiance = retoucher ambiance.gd.

# ---- Surfaces (nuit) ----
const NUIT := Color("0e1638")           ## fond profond
const PANNEAU := Color("17234a")        ## panneaux (MARINE PROFOND de la planche)
const PANNEAU_CLAIR := Color("24407c")  ## surbrillance de panneau
const CONTOUR := Color("0a1230")        ## contour marine épais (BD)

# ---- Accents ----
const BLEU := Color("258cff")
const BLEU_SOMBRE := Color("1660c2")
const CYAN := Color("20cff3")
const VIOLET := Color("8a55f5")
const VIOLET_SOMBRE := Color("6a34d6")
const MAGENTA := Color("ef4e9b")
const OR := Color("ffc928")
const OR_SOMBRE := Color("e0a000")
const ORANGE := Color("ff9418")
const CREME := Color("fff3d5")
const VERT := Color("53cc55")
const VERT_SOMBRE := Color("379e3a")
const ROUGE := Color("f04455")

# ---- Texte ----
const TEXTE := Color.WHITE
const TEXTE_ATTENUE := Color("c3d0ef")

# ---- Formes (planche : arrondi généreux, gros bords) ----
const RAYON_SM := 10
const RAYON_MD := 16
const RAYON_LG := 22
const BORD := 3
const BORD_FORT := 4

# ---- Réponses et zones (liées : même couleur au panneau et au sol) ----
const COULEURS_REPONSES := [VERT, BLEU, OR, MAGENTA]

# ---- Raretés (badges de la planche : COMMUN vert, RARE bleu, ÉPIQUE violet) ----
const RARETES := {
	"Commun": VERT, "Rare": BLEU, "Épique": VIOLET, "Légendaire": OR, "Mythique": MAGENTA,
}

# ---- Équipes / personnages (fiches complètes dans personnage3d.gd) ----
const TEINTE_MAX := BLEU
const TEINTE_ZEP := VIOLET
const TEINTE_NOVA := CYAN
const TEINTE_FICELLE := MAGENTA

# ---- Monde (île flottante bioluminescente) ----
const PELOUSE_NUIT := Color(0.13, 0.36, 0.31)   ## herbe sombre-turquoise
const PELOUSE_ANNEAU := Color(0.16, 0.45, 0.40) ## anneaux de tonte
const ROCHE := Color(0.19, 0.15, 0.34)          ## falaise et rochers flottants
const LUEUR_LISIERE := CYAN                     ## anneau lumineux du bord

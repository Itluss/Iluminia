class_name AdaptateurRendu
extends RefCounted
## ADAPTATEUR MÉTIER → RENDU 3D (pur, testé sans le jeu complet).
## La vue 3D ne lit JAMAIS l'état métier directement : cet adaptateur
## traduit les données de la ville (Profil.ville) en instructions de
## rendu neutres. La 3D est une COUCHE DE RENDU, pas une couche métier.
##
## CONVENTIONS 3D D'ILLUMINIA (tous les bâtiments les respectent) :
##   - 1 case logique = 1 unité Godot ;
##   - l'origine du monde est le CENTRE du terrain : la case (0, 0) est
##     au coin (-TAILLE/2, 0, -TAILLE/2) ; x logique → +X, y logique → +Z ;
##   - le pivot d'un bâtiment est le CENTRE de son emprise, AU SOL (y=0) ;
##   - la rotation logique `rot` (0-3) = quarts de tour autour de Y ;
##   - chaque bâtiment est une scène indépendante et remplaçable
##     (FabriqueBatiments) — le débord visuel (toit) peut dépasser
##     l'emprise, l'ancrage logique jamais.

## Caméra 3/4 isométrique légère, stable, pensée mobile paysage :
## orthographique (aucune déformation dramatique, lecture immédiate),
## panoramique borné, AUCUNE rotation libre.
const CAMERA := {
	"decalage": Vector3(9.0, 11.0, 9.0),
	"taille_ortho": 9.2,
	"borne_pan": 4.0,
}


## Centre de l'emprise d'un bâtiment, au sol, en unités monde.
static func position_monde(x: int, y: int, taille: int) -> Vector3:
	var demi := Cite.TAILLE_GRILLE / 2.0
	return Vector3(float(x) + taille / 2.0 - demi, 0.0, float(y) + taille / 2.0 - demi)


static func rotation_monde(rot: int) -> float:
	return float(rot) * PI / 2.0


## Un point du plan du sol → la case logique qu'il recouvre.
static func case_depuis_sol(point: Vector3) -> Vector2i:
	var demi := Cite.TAILLE_GRILLE / 2.0
	return Vector2i(int(floor(point.x + demi)), int(floor(point.z + demi)))


## L'état métier posé → une instruction de rendu par bâtiment :
## {type, niveau, taille, position, rotation_y}. Aucune décision de
## gameplay ici — uniquement de la traduction géométrique.
static func instructions(ville_posee: Array) -> Array:
	var sortie: Array = []
	for b in ville_posee:
		var taille := int(Cite.BATIMENTS.get(str(b.type), {}).get("taille", 2))
		sortie.append({
			"type": str(b.type),
			"niveau": int(b.get("niveau", 1)),
			"taille": taille,
			"position": position_monde(int(b.x), int(b.y), taille),
			"rotation_y": rotation_monde(int(b.get("rot", 0))),
		})
	return sortie

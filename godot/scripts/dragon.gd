class_name Dragon
extends Node2D
## Le bébé dragon de l'arène. Libre, il FUIT le chasseur le plus proche
## (trottinement à 5,5 u, panique à 2,6 u — toujours plus lent que les
## chasseurs) avec un biais vers le centre pour ne pas se coincer au bord.
## Porté, il se blottit dans les bras du porteur (pose « dans les bras »).
## Valeurs du spike Three.js, 1 u = 60 px (docs/mecaniques-arene.md).

const RAYON_CONTACT := 66.0   ## « l'attraper = marcher dessus » (1,1 u)
const DETECTION := 330.0      ## 5,5 u : commence à trottiner à l'opposé
const PANIQUE := 156.0        ## 2,6 u : fuite paniquée, petits bonds
const VITESSE_CALME := 120.0  ## 2,0 u/s
const VITESSE_FUITE := 156.0  ## 2,6 u/s

var arene: Arene
var porteur: Chasseur = null
var visuel: VisuelCartoon


func _ready() -> void:
	visuel = VisuelCartoon.new()
	visuel.genre = "dragon"
	visuel.rayon = 15.0
	visuel.couleur = Color(0.45, 0.82, 0.55)
	add_child(visuel)
	# Emplacement prévu pour un vrai sprite (voir assets/README.md).
	var sprite := Sprite2D.new()
	sprite.name = "Sprite2D"
	add_child(sprite)


func libre() -> bool:
	return porteur == null


func _process(delta: float) -> void:
	if porteur != null:
		# Dans les bras du porteur, légèrement devant lui.
		position = porteur.position + porteur.regard() * 26.0 + Vector2(0.0, -8.0)
		visuel.regard = porteur.regard()
		visuel.en_marche = false
		return

	var proche := arene.chasseur_le_plus_proche(position)
	if proche == null:
		visuel.en_marche = false
		return
	var d := position.distance_to(proche.position)
	if d < DETECTION:
		var fuite := (position - proche.position).normalized()
		# Biais vers le centre, d'autant plus fort qu'on approche du bord.
		var poids_centre := position.length() / Arene.RAYON_ARENE
		var dir := (fuite + (-position.normalized()) * poids_centre * 0.9).normalized()
		var v := VITESSE_FUITE if d < PANIQUE else VITESSE_CALME
		position += dir * v * delta
		visuel.regard = dir
		visuel.en_marche = true
		# Poussière de panique.
		if d < PANIQUE and randf() < 6.0 * delta:
			arene.fx.eclat_etoiles(position + Vector2(0.0, 10.0), Color(0.75, 0.68, 0.55), 3)
	else:
		visuel.en_marche = false
	position = arene.borner(position)

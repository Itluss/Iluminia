class_name Dragon
extends Node3D
## Le bébé dragon de l'arène. Libre, il FUIT le chasseur le plus proche
## (trottinement à 5,5 u, panique à 2,6 u — toujours plus lent que les
## chasseurs) avec un biais vers le centre pour ne pas se coincer au bord.
## Porté, il se blottit dans les bras du porteur. Valeurs du spike Three.js
## (docs/mecaniques-arene.md), unités identiques (1 u = 1 m).

const RAYON_CONTACT := 1.1   ## « l'attraper = marcher dessus »
const DETECTION := 5.5       ## commence à trottiner à l'opposé
const PANIQUE := 2.6         ## fuite paniquée, petits bonds
const VITESSE_CALME := 2.0
const VITESSE_FUITE := 2.6   ## toujours plus lent que bots (3,2) et joueur (4,4)

var arene: Arene
var porteur: Chasseur = null
var visuel: Personnage3D


func _ready() -> void:
	visuel = Personnage3D.new()
	visuel.genre = "dragon"
	visuel.couleur = Color(0.45, 0.82, 0.55)
	add_child(visuel)


func pos2() -> Vector2:
	return Vector2(position.x, position.z)


func fixer_pos2(v: Vector2) -> void:
	position = Vector3(v.x, position.y, v.y)


func libre() -> bool:
	return porteur == null


func _process(delta: float) -> void:
	if porteur != null:
		# Dans les bras du porteur, légèrement devant lui, soulevé.
		var devant := porteur.pos2() + porteur.regard() * 0.55
		position = Vector3(devant.x, 0.55, devant.y)
		visuel.regarder(porteur.regard())
		visuel.en_marche = false
		return
	position.y = 0.0

	var proche := arene.chasseur_le_plus_proche(pos2())
	if proche == null:
		visuel.en_marche = false
		return
	var d := pos2().distance_to(proche.pos2())
	if d < DETECTION:
		var fuite := (pos2() - proche.pos2()).normalized()
		# Biais vers le centre, d'autant plus fort qu'on approche du bord.
		var poids_centre := pos2().length() / Arene.RAYON_ARENE
		var dir := (fuite + (-pos2().normalized()) * poids_centre * 0.9).normalized()
		var v := VITESSE_FUITE if d < PANIQUE else VITESSE_CALME
		fixer_pos2(arene.borner(pos2() + dir * v * delta))
		visuel.regarder(dir)
		visuel.en_marche = true
		# Poussière de panique.
		if d < PANIQUE and randf() < 6.0 * delta:
			arene.fx.eclat_etoiles(pos2(), Color(0.75, 0.68, 0.55), 3)
	else:
		visuel.en_marche = false

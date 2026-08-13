class_name ObjetLoot
extends Node2D
## Butin au sol : arme ou armure, cinq raretés (multiplicateurs ×1/×2/×3,5/×6/×12),
## valeur croissante avec la zone. Ramassage automatique au contact ;
## le joueur équipe l'objet s'il est meilleur, sinon il le recycle en XP.

const RARETES := ["Commun", "Rare", "Épique", "Légendaire", "Mythique"]
const MULTIPLICATEURS := [1.0, 2.0, 3.5, 6.0, 12.0]
const POIDS := [55.0, 25.0, 12.0, 6.0, 2.0] ## probabilités de tirage (%)
const COULEURS := [
	Color(0.85, 0.85, 0.85), # Commun — gris clair
	Color(0.35, 0.62, 1.0),  # Rare — bleu
	Color(0.72, 0.40, 1.0),  # Épique — violet
	Color(1.0, 0.62, 0.15),  # Légendaire — orange
	Color(1.0, 0.30, 0.50),  # Mythique — rose incandescent
]
const NOMS_ARMES := ["Dague", "Épée", "Hache", "Lame", "Espadon"]
const NOMS_ARMURES := ["Tunique", "Cotte", "Plastron", "Cuirasse", "Égide"]
const SUFFIXES_ZONE := ["de la Clairière", "de la Forêt", "du Marais", "des Terres Brûlées"]
## Valeur de base par zone (multipliée ensuite par la rareté).
const BASE_ARME := [4.0, 7.0, 11.0, 16.0]
const BASE_ARMURE := [2.0, 4.0, 7.0, 11.0]

var monde: Monde
var objet := {}
var duree_vie := 60.0
var _t := 0.0


## Tire un objet aléatoire adapté à la zone. rarete_min force une rareté
## plancher (ex. le butin du boss est Légendaire ou Mythique).
static func generer(zone: int, rarete_min := 0) -> Dictionary:
	var emplacement := "arme" if randf() < 0.5 else "armure"
	var rarete := rarete_min
	var tirage := randf() * 100.0
	var cumul := 0.0
	for i in POIDS.size():
		cumul += POIDS[i]
		if tirage <= cumul:
			rarete = maxi(i, rarete_min)
			break
	var bases: Array = BASE_ARME if emplacement == "arme" else BASE_ARMURE
	var valeur := roundf(bases[zone - 1] * MULTIPLICATEURS[rarete] * randf_range(0.9, 1.15))
	var noms: Array = NOMS_ARMES if emplacement == "arme" else NOMS_ARMURES
	var nom := "%s %s %s (+%d %s)" % [
		noms[rarete], RARETES[rarete].to_lower(), SUFFIXES_ZONE[zone - 1],
		int(valeur), "ATQ" if emplacement == "arme" else "DÉF",
	]
	return {"emplacement": emplacement, "rarete": rarete, "valeur": valeur, "nom": nom}


func _process(delta: float) -> void:
	_t += delta
	duree_vie -= delta
	queue_redraw()
	if duree_vie <= 0.0:
		queue_free()
		return
	# Clignote avant de disparaître.
	if duree_vie < 5.0:
		modulate.a = 0.4 + absf(sin(_t * 8.0)) * 0.6
	var j := monde.joueur
	if j.vivant and position.distance_to(j.position) < 36.0:
		j.recevoir_objet(objet)
		monde.fx.eclat_etoiles(position, COULEURS[int(objet.rarete)], 8)
		queue_free()


func _draw() -> void:
	var teinte: Color = COULEURS[int(objet.rarete)]
	var flottement := sin(_t * 3.0) * 3.0
	var p := Vector2(0.0, -flottement)
	# Halo de rareté.
	draw_circle(p, 20.0 + sin(_t * 4.0) * 2.0, Color(teinte.r, teinte.g, teinte.b, 0.18))
	if objet.emplacement == "arme":
		# Petite épée stylisée : lame en losange + garde.
		draw_colored_polygon(PackedVector2Array([
			p + Vector2(0.0, -14.0), p + Vector2(5.0, 0.0), p + Vector2(0.0, 10.0), p + Vector2(-5.0, 0.0),
		]), Color(0.13, 0.10, 0.16))
		draw_colored_polygon(PackedVector2Array([
			p + Vector2(0.0, -11.0), p + Vector2(3.0, 0.0), p + Vector2(0.0, 7.0), p + Vector2(-3.0, 0.0),
		]), teinte)
		draw_line(p + Vector2(-6.0, 2.0), p + Vector2(6.0, 2.0), Color(0.13, 0.10, 0.16), 3.0)
	else:
		# Petit bouclier stylisé.
		draw_colored_polygon(PackedVector2Array([
			p + Vector2(-8.0, -8.0), p + Vector2(8.0, -8.0), p + Vector2(8.0, 2.0),
			p + Vector2(0.0, 10.0), p + Vector2(-8.0, 2.0),
		]), Color(0.13, 0.10, 0.16))
		draw_colored_polygon(PackedVector2Array([
			p + Vector2(-6.0, -6.0), p + Vector2(6.0, -6.0), p + Vector2(6.0, 1.0),
			p + Vector2(0.0, 7.0), p + Vector2(-6.0, 1.0),
		]), teinte)

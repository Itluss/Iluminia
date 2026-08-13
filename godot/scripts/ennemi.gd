class_name Ennemi
extends Node2D
## Ennemi générique : six types configurés dans TYPES (mêlée ou tir),
## IA en trois états — repos → poursuite (aggro à 260 px) → retour au point
## d'origine avec régénération (désaggro au-delà de 700 px).

enum Etat { REPOS, POURSUITE, RETOUR }

const DIST_AGGRO := 260.0
const DIST_DESAGGRO := 700.0

const TYPES := {
	"sanglier": {"zone": 1, "pv": 30.0, "atk": 6.0, "vitesse": 100.0, "xp": 12.0, "rayon": 14.0, "couleur": Color(0.62, 0.42, 0.28), "tir": false},
	"loup": {"zone": 2, "pv": 55.0, "atk": 10.0, "vitesse": 145.0, "xp": 22.0, "rayon": 15.0, "couleur": Color(0.55, 0.57, 0.62), "tir": false},
	"araignee": {"zone": 2, "pv": 45.0, "atk": 12.0, "vitesse": 85.0, "xp": 26.0, "rayon": 13.0, "couleur": Color(0.38, 0.28, 0.45), "tir": true},
	"zombie": {"zone": 3, "pv": 110.0, "atk": 18.0, "vitesse": 62.0, "xp": 45.0, "rayon": 15.0, "couleur": Color(0.45, 0.62, 0.38), "tir": false},
	"scorpion": {"zone": 3, "pv": 85.0, "atk": 22.0, "vitesse": 95.0, "xp": 52.0, "rayon": 14.0, "couleur": Color(0.78, 0.55, 0.25), "tir": true},
	"ogre": {"zone": 4, "pv": 260.0, "atk": 34.0, "vitesse": 78.0, "xp": 120.0, "rayon": 24.0, "couleur": Color(0.52, 0.55, 0.35), "tir": false},
	"dragon": {"zone": 4, "pv": 1200.0, "atk": 45.0, "vitesse": 85.0, "xp": 600.0, "rayon": 40.0, "couleur": Color(0.78, 0.22, 0.18), "tir": false},
}

var monde: Monde
var type_nom := "sanglier"
var origine := Vector2.ZERO ## point de garde (retour après désaggro)
var pv_max := 30.0
var pv := 30.0
var atk := 6.0
var vitesse := 100.0
var xp_donnee := 12.0
var tireur := false
var etat := Etat.REPOS
var cd_coup := 0.0
var cd_tir := 0.0
var visuel: VisuelCartoon


## À appeler AVANT l'ajout à l'arbre : fixe le type et le poste de garde.
func configurer(nom: String, pos: Vector2) -> void:
	type_nom = nom
	var t: Dictionary = TYPES[nom]
	pv_max = t.pv
	pv = t.pv
	atk = t.atk
	vitesse = t.vitesse
	xp_donnee = t.xp
	tireur = t.tir
	position = pos
	origine = pos


func _ready() -> void:
	var t: Dictionary = TYPES[type_nom]
	visuel = VisuelCartoon.new()
	visuel.genre = type_nom
	visuel.rayon = t.rayon
	visuel.couleur = t.couleur
	add_child(visuel)
	# Emplacement prévu pour un vrai sprite (voir assets/README.md).
	var sprite := Sprite2D.new()
	sprite.name = "Sprite2D"
	add_child(sprite)


func _process(delta: float) -> void:
	cd_coup = maxf(cd_coup - delta, 0.0)
	cd_tir = maxf(cd_tir - delta, 0.0)
	var j := monde.joueur
	var d := position.distance_to(j.position)

	match etat:
		Etat.REPOS:
			visuel.en_marche = false
			if j.vivant and d < DIST_AGGRO:
				etat = Etat.POURSUITE
		Etat.POURSUITE:
			if not j.vivant or d > DIST_DESAGGRO:
				etat = Etat.RETOUR
			else:
				_poursuivre(delta, j, d)
		Etat.RETOUR:
			# On rentre au poste en se régénérant, sourd aux provocations.
			visuel.en_marche = true
			pv = minf(pv + pv_max * 0.6 * delta, pv_max)
			var vers := origine - position
			if vers.length() < 8.0:
				etat = Etat.REPOS
				pv = pv_max
			else:
				position += vers.normalized() * vitesse * 1.2 * delta
				visuel.regard = vers.normalized()


func _poursuivre(delta: float, j: Joueur, d: float) -> void:
	var dir := (j.position - position).normalized()
	visuel.regard = dir
	# Les tireurs gardent leurs distances, les cogneurs vont au contact.
	var portee_arret := 200.0 if tireur else (visuel.rayon + 20.0)
	visuel.en_marche = d > portee_arret
	if d > portee_arret:
		position += dir * vitesse * delta
	if tireur:
		if d < 320.0 and cd_tir <= 0.0:
			cd_tir = 1.7
			visuel.squash(0.15)
			monde.creer_projectile(position, dir * 240.0, atk,
				Color(0.85, 0.4, 0.85) if type_nom == "araignee" else Color(0.95, 0.7, 0.2))
	else:
		if d < visuel.rayon + 34.0 and cd_coup <= 0.0:
			cd_coup = 1.1
			visuel.squash(0.2)
			j.subir_degats(atk * randf_range(0.9, 1.1))


func subir_degats(deg: float) -> void:
	if pv <= 0.0:
		return
	pv -= deg
	etat = Etat.POURSUITE # se faire frapper réveille n'importe qui
	visuel.flash()
	visuel.squash(0.22)
	monde.fx.texte_flottant(position + Vector2(0.0, -visuel.rayon - 14.0),
		str(int(round(deg))), Color(1.0, 0.95, 0.6))
	monde.fx.eclat_etoiles(position, Color(1.0, 0.85, 0.4), 5)
	Audio.jouer("impact")
	if pv <= 0.0:
		mourir()


func mourir() -> void:
	monde.sur_mort_ennemi(self)
	queue_free()

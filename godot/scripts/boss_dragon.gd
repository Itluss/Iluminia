class_name BossDragon
extends Ennemi
## Le dragon des Terres Brûlées : 1200 PV. À 50 % de vie il entre en rage —
## vitesse ×1,5 et salves circulaires de 8 projectiles toutes les 2,2 s.
## Hors rage, il crache une boule de feu isolée de temps en temps.
## Une boussole à l'écran (hud.gd) pointe vers lui en permanence.

const AGGRO_BOSS := 420.0
const DESAGGRO_BOSS := 1000.0
const PERIODE_SALVE := 2.2
const NB_PROJECTILES_SALVE := 8

var enrage := false
var cd_salve := 0.0


func _process(delta: float) -> void:
	cd_coup = maxf(cd_coup - delta, 0.0)
	cd_tir = maxf(cd_tir - delta, 0.0)
	cd_salve = maxf(cd_salve - delta, 0.0)
	var j := monde.joueur
	var d := position.distance_to(j.position)

	match etat:
		Etat.REPOS:
			visuel.en_marche = false
			if j.vivant and d < AGGRO_BOSS:
				etat = Etat.POURSUITE
				monde.hud.message("Le dragon vous a repéré…", 2.0)
				Audio.jouer("rage")
		Etat.POURSUITE:
			if not j.vivant or d > DESAGGRO_BOSS:
				etat = Etat.RETOUR
			else:
				_poursuivre(delta, j, d)
				# Boule de feu isolée hors rage, salve circulaire en rage.
				if enrage:
					if cd_salve <= 0.0:
						cd_salve = PERIODE_SALVE
						_salve()
				elif cd_tir <= 0.0 and d < 420.0:
					cd_tir = 2.6
					visuel.squash(0.15)
					monde.creer_projectile(position, (j.position - position).normalized() * 230.0,
						atk * 0.8, Color(1.0, 0.5, 0.15))
		Etat.RETOUR:
			visuel.en_marche = true
			pv = minf(pv + pv_max * 0.6 * delta, pv_max)
			var vers := origine - position
			if vers.length() < 8.0:
				etat = Etat.REPOS
				pv = pv_max
			else:
				position += vers.normalized() * vitesse * 1.2 * delta
				visuel.regard = vers.normalized()


func subir_degats(deg: float) -> void:
	super.subir_degats(deg)
	if not enrage and pv > 0.0 and pv <= pv_max * 0.5:
		enrage = true
		vitesse *= 1.5
		monde.fx.texte_flottant(position + Vector2(0.0, -70.0), "Le dragon entre en RAGE !", Color(1.0, 0.3, 0.2))
		monde.fx.secousse(0.8)
		monde.hud.message("Le dragon entre en rage !", 2.5)
		Audio.jouer("rage")


## Salve enragée : anneau de 8 boules de feu dans toutes les directions.
func _salve() -> void:
	visuel.squash(0.25)
	Audio.jouer("souffle")
	for i in NB_PROJECTILES_SALVE:
		var dir := Vector2.from_angle(TAU * i / NB_PROJECTILES_SALVE)
		monde.creer_projectile(position, dir * 210.0, atk * 0.6, Color(1.0, 0.45, 0.1))


func mourir() -> void:
	monde.sur_mort_boss(self)
	queue_free()

class_name Simulation
extends RefCounted
## LE MOTEUR DE SIMULATION DE VILLE V1 — la couche économique, SÉPARÉE
## de l'interface : l'UI (et le futur rendu 3D) LISENT l'état, ils ne
## recalculent jamais l'économie.
##
## Boucle V1 : construire → produire → accueillir des habitants →
## créer des besoins → les satisfaire → faire grandir la ville.
## « Si j'ajoute des habitants, je dois aussi produire davantage de
## nourriture. » Ressources : PIÈCES + NOURRITURE (+ la population).
## La connaissance ne fait pas partie de la simulation : elle DÉBLOQUE.
##
## PAS DE PUNITION : une pénurie arrête la croissance, elle ne fait ni
## mourir les habitants, ni disparaître les bâtiments, ni perdre des
## pièces. Le manque crée une motivation, jamais de la culpabilité.
##
## Fonctions PURES (testables sans le profil) ; `appliquer()` est le
## seul point qui écrit dans Profil — et les pièces produites passent
## par Profil.crediter_pieces (source CITY_PRODUCTION), la même source
## de vérité que les récompenses d'apprentissage.

## LA CONFIG D'ÉQUILIBRAGE — toutes les valeurs de simulation vivent
## ICI (provisoires : l'équilibrage se fera sans toucher à la logique).
const EQUILIBRAGE := {
	"population": {
		"conso_nourriture_min": 0.1,     ## nourriture consommée / habitant / minute
		"intervalle_croissance_min": 3.0, ## +1 habitant toutes les N minutes
		"reserve_min_croissance": 2.0,    ## réserve de nourriture exigée pour grandir
	},
	"nourriture": {
		"seuil_equilibre": 0.1,          ## |taux net| sous ce seuil → ÉQUILIBRE
	},
	"simulation": {
		"tick_s": 2.0,                   ## cadence du tick (le calcul utilise le
	},                                   ## temps RÉELLEMENT écoulé, jamais un pas fixe)
}


# ------------------------------------------------------ fonctions pures

## Production de nourriture par minute (somme des bâtiments posés).
static func production_nourriture_min(ville_posee: Array) -> float:
	var total := 0.0
	for b in ville_posee:
		total += float(Cite.BATIMENTS.get(str(b.type), {}).get("production", {}).get("nourriture_min", 0.0))
	return total


## Production de pièces par minute.
static func production_or_min(ville_posee: Array) -> float:
	var total := 0.0
	for b in ville_posee:
		total += float(Cite.BATIMENTS.get(str(b.type), {}).get("production", {}).get("or_min", 0.0))
	return total


## Capacité d'accueil totale (logements).
static func capacite_population(ville_posee: Array) -> int:
	var total := 0
	for b in ville_posee:
		total += int(Cite.BATIMENTS.get(str(b.type), {}).get("capacite_population", 0))
	return total


static func consommation_nourriture_min(population: int) -> float:
	return population * float(EQUILIBRAGE.population.conso_nourriture_min)


static func taux_net_nourriture(ville_posee: Array, population: int) -> float:
	return production_nourriture_min(ville_posee) - consommation_nourriture_min(population)


## SURPLUS / EQUILIBRE / PENURIE — l'indicateur qui nourrira plus tard
## le moteur de besoins.
static func statut_nourriture(ville_posee: Array, population: int) -> String:
	var taux := taux_net_nourriture(ville_posee, population)
	if taux > float(EQUILIBRAGE.nourriture.seuil_equilibre):
		return "SURPLUS"
	if taux < -float(EQUILIBRAGE.nourriture.seuil_equilibre):
		return "PENURIE"
	return "EQUILIBRE"


## La population peut croître si : de la place, pas de pénurie, et une
## petite réserve de nourriture.
static func peut_croitre(ville_posee: Array, population: int, nourriture: float) -> bool:
	if population >= capacite_population(ville_posee):
		return false
	if statut_nourriture(ville_posee, population) == "PENURIE":
		return false
	return nourriture >= float(EQUILIBRAGE.population.reserve_min_croissance)


## Pourquoi un bâtiment est-il (in)disponible ? Une seule fonction — le
## système sait toujours EXPLIQUER un verrou.
static func disponibilite(type: String, connaissance_xp: int, pieces: int,
		population: int) -> String:
	var fiche: Dictionary = Cite.BATIMENTS.get(type, {})
	if Cite.palier(connaissance_xp) < int(fiche.get("palier", 0)):
		return "VERROU_CONNAISSANCE"
	if population < int(fiche.get("population_requise", 0)):
		return "VERROU_POPULATION"
	if pieces < int(fiche.get("or", 0)):
		return "PIECES_INSUFFISANTES"
	return "DISPONIBLE"


## UN TICK, pur : reçoit l'état + le temps réellement écoulé, renvoie
## les nouvelles valeurs (rien n'est écrit ici — testable à sec).
## La nourriture ne devient JAMAIS négative.
static func tick(etat: Dictionary, delta_s: float) -> Dictionary:
	var ville_posee: Array = etat.ville
	var population := int(etat.population)
	var prod_n := production_nourriture_min(ville_posee) / 60.0
	var conso := consommation_nourriture_min(population) / 60.0
	var nourriture := maxf(float(etat.nourriture) + (prod_n - conso) * delta_s, 0.0)
	# Les pièces produites s'accumulent en fraction, créditées à l'unité.
	var or_fraction := float(etat.get("or_fraction", 0.0)) \
		+ production_or_min(ville_posee) / 60.0 * delta_s
	var or_gagne := int(or_fraction)
	or_fraction -= or_gagne
	# Croissance : le progrès n'avance que si les conditions sont réunies
	# (il ne se PERD pas pendant une pénurie — pas de punition).
	var progres := float(etat.get("croissance_progres", 0.0))
	var habitant_arrive := false
	if peut_croitre(ville_posee, population, nourriture):
		progres += delta_s
		if progres >= float(EQUILIBRAGE.population.intervalle_croissance_min) * 60.0:
			progres = 0.0
			habitant_arrive = true
	return {"nourriture": nourriture, "or_fraction": or_fraction, "or_gagne": or_gagne,
		"croissance_progres": progres, "habitant_arrive": habitant_arrive}


# ------------------------------------------------- application au profil

## L'autoload Profil, résolu à l'EXÉCUTION : les fonctions pures de ce
## fichier restent compilables (et testables) sans le jeu complet.
static func _profil() -> Node:
	return (Engine.get_main_loop() as SceneTree).root.get_node("Profil")


## LE SEUL point d'écriture : applique un tick au Profil (source de
## vérité unique) et persiste. `dernier_tick` est tenu à jour pour la
## future simulation hors-ligne (prompt suivant — rien de calculé ici).
static func appliquer(delta_s: float) -> Dictionary:
	var p := _profil()
	var resultat := tick({"ville": p.ville, "population": p.population,
		"nourriture": p.nourriture, "or_fraction": p.or_fraction,
		"croissance_progres": p.croissance_progres}, delta_s)
	p.nourriture = float(resultat.nourriture)
	p.or_fraction = float(resultat.or_fraction)
	p.croissance_progres = float(resultat.croissance_progres)
	if bool(resultat.habitant_arrive):
		p.population += 1
	if int(resultat.or_gagne) > 0:
		p.crediter_pieces(int(resultat.or_gagne), "CITY_PRODUCTION", "ville")
	p.dernier_tick = int(Time.get_unix_time_from_system())
	p.sauver()
	return resultat


## Résumé lisible par l'UI (jamais recalculé dans les composants).
static func resume() -> Dictionary:
	var p := _profil()
	return {
		"nourriture": p.nourriture,
		"taux_net": taux_net_nourriture(p.ville, p.population),
		"statut": statut_nourriture(p.ville, p.population),
		"population": p.population,
		"capacite": capacite_population(p.ville),
	}

extends MainLoop
## TESTS DE LOGIQUE du moteur de simulation (fonctions pures — aucun
## profil requis). Lancer :
##   godot --headless --path godot --script res://scripts/test_simulation.gd
## Les tests 9 et 10 (débit unique, source de vérité commune) sont
## garantis par l'architecture : debiter_pieces atomique + Profil unique
## — validés par les captures d'achat de l'itération économie.

var echecs := 0


func _process(_delta: float) -> bool:
	return true   # un seul passage : tout se joue dans _initialize


func _initialize() -> void:
	var maison: Array = [{"type": "maison"}]
	var maison_potager: Array = [{"type": "maison"}, {"type": "potager"}]

	# 1. Une Maison des Aventuriers donne la bonne capacité.
	verifier(Simulation.capacite_population(maison) == 4, "capacité maison = 4")
	# 2. Un Potager augmente la production de nourriture.
	verifier(Simulation.production_nourriture_min(maison) == 0.0, "sans potager : 0 nourriture/min")
	verifier(Simulation.production_nourriture_min(maison_potager) == 2.0, "potager : +2 nourriture/min")
	# 3. La population consomme de la nourriture.
	verifier(absf(Simulation.consommation_nourriture_min(4) - 0.4) < 0.0001,
		"4 habitants consomment 0.4/min")
	# 4. La nourriture ne devient jamais négative.
	var affame := Simulation.tick({"ville": maison, "population": 4, "nourriture": 0.01}, 600.0)
	verifier(float(affame.nourriture) >= 0.0, "nourriture jamais négative")
	# 5. La population ne dépasse jamais sa capacité (croissance refusée).
	verifier(not Simulation.peut_croitre(maison, 4, 100.0), "pleine : pas de croissance")
	# 6. Pas de croissance pendant une pénurie (ni sans réserve).
	verifier(not Simulation.peut_croitre(maison, 3, 100.0), "pénurie : pas de croissance")
	verifier(not Simulation.peut_croitre(maison_potager, 3, 0.5), "réserve trop faible : pas de croissance")
	verifier(Simulation.peut_croitre(maison_potager, 3, 10.0), "place + surplus + réserve : croissance")
	# 7. Un Atelier verrouillé par connaissance ne peut pas être acheté.
	verifier(Simulation.disponibilite("atelier", 100, 10000, 10) == "VERROU_CONNAISSANCE",
		"atelier : verrou connaissance malgré 10 000 pièces")
	#    …et par population, même au bon palier.
	verifier(Simulation.disponibilite("atelier", 300, 10000, 2) == "VERROU_POPULATION",
		"atelier : verrou population")
	# 8. Impossible d'acheter sans assez de pièces.
	verifier(Simulation.disponibilite("potager", 100, 10, 2) == "PIECES_INSUFFISANTES",
		"potager : pièces insuffisantes")
	verifier(Simulation.disponibilite("potager", 100, 150, 2) == "DISPONIBLE", "potager : disponible")
	# Production de pièces : accumulation exacte (production × temps).
	var r := Simulation.tick({"ville": [{"type": "maison"}, {"type": "atelier"}],
		"population": 4, "nourriture": 50.0, "or_fraction": 0.0}, 120.0)
	verifier(int(r.or_gagne) == 2, "atelier : 2 pièces exactement en 2 min")
	# Statuts nourriture.
	verifier(Simulation.statut_nourriture(maison_potager, 2) == "SURPLUS", "statut SURPLUS")
	verifier(Simulation.statut_nourriture(maison, 4) == "PENURIE", "statut PENURIE")
	# Croissance : +1 habitant après l'intervalle configuré.
	var minutes := float(Simulation.EQUILIBRAGE.population.intervalle_croissance_min)
	var etat := {"ville": maison_potager, "population": 2, "nourriture": 10.0,
		"croissance_progres": 0.0, "or_fraction": 0.0}
	var arrive := false
	for i in int(minutes * 60.0 / 5.0) + 2:
		var pas := Simulation.tick(etat, 5.0)
		etat.nourriture = pas.nourriture
		etat.croissance_progres = pas.croissance_progres
		if bool(pas.habitant_arrive):
			arrive = true
			break
	verifier(arrive, "un habitant arrive après l'intervalle de croissance")

	print("ÉCHECS : %d" % echecs)


func verifier(condition: bool, nom: String) -> void:
	if condition:
		print("  OK  — %s" % nom)
	else:
		echecs += 1
		printerr("ÉCHEC — %s" % nom)

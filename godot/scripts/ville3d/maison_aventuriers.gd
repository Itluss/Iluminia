class_name MaisonAventuriers
extends Node3D
## LA MAISON DES AVENTURIERS — placeholder PREMIUM V1, traduit de la
## planche « 6 explorations de silhouette » (direction Porte des
## Étoiles) : pierre claire massive, GRAND toit bleu nuit liseré d'or,
## portail-arche lumineux cyan — la magie est STRUCTURELLE (c'est
## l'entrée elle-même qui rayonne), pas décorative. Volumes gros et
## caricaturés, très peu de micro-détails : lisible en silhouette noire.
##
## REMPLACEMENT FUTUR : cette scène est indépendante — remplacer son
## contenu par un vrai .glb (même racine, pivot au centre de l'emprise
## AU SOL, 1 case = 1 unité, emprise 3×3) suffit ; ni la Simulation, ni
## l'économie, ni la fabrique n'en dépendent.

const PIERRE := Color(0.93, 0.89, 0.8)
const PIERRE_OMBRE := Color(0.84, 0.78, 0.68)
const NUIT := Color(0.21, 0.2, 0.52)        ## toit bleu nuit (planche)
const NUIT_CLAIR := Color(0.29, 0.28, 0.66)

@export var niveau := 1


func _ready() -> void:
	_construire()


## 6 grandes masses : parvis, corps, toit, portail, emblème, aile.
func _construire() -> void:
	# 1. PARVIS — plateforme de pierre + marches LARGES (entrée lisible).
	var socle := BoxMesh.new()
	socle.size = Vector3(2.9, 0.4, 2.5)
	Materiaux.mesh(self, socle, Materiaux.toon(PIERRE_OMBRE), Vector3(0.0, 0.2, 0.0))
	for m in 2:
		var marche := BoxMesh.new()
		marche.size = Vector3(1.7 - m * 0.2, 0.14, 0.42)
		Materiaux.mesh(self, marche, Materiaux.toon(PIERRE_OMBRE),
			Vector3(0.0, 0.07 + m * 0.14, 1.5 - m * 0.2), Vector3.ONE, false)
	# 2. CORPS — un seul gros volume de pierre claire.
	var corps := BoxMesh.new()
	corps.size = Vector3(2.5, 1.6, 2.1)
	Materiaux.mesh(self, corps, Materiaux.toon(PIERRE), Vector3(0.0, 1.2, 0.0))
	# 3. GRAND TOIT bleu nuit débordant + faîtage doré + fanion.
	var toit := PrismMesh.new()
	toit.size = Vector3(3.2, 1.5, 2.7)
	Materiaux.mesh(self, toit, Materiaux.toon(NUIT), Vector3(0.0, 2.75, 0.0))
	# (l'arête du PrismMesh court le long de Z : le faîtage la suit.)
	var faitage := BoxMesh.new()
	faitage.size = Vector3(0.2, 0.12, 2.5)
	Materiaux.mesh(self, faitage, Materiaux.toon(Identite.OR), Vector3(0.0, 3.5, 0.0), Vector3.ONE, false)
	Materiaux.mesh(self, Materiaux.cylindre(0.03, 0.55), Materiaux.toon(Identite.OR_SOMBRE),
		Vector3(0.0, 3.75, 0.0), Vector3.ONE, false)
	var drapeau := BoxMesh.new()
	drapeau.size = Vector3(0.42, 0.26, 0.03)
	Materiaux.mesh(self, drapeau, Materiaux.toon(Identite.OR), Vector3(0.24, 3.9, 0.0), Vector3.ONE, false)
	# 4. PORTAIL DES ÉTOILES — encadrement d'or massif, arche intérieure
	# ENTIÈREMENT lumineuse (cyan) : la magie fait partie du bâtiment.
	var cadre := BoxMesh.new()
	cadre.size = Vector3(1.34, 1.5, 0.14)
	Materiaux.mesh(self, cadre, Materiaux.toon(Identite.OR), Vector3(0.0, 0.99, 1.06))
	Materiaux.mesh(self, Materiaux.sphere(0.67), Materiaux.toon(Identite.OR),
		Vector3(0.0, 1.74, 1.06), Vector3(1.0, 0.82, 0.2), false)
	var interieur := BoxMesh.new()
	interieur.size = Vector3(1.02, 1.34, 0.1)
	Materiaux.mesh(self, interieur, Materiaux.emissif(Identite.CYAN, 1.1), Vector3(0.0, 0.94, 1.12))
	Materiaux.mesh(self, Materiaux.sphere(0.51), Materiaux.emissif(Identite.CYAN, 1.1),
		Vector3(0.0, 1.6, 1.12), Vector3(1.0, 0.8, 0.22), false)
	var seuil := BoxMesh.new()
	seuil.size = Vector3(1.0, 0.05, 0.5)
	Materiaux.mesh(self, seuil, Materiaux.emissif(Identite.CYAN, 0.5),
		Vector3(0.0, 0.43, 1.35), Vector3.ONE, false)
	# 5. EMBLÈME — gemme-étoile dorée sur le PIGNON avant du toit (icône).
	Materiaux.mesh(self, Materiaux.sphere(0.3), Materiaux.emissif(Identite.OR, 1.2),
		Vector3(0.0, 2.72, 1.4), Vector3(0.85, 1.35, 0.3), false)
	for cote: float in [-1.0, 1.0]:
		Materiaux.mesh(self, Materiaux.sphere(0.09), Materiaux.emissif(Identite.OR, 1.4),
			Vector3(cote * 0.8, 2.5, 1.38), Vector3.ONE, false)
	# 6. AILE latérale plus basse (asymétrie de silhouette, même langage).
	var aile := BoxMesh.new()
	aile.size = Vector3(1.15, 1.05, 1.6)
	Materiaux.mesh(self, aile, Materiaux.toon(PIERRE), Vector3(1.62, 0.92, -0.15))
	var toit_aile := PrismMesh.new()
	toit_aile.size = Vector3(1.5, 0.75, 1.9)
	Materiaux.mesh(self, toit_aile, Materiaux.toon(NUIT_CLAIR), Vector3(1.62, 1.8, -0.15))
	# Fenêtres arquées lumineuses (2 + 1 sur l'aile) et bannière violette.
	for cote: float in [-1.0, 1.0]:
		Materiaux.mesh(self, Materiaux.sphere(0.17), Materiaux.emissif(Identite.CYAN, 0.8),
			Vector3(cote * 0.92, 1.5, 1.07), Vector3(1.0, 1.25, 0.3), false)
	Materiaux.mesh(self, Materiaux.sphere(0.15), Materiaux.emissif(Identite.CYAN, 0.8),
		Vector3(1.62, 1.05, 0.68), Vector3(1.0, 1.2, 0.3), false)
	var banniere := BoxMesh.new()
	banniere.size = Vector3(0.36, 0.85, 0.05)
	Materiaux.mesh(self, banniere, Materiaux.toon(Identite.VIOLET), Vector3(-0.95, 1.55, 1.08), Vector3.ONE, false)
	Materiaux.mesh(self, Materiaux.sphere(0.07), Materiaux.emissif(Identite.OR, 1.4),
		Vector3(-0.95, 1.75, 1.12), Vector3.ONE, false)
	_construire_evolution()


## ÉVOLUTION par niveau : la maison grandit dans le MÊME langage de
## formes (annexe, tourelles à dôme bleu nuit, flèche-lanterne) — jamais
## un changement d'identité.
func _construire_evolution() -> void:
	if niveau >= 2:
		var annexe := BoxMesh.new()
		annexe.size = Vector3(1.1, 0.95, 1.3)
		Materiaux.mesh(self, annexe, Materiaux.toon(PIERRE), Vector3(-1.55, 0.85, -0.4))
		var toit_a := PrismMesh.new()
		toit_a.size = Vector3(1.45, 0.7, 1.6)
		Materiaux.mesh(self, toit_a, Materiaux.toon(NUIT_CLAIR), Vector3(-1.55, 1.65, -0.4))
	if niveau >= 3:
		_tourelle(Vector3(1.55, 0.0, -1.15))
	if niveau >= 4:
		_tourelle(Vector3(-1.55, 0.0, -1.15))
	if niveau >= 5:
		# FLÈCHE-LANTERNE centrale : la connaissance rayonne au sommet.
		Materiaux.mesh(self, Materiaux.cylindre(0.34, 1.6), Materiaux.toon(PIERRE),
			Vector3(0.0, 4.1, -0.5))
		Materiaux.mesh(self, Materiaux.sphere(0.44), Materiaux.toon(NUIT),
			Vector3(0.0, 4.95, -0.5), Vector3(1.0, 0.8, 1.0), false)
		Materiaux.mesh(self, Materiaux.sphere(0.16), Materiaux.emissif(Identite.CYAN, 2.2),
			Vector3(0.0, 5.45, -0.5), Vector3(1.0, 1.4, 1.0), false)


func _tourelle(base: Vector3) -> void:
	Materiaux.mesh(self, Materiaux.cylindre(0.42, 2.4), Materiaux.toon(PIERRE),
		base + Vector3(0.0, 1.2, 0.0))
	Materiaux.mesh(self, Materiaux.sphere(0.55), Materiaux.toon(NUIT),
		base + Vector3(0.0, 2.5, 0.0), Vector3(1.0, 0.75, 1.0), false)
	Materiaux.mesh(self, Materiaux.cone(0.12, 0.5), Materiaux.toon(Identite.OR),
		base + Vector3(0.0, 3.1, 0.0), Vector3.ONE, false)
	Materiaux.mesh(self, Materiaux.sphere(0.12), Materiaux.emissif(Identite.CYAN, 0.9),
		base + Vector3(0.0, 1.7, 0.44), Vector3(1.0, 1.3, 0.3), false)

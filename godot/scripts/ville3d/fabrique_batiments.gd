class_name FabriqueBatiments
extends RefCounted
## FABRIQUE DES BÂTIMENTS 3D : un type métier → sa représentation
## visuelle. Ajouter un bâtiment = une entrée ICI (jamais de nouveau
## code dispersé dans ville.gd). Un type sans rendu dédié reçoit le
## bloc générique — le rendu ne casse jamais, il reste juste sobre.
##
## La fabrique ne décide RIEN : ni prix, ni disponibilité, ni
## production — elle transforme une instruction de rendu en géométrie.

## Scènes dédiées, indépendantes et REMPLAÇABLES : substituer le contenu
## d'une scène par un vrai asset .glb (même racine, pivot au centre de
## l'emprise au sol, 1 case = 1 unité) ne touche ni la Simulation, ni
## l'économie, ni cette fabrique.
const SCENES := {
	"maison": "res://scenes/ville3d/maison_aventuriers.tscn",
}


## Tout le catalogue est pris en charge (scène dédiée, constructeur
## simple ou bloc générique) — testé contre Cite.BATIMENTS.
static func types_geres() -> Array:
	return Cite.BATIMENTS.keys()


static func construire(parent: Node3D, type: String, niveau := 1) -> void:
	if SCENES.has(type):
		var scene: PackedScene = load(str(SCENES[type]))
		var inst: Node3D = scene.instantiate()
		inst.niveau = niveau
		parent.add_child(inst)
		return
	match type:
		"potager":
			for r in 3:
				var rangee := BoxMesh.new()
				rangee.size = Vector3(1.6, 0.14, 0.32)
				Materiaux.mesh(parent, rangee, Materiaux.toon(Color(0.44, 0.3, 0.2)),
					Vector3(0.0, 0.07, -0.55 + r * 0.55))
				for l in 4:
					Materiaux.mesh(parent, Materiaux.sphere(0.1), Materiaux.toon(Identite.VERT),
						Vector3(-0.6 + l * 0.4, 0.2, -0.55 + r * 0.55), Vector3.ONE, false)
			var barriere := BoxMesh.new()
			barriere.size = Vector3(1.9, 0.28, 0.05)
			Materiaux.mesh(parent, barriere, Materiaux.toon(Color(0.6, 0.44, 0.28)),
				Vector3(0.0, 0.2, 0.95), Vector3.ONE, false)
		"atelier":
			var murs := BoxMesh.new()
			murs.size = Vector3(1.6, 1.0, 1.3)
			Materiaux.mesh(parent, murs, Materiaux.toon(Color(0.68, 0.5, 0.32)), Vector3(0.0, 0.5, 0.0))
			var toit := PrismMesh.new()
			toit.size = Vector3(1.9, 0.7, 1.6)
			Materiaux.mesh(parent, toit, Materiaux.toon(Color(0.45, 0.32, 0.22)), Vector3(0.0, 1.35, 0.0))
		"forge":
			var murs_f := BoxMesh.new()
			murs_f.size = Vector3(1.7, 1.1, 1.4)
			Materiaux.mesh(parent, murs_f, Materiaux.toon(Color(0.52, 0.52, 0.58)), Vector3(0.0, 0.55, 0.0))
			var toit_f := PrismMesh.new()
			toit_f.size = Vector3(2.0, 0.8, 1.7)
			Materiaux.mesh(parent, toit_f, Materiaux.toon(Color(0.3, 0.3, 0.36)), Vector3(0.0, 1.5, 0.0))
			Materiaux.mesh(parent, Materiaux.sphere(0.16), Materiaux.emissif(Identite.ORANGE, 1.8),
				Vector3(0.0, 0.62, 0.74), Vector3.ONE, false)
		_:
			var bloc := BoxMesh.new()
			bloc.size = Vector3(1.5, 1.0, 1.5)
			Materiaux.mesh(parent, bloc, Materiaux.toon(Identite.PANNEAU_CLAIR), Vector3(0.0, 0.5, 0.0))

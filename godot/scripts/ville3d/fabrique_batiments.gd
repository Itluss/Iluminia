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

## Assets .glb de l'ART KIT : un type → son modèle sculpté. Remplacer un
## asset = remplacer son .glb (mêmes conventions), rien d'autre à toucher.
const MODELES := {
	"potager": "res://assets/artkit/architecture/potager.glb",
	"atelier": "res://assets/artkit/architecture/atelier.glb",
	"forge": "res://assets/artkit/architecture/moulin.glb",
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
	if MODELES.has(type):
		# Asset .glb de l'art kit : instancié, harmonisé au rendu du jeu,
		# puis animé si le modèle expose des nœuds d'animation nommés.
		var modele: Node3D = (load(str(MODELES[type])) as PackedScene).instantiate()
		Univers.harmoniser_gltf(modele)
		parent.add_child(modele)
		Vie.animer(modele)
		return
	# Sans asset dédié : bloc générique PLACEHOLDER, jamais un final.
	var bloc := BoxMesh.new()
	bloc.size = Vector3(1.5, 1.0, 1.5)
	Materiaux.mesh(parent, bloc, Materiaux.toon(Identite.PANNEAU_CLAIR), Vector3(0.0, 0.5, 0.0))

class_name MaisonAventuriers
extends Node3D
## LA MAISON DES AVENTURIERS — wrapper du VRAI asset 3D (.glb produit
## depuis la planche de référence : toit bleu nuit courbe, portail cyan
## lumineux, pierre claire, tour latérale à dôme, accents or, bannières
## violettes, étoile au pignon).
##
## Le wrapper ne contient AUCUNE géométrie : il instancie l'asset et
## pilote les micro-animations (le portail « respire », la lumière de la
## tour varie à peine) + l'apparition. Remplacer l'asset = remplacer le
## .glb (mêmes conventions : pivot au centre de l'emprise au sol,
## 1 case = 1 unité, emprise 3×3, façade +Z) — le métier ne connaît
## jamais ce chemin, seule la fabrique instancie cette scène.

const ASSET := "res://assets/3d/buildings/maison_aventuriers/maison_aventuriers.glb"

@export var niveau := 1

var _portail: StandardMaterial3D
var _fenetres: StandardMaterial3D
var _t := 0.0


func _ready() -> void:
	var inst: Node3D = (load(ASSET) as PackedScene).instantiate()
	add_child(inst)
	_harmoniser_toon(inst)
	_portail = _materiau_anime(inst, "Portail")
	_fenetres = _materiau_anime(inst, "FenetresTour")


## Les matériaux importés du .glb reçoivent le MÊME modèle d'éclairage
## que le reste de la ville (diffuse/specular toon) : l'asset s'intègre
## au style au lieu de briller « PBR réaliste » à part.
func _harmoniser_toon(racine: Node) -> void:
	for enfant in racine.find_children("*", "MeshInstance3D", true, false):
		var mi := enfant as MeshInstance3D
		for s in mi.mesh.get_surface_count():
			var m := mi.get_active_material(s)
			if m is StandardMaterial3D:
				var copie: StandardMaterial3D = m.duplicate()
				copie.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
				copie.specular_mode = BaseMaterial3D.SPECULAR_TOON
				mi.set_surface_override_material(s, copie)


## Duplique le matériau du nœud nommé : l'animation ne touche jamais la
## ressource partagée de l'asset.
func _materiau_anime(racine: Node, nom: String) -> StandardMaterial3D:
	var noeud := racine.find_child(nom, true, false)
	if noeud is MeshInstance3D:
		var m := (noeud as MeshInstance3D).get_active_material(0)
		if m is StandardMaterial3D:
			var copie: StandardMaterial3D = m.duplicate()
			(noeud as MeshInstance3D).material_override = copie
			return copie
	return null


## IDLE discret : pulse LENT et FAIBLE du portail (jamais de
## clignotement), très légère respiration des fenêtres de la tour.
## L'architecture elle-même ne bouge pas.
func _process(delta: float) -> void:
	_t += delta
	if _portail != null:
		_portail.emission_energy_multiplier = 1.1 + 0.28 * (0.5 + 0.5 * sin(_t * 1.6))
	if _fenetres != null:
		_fenetres.emission_energy_multiplier = 0.95 + 0.16 * (0.5 + 0.5 * sin(_t * 1.05 + 1.7))

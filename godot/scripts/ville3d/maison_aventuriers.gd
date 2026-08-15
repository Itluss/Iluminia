class_name MaisonAventuriers
extends Node3D
## LA MAISON DES AVENTURIERS — bâtiment HÉRO d'Illuminia (art kit).
##
## Wrapper SANS géométrie : il instancie l'asset .glb sculpté, l'harmonise
## au rendu du jeu et laisse le système Vie animer ses nœuds nommés
## (Portail, FenetresMagie, Fanion, Lanternes). Les niveaux d'évolution
## ajoutent des volumes de prestige — la silhouette, elle, ne change pas.
##
## REMPLACEMENT : changer le .glb (mêmes conventions — emprise 3×3, pivot
## au centre au sol, façade +Z) suffit ; le métier n'en sait rien.

const ASSET := "res://assets/artkit/architecture/maison_aventuriers.glb"

@export var niveau := 1


func _ready() -> void:
	var inst: Node3D = (load(ASSET) as PackedScene).instantiate()
	add_child(inst)
	Univers.harmoniser_gltf(inst)
	Vie.animer(inst)

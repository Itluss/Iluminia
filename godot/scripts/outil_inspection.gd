extends SceneTree
## Outil de développement : inspecte les modèles Meshy importés
## (arbre, boîte englobante, animations). Lancer :
## godot --headless --path godot --script res://scripts/outil_inspection.gd


func _init() -> void:
	for chemin in [
		"res://assets/models/max-character-rigged.glb",
		"res://assets/models/max-walk.glb",
		"res://assets/models/max-run.glb",
		"res://assets/models/zep-character.glb",
	]:
		print("\n=== ", chemin)
		var scene: PackedScene = load(chemin)
		if scene == null:
			print("  échec de chargement")
			continue
		var racine := scene.instantiate()
		_arbre(racine, 1)
		var aabb := _aabb_totale(racine)
		print("  AABB position=", aabb.position, " taille=", aabb.size)
		racine.free()
	quit()


func _arbre(n: Node, prof: int) -> void:
	var infos := n.get_class()
	if n is AnimationPlayer:
		infos += " animations=" + str((n as AnimationPlayer).get_animation_list())
	if n is Skeleton3D:
		infos += " os=" + str((n as Skeleton3D).get_bone_count())
	print("  ".repeat(prof), n.name, " (", infos, ")")
	if prof < 4:
		for e in n.get_children():
			_arbre(e, prof + 1)


func _aabb_totale(n: Node) -> AABB:
	var boite := AABB()
	var premier := true
	var pile: Array = [n]
	while not pile.is_empty():
		var courant: Node = pile.pop_back()
		if courant is MeshInstance3D:
			var mi := courant as MeshInstance3D
			var b: AABB = mi.get_aabb()
			# Transformée globale approximative (pas dans l'arbre : transform locale cumulée absente)
			if premier:
				boite = b
				premier = false
			else:
				boite = boite.merge(b)
		pile.append_array(courant.get_children())
	return boite

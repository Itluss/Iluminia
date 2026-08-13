class_name Personnage3D
extends Node3D
## Personnage « toon chibi » 100 % procédural, style planche Eluminia :
## corps rond, capuche claire, grands yeux, pieds trottinants — ou bébé
## dragon (ailes battantes, cornes, ventre crème, queue). Contours peints
## par coque inversée, squash & stretch, flash d'impact, anneau doré du
## porteur, bulles de protection, étiquette de nom.

var genre := "chasseur"          ## "chasseur" ou "dragon"
var couleur := Color(0.30, 0.75, 0.72)
var etiquette := ""
var en_marche := false

var _t := 0.0
var _cap := 0.0                  ## orientation lissée (radians)
var _cible_cap := 0.0
var _racine: Node3D              ## tout ce qui rebondit
var _mat_corps: StandardMaterial3D
var _flash := 0.0
var _pied_g: MeshInstance3D
var _pied_d: MeshInstance3D
var _aile_g: Node3D
var _aile_d: Node3D
var _anneau: MeshInstance3D
var _bulle: MeshInstance3D
var _mat_bulle: StandardMaterial3D


func _ready() -> void:
	_racine = Node3D.new()
	add_child(_racine)
	if genre == "dragon":
		_construire_dragon()
	else:
		_construire_chasseur()
	# Anneau doré du porteur du dragon (masqué par défaut).
	_anneau = Materiaux.mesh(self, Materiaux.tore(0.06, 0.85),
		Materiaux.emissif(Color(1.0, 0.8, 0.2), 2.5), Vector3(0.0, 0.06, 0.0), Vector3.ONE, false)
	_anneau.visible = false
	# Bulle de protection (masquée par défaut).
	_mat_bulle = Materiaux.verre(Color(0.7, 0.45, 1.0), 0.25, 1.5)
	_bulle = Materiaux.mesh(self, Materiaux.sphere(0.95), _mat_bulle,
		Vector3(0.0, 0.7, 0.0), Vector3.ONE, false)
	_bulle.visible = false
	# Étiquette de nom.
	if etiquette != "":
		var nom := Label3D.new()
		nom.text = etiquette
		nom.pixel_size = 0.0022 # glyphes rendus plus fins → texte net
		nom.font_size = 130
		nom.outline_size = 34
		nom.modulate = Color(1.0, 1.0, 1.0, 0.95)
		nom.outline_modulate = Materiaux.COULEUR_CONTOUR
		nom.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		nom.no_depth_test = true
		nom.position = Vector3(0.0, 1.75, 0.0)
		add_child(nom)


func _construire_chasseur() -> void:
	_mat_corps = Materiaux.toon(couleur)
	# Corps rond.
	Materiaux.mesh(_racine, Materiaux.sphere(0.5), _mat_corps,
		Vector3(0.0, 0.55, 0.0), Vector3(1.0, 0.95, 1.0))
	# Capuche : calotte claire.
	Materiaux.mesh(_racine, Materiaux.sphere(0.4), Materiaux.toon(couleur.lightened(0.45)),
		Vector3(0.0, 0.82, -0.08), Vector3(1.05, 0.7, 1.05))
	# Yeux : blancs + pupilles, tournés vers +Z (le « visage »).
	for cote: float in [-1.0, 1.0]:
		Materiaux.mesh(_racine, Materiaux.sphere(0.13), Materiaux.toon(Color.WHITE),
			Vector3(cote * 0.18, 0.66, 0.4), Vector3.ONE, false)
		Materiaux.mesh(_racine, Materiaux.sphere(0.06), Materiaux.toon(Materiaux.COULEUR_CONTOUR),
			Vector3(cote * 0.18, 0.66, 0.5), Vector3.ONE, false)
	# Pieds.
	_pied_g = Materiaux.mesh(_racine, Materiaux.sphere(0.17), Materiaux.toon(couleur.darkened(0.35)),
		Vector3(-0.2, 0.15, 0.0))
	_pied_d = Materiaux.mesh(_racine, Materiaux.sphere(0.17), Materiaux.toon(couleur.darkened(0.35)),
		Vector3(0.2, 0.15, 0.0))


func _construire_dragon() -> void:
	_mat_corps = Materiaux.toon(couleur)
	# Corps.
	Materiaux.mesh(_racine, Materiaux.sphere(0.42), _mat_corps,
		Vector3(0.0, 0.45, 0.0), Vector3(1.0, 0.95, 1.1))
	# Ventre crème.
	Materiaux.mesh(_racine, Materiaux.sphere(0.3), Materiaux.toon(Color(0.96, 0.93, 0.72)),
		Vector3(0.0, 0.38, 0.18), Vector3.ONE, false)
	# Ailes battantes (pivots animés).
	_aile_g = _aile(-1.0)
	_aile_d = _aile(1.0)
	# Cornes.
	for cote: float in [-1.0, 1.0]:
		Materiaux.mesh(_racine, Materiaux.cone(0.08, 0.28), Materiaux.toon(Color(0.96, 0.9, 0.75)),
			Vector3(cote * 0.18, 0.85, -0.05))
	# Queue : petit cône vers l'arrière.
	var queue := Materiaux.mesh(_racine, Materiaux.cone(0.12, 0.55), Materiaux.toon(couleur.darkened(0.1)),
		Vector3(0.0, 0.4, -0.55))
	queue.rotation_degrees = Vector3(-70.0, 0.0, 0.0)
	# Grands yeux.
	for cote: float in [-1.0, 1.0]:
		Materiaux.mesh(_racine, Materiaux.sphere(0.12), Materiaux.toon(Color.WHITE),
			Vector3(cote * 0.16, 0.6, 0.32), Vector3.ONE, false)
		Materiaux.mesh(_racine, Materiaux.sphere(0.055), Materiaux.toon(Materiaux.COULEUR_CONTOUR),
			Vector3(cote * 0.16, 0.6, 0.42), Vector3.ONE, false)
	# Museau.
	Materiaux.mesh(_racine, Materiaux.sphere(0.14), Materiaux.toon(couleur.lightened(0.2)),
		Vector3(0.0, 0.45, 0.4), Vector3.ONE, false)


func _aile(cote: float) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = Vector3(cote * 0.3, 0.65, -0.1)
	_racine.add_child(pivot)
	var membrane := PrismMesh.new()
	membrane.size = Vector3(0.7, 0.5, 0.06)
	var mi := Materiaux.mesh(pivot, membrane, Materiaux.toon(couleur.darkened(0.25)),
		Vector3(cote * 0.4, 0.15, 0.0))
	mi.rotation_degrees = Vector3(0.0, 0.0, cote * -20.0)
	return pivot


# ---------------------------------------------------------------- animation

func _process(delta: float) -> void:
	_t += delta
	# Orientation lissée vers la direction du regard.
	_cap = lerp_angle(_cap, _cible_cap, minf(delta * 12.0, 1.0))
	_racine.rotation.y = _cap
	# Rebond de trottinement / respiration.
	var saut := absf(sin(_t * 10.0)) * (0.14 if en_marche else 0.02)
	_racine.position.y = saut
	# Pieds qui trottinent.
	if _pied_g != null:
		var pas := sin(_t * 14.0) * (0.16 if en_marche else 0.0)
		_pied_g.position.z = pas
		_pied_d.position.z = -pas
	# Battement d'ailes du dragon.
	if _aile_g != null:
		var bat := sin(_t * 9.0) * 0.6
		_aile_g.rotation.z = 0.3 + bat
		_aile_d.rotation.z = -0.3 - bat
	# Flash d'impact : émission blanche qui retombe.
	if _flash > 0.0:
		_flash = maxf(_flash - delta * 5.0, 0.0)
		_mat_corps.emission_enabled = _flash > 0.0
		_mat_corps.emission = Color.WHITE
		_mat_corps.emission_energy_multiplier = _flash * 1.4


## Oriente le personnage vers une direction du plan (x, z).
func regarder(dir: Vector2) -> void:
	if dir.length() > 0.01:
		_cible_cap = atan2(dir.x, dir.y)


func flash() -> void:
	_flash = 1.0


## Squash & stretch : écrasé à l'impact, puis retour élastique.
func squash(force := 0.25) -> void:
	_racine.scale = Vector3(1.0 + force, 1.0 - force, 1.0 + force)
	var tw := create_tween()
	tw.tween_property(_racine, "scale", Vector3.ONE, 0.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func montrer_anneau(oui: bool) -> void:
	_anneau.visible = oui
	if oui:
		_anneau.rotation.y += 0.02


## 0 = pas de bulle ; sinon opacité relative. `teinte` : violet (bouclier)
## ou cyan (réapparition).
func montrer_bulle(force: float, teinte: Color) -> void:
	_bulle.visible = force > 0.0
	if force > 0.0:
		_mat_bulle.albedo_color = Color(teinte.r, teinte.g, teinte.b, 0.22 * force)
		_mat_bulle.emission = teinte

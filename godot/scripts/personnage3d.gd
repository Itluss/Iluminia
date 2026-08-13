class_name Personnage3D
extends Node3D
## LES LUMINS — le style de personnage propre à Iluminia.
##
## Un Lumin est un petit porteur de lumière : corps rond et joufflu à gros
## contour, grands yeux, écharpe au vent… et surtout sa CRÊTE-LUMIÈRE, la
## signature du personnage : une petite forme émissive qui flotte au-dessus
## de sa tête et brille dans la nuit (étoile, éclair, goutte, flamme…).
## C'est elle qui identifie chacun en un coup d'œil, même en pleine mêlée —
## et elle fait écho à l'étoile du logo ILLUMINIA.
##
## STYLE ÉVOLUTIF : chaque personnage est décrit par une FICHE (dictionnaire
## ci-dessous). Nouveau héros = nouvelle fiche ; nouvel accessoire = une
## entrée de fiche + un petit constructeur (_accessoire_*). Rien d'autre à
## toucher — l'arène et le menu instancient tous les Lumins pareil.
## Le bébé dragon suit le même langage (rondeurs, membrane lumineuse).

## Fiches des personnages jouables (teintes : identite.gd).
## `variantes` : garde-robe de couleurs — la première est débloquée d'office,
## les autres s'obtiennent via le cadeau quotidien (voir profil.gd).
const FICHES := {
	"Max": {"couleur": Identite.TEINTE_MAX, "crete": "etoile", "crete_couleur": Identite.OR,
		"echarpe": Identite.OR, "accessoire": "",
		"variantes": [Identite.TEINTE_MAX, Identite.CYAN, Identite.OR, Identite.VERT]},
	"Zep": {"couleur": Identite.TEINTE_ZEP, "crete": "eclair", "crete_couleur": Identite.CYAN,
		"echarpe": Identite.CREME, "accessoire": "hoverboard",
		"variantes": [Identite.TEINTE_ZEP, Identite.MAGENTA, Identite.BLEU, Identite.ORANGE]},
	"Nova": {"couleur": Identite.TEINTE_NOVA, "crete": "goutte", "crete_couleur": Identite.CREME,
		"echarpe": Identite.VIOLET, "accessoire": "",
		"variantes": [Identite.TEINTE_NOVA, Identite.VERT, Identite.VIOLET, Identite.ROUGE]},
	"Ficelle": {"couleur": Identite.TEINTE_FICELLE, "crete": "flamme", "crete_couleur": Identite.ORANGE,
		"echarpe": Identite.CYAN, "accessoire": "",
		"variantes": [Identite.TEINTE_FICELLE, Identite.ORANGE, Identite.CYAN, Identite.CREME]},
}

## Si vrai, la couleur vient de la fiche ; mettre à faux pour imposer une
## variante (sélection du joueur, aperçus de la garde-robe).
var utiliser_fiche_couleur := true

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
var _crete: Node3D
var _pan_echarpe: MeshInstance3D
var _planche: Node3D             ## hoverboard éventuel
var _anneau: MeshInstance3D
var _bulle: MeshInstance3D
var _mat_bulle: StandardMaterial3D


func _ready() -> void:
	_racine = Node3D.new()
	add_child(_racine)
	if genre == "dragon":
		_construire_dragon()
	else:
		var fiche: Dictionary = FICHES.get(etiquette, {})
		if not fiche.is_empty() and utiliser_fiche_couleur:
			couleur = fiche.couleur
		_construire_lumin(fiche)
	# Anneau doré du porteur du dragon (masqué par défaut).
	_anneau = Materiaux.mesh(self, Materiaux.tore(0.85, 0.07),
		Materiaux.emissif(Identite.OR, 2.5), Vector3(0.0, 0.06, 0.0), Vector3.ONE, false)
	_anneau.visible = false
	# Bulle de protection (masquée par défaut).
	_mat_bulle = Materiaux.verre(Identite.VIOLET, 0.25, 1.5)
	_bulle = Materiaux.mesh(self, Materiaux.sphere(0.95), _mat_bulle,
		Vector3(0.0, 0.7, 0.0), Vector3.ONE, false)
	_bulle.visible = false
	# Étiquette de nom.
	if etiquette != "":
		var nom := Label3D.new()
		nom.text = etiquette
		nom.pixel_size = 0.0022
		nom.font_size = 130
		nom.outline_size = 34
		nom.modulate = Color(1.0, 1.0, 1.0, 0.95)
		nom.outline_modulate = Identite.CONTOUR
		nom.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		nom.no_depth_test = true
		nom.position = Vector3(0.0, 1.95, 0.0)
		add_child(nom)


# ---------------------------------------------------------------- Lumin

func _construire_lumin(fiche: Dictionary) -> void:
	_mat_corps = Materiaux.toon(couleur)
	# Corps rond et joufflu.
	Materiaux.mesh(_racine, Materiaux.sphere(0.5), _mat_corps,
		Vector3(0.0, 0.55, 0.0), Vector3(1.0, 0.95, 1.0))
	# Ventre crème lumineux (les Lumins portent la lumière en eux).
	var ventre := Materiaux.toon(Identite.CREME)
	ventre.emission_enabled = true
	ventre.emission = Identite.CREME
	ventre.emission_energy_multiplier = 0.25
	Materiaux.mesh(_racine, Materiaux.sphere(0.32), ventre,
		Vector3(0.0, 0.42, 0.22), Vector3.ONE, false)
	# Grands yeux expressifs vers +Z.
	for cote: float in [-1.0, 1.0]:
		Materiaux.mesh(_racine, Materiaux.sphere(0.13), Materiaux.toon(Color.WHITE),
			Vector3(cote * 0.18, 0.68, 0.4), Vector3.ONE, false)
		Materiaux.mesh(_racine, Materiaux.sphere(0.06), Materiaux.toon(Identite.CONTOUR),
			Vector3(cote * 0.18, 0.68, 0.5), Vector3.ONE, false)
		# Petit éclat de vie dans l'œil.
		Materiaux.mesh(_racine, Materiaux.sphere(0.022), Materiaux.toon(Color.WHITE),
			Vector3(cote * 0.15, 0.72, 0.54), Vector3.ONE, false)
	# Écharpe : anneau au cou + pan flottant derrière.
	var teinte_echarpe: Color = fiche.get("echarpe", Identite.CREME)
	var col := Materiaux.mesh(_racine, Materiaux.tore(0.42, 0.09), Materiaux.toon(teinte_echarpe),
		Vector3(0.0, 0.82, 0.0))
	col.rotation_degrees = Vector3(12.0, 0.0, 0.0)
	var pan := BoxMesh.new()
	pan.size = Vector3(0.22, 0.5, 0.05)
	_pan_echarpe = Materiaux.mesh(_racine, pan, Materiaux.toon(teinte_echarpe.darkened(0.12)),
		Vector3(0.0, 0.6, -0.45))
	_pan_echarpe.rotation_degrees = Vector3(-25.0, 0.0, 0.0)
	# CRÊTE-LUMIÈRE signature, flottant au-dessus de la tête.
	_crete = Node3D.new()
	_crete.position = Vector3(0.0, 1.35, 0.0)
	_racine.add_child(_crete)
	_construire_crete(str(fiche.get("crete", "etoile")), fiche.get("crete_couleur", Identite.OR))
	# Pieds ou accessoire.
	if str(fiche.get("accessoire", "")) == "hoverboard":
		_accessoire_hoverboard()
	else:
		_pied_g = Materiaux.mesh(_racine, Materiaux.sphere(0.17), Materiaux.toon(couleur.darkened(0.35)),
			Vector3(-0.2, 0.15, 0.0))
		_pied_d = Materiaux.mesh(_racine, Materiaux.sphere(0.17), Materiaux.toon(couleur.darkened(0.35)),
			Vector3(0.2, 0.15, 0.0))


## Les crêtes-lumières : petites constellations émissives, une par héros.
func _construire_crete(forme: String, teinte: Color) -> void:
	var mat := Materiaux.emissif(teinte, 2.4)
	match forme:
		"etoile":
			# Cœur + quatre rayons : l'étoile du logo.
			Materiaux.mesh(_crete, Materiaux.sphere(0.09), mat, Vector3.ZERO, Vector3.ONE, false)
			for i in 4:
				var ang := PI / 2.0 * i
				var branche := Materiaux.mesh(_crete, Materiaux.cone(0.05, 0.18), mat,
					Vector3(sin(ang) * 0.14, cos(ang) * 0.14, 0.0), Vector3.ONE, false)
				branche.rotation_degrees = Vector3(0.0, 0.0, -rad_to_deg(ang))
		"eclair":
			for i in 2:
				var segment := BoxMesh.new()
				segment.size = Vector3(0.08, 0.2, 0.05)
				var mi := Materiaux.mesh(_crete, segment, mat,
					Vector3(0.05 - 0.1 * i, 0.08 - 0.16 * i, 0.0), Vector3.ONE, false)
				mi.rotation_degrees = Vector3(0.0, 0.0, -28.0)
		"goutte":
			Materiaux.mesh(_crete, Materiaux.sphere(0.09), mat, Vector3(0.0, -0.03, 0.0), Vector3.ONE, false)
			Materiaux.mesh(_crete, Materiaux.cone(0.07, 0.16), mat, Vector3(0.0, 0.1, 0.0), Vector3.ONE, false)
		"flamme":
			Materiaux.mesh(_crete, Materiaux.cone(0.1, 0.22), mat, Vector3(0.0, 0.02, 0.0), Vector3.ONE, false)
			Materiaux.mesh(_crete, Materiaux.cone(0.05, 0.14), mat, Vector3(0.04, 0.14, 0.0), Vector3.ONE, false)
		_:
			Materiaux.mesh(_crete, Materiaux.sphere(0.09), mat, Vector3.ZERO, Vector3.ONE, false)


## Hoverboard de Zep : planche joufflue qui lévite, réacteurs lumineux.
func _accessoire_hoverboard() -> void:
	_planche = Node3D.new()
	_planche.position = Vector3(0.0, 0.12, 0.0)
	_racine.add_child(_planche)
	var forme := BoxMesh.new()
	forme.size = Vector3(0.62, 0.1, 0.95)
	Materiaux.mesh(_planche, forme, Materiaux.toon(couleur.darkened(0.3)), Vector3.ZERO)
	for cote: float in [-1.0, 1.0]:
		Materiaux.mesh(_planche, Materiaux.sphere(0.07), Materiaux.emissif(Identite.CYAN, 2.2),
			Vector3(0.0, -0.02, cote * 0.42), Vector3.ONE, false)


# ---------------------------------------------------------------- dragon

## Le bébé dragon-lumière : mêmes rondeurs, membranes et cornes émissives.
func _construire_dragon() -> void:
	_mat_corps = Materiaux.toon(couleur)
	Materiaux.mesh(_racine, Materiaux.sphere(0.42), _mat_corps,
		Vector3(0.0, 0.45, 0.0), Vector3(1.0, 0.95, 1.1))
	# Ventre-lanterne : c'est LUI, la lumière que tout le monde se dispute.
	var ventre := Materiaux.toon(Identite.CREME)
	ventre.emission_enabled = true
	ventre.emission = Identite.CREME
	ventre.emission_energy_multiplier = 0.9
	Materiaux.mesh(_racine, Materiaux.sphere(0.3), ventre,
		Vector3(0.0, 0.38, 0.18), Vector3.ONE, false)
	_aile_g = _aile(-1.0)
	_aile_d = _aile(1.0)
	for cote: float in [-1.0, 1.0]:
		Materiaux.mesh(_racine, Materiaux.cone(0.08, 0.28), Materiaux.emissif(Identite.CREME, 0.8),
			Vector3(cote * 0.18, 0.85, -0.05))
	var queue := Materiaux.mesh(_racine, Materiaux.cone(0.12, 0.55), Materiaux.toon(couleur.darkened(0.1)),
		Vector3(0.0, 0.4, -0.55))
	queue.rotation_degrees = Vector3(-70.0, 0.0, 0.0)
	Materiaux.mesh(_racine, Materiaux.sphere(0.06), Materiaux.emissif(Identite.OR, 2.0),
		Vector3(0.0, 0.62, -0.72), Vector3.ONE, false) # lueur au bout de la queue
	for cote: float in [-1.0, 1.0]:
		Materiaux.mesh(_racine, Materiaux.sphere(0.12), Materiaux.toon(Color.WHITE),
			Vector3(cote * 0.16, 0.6, 0.32), Vector3.ONE, false)
		Materiaux.mesh(_racine, Materiaux.sphere(0.055), Materiaux.toon(Identite.CONTOUR),
			Vector3(cote * 0.16, 0.6, 0.42), Vector3.ONE, false)
	Materiaux.mesh(_racine, Materiaux.sphere(0.14), Materiaux.toon(couleur.lightened(0.2)),
		Vector3(0.0, 0.45, 0.4), Vector3.ONE, false)


func _aile(cote: float) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = Vector3(cote * 0.3, 0.65, -0.1)
	_racine.add_child(pivot)
	var membrane := PrismMesh.new()
	membrane.size = Vector3(0.7, 0.5, 0.06)
	# Membrane translucide lumineuse : le dragon brille dans la nuit.
	var mi := Materiaux.mesh(pivot, membrane, Materiaux.verre(couleur.lightened(0.2), 0.55, 1.1),
		Vector3(cote * 0.4, 0.15, 0.0))
	mi.rotation_degrees = Vector3(0.0, 0.0, cote * -20.0)
	return pivot


# ---------------------------------------------------------------- animation

func _process(delta: float) -> void:
	_t += delta
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
	# Hoverboard : lévitation + inclinaison dans les virages.
	if _planche != null:
		_planche.position.y = 0.12 + sin(_t * 4.0) * 0.04
		_planche.rotation.z = sin(_t * 3.0) * 0.06
	# La crête-lumière flotte et tourne doucement.
	if _crete != null:
		_crete.position.y = 1.35 + sin(_t * 3.0) * 0.05
		_crete.rotation.y = _t * 1.2
	# Le pan d'écharpe se soulève quand on court.
	if _pan_echarpe != null:
		_pan_echarpe.rotation.x = deg_to_rad(-25.0) - (sin(_t * 9.0) * 0.25 + 0.5) * (0.6 if en_marche else 0.08)
	# Battement d'ailes du dragon.
	if _aile_g != null:
		var bat := sin(_t * 9.0) * 0.6
		_aile_g.rotation.z = 0.3 + bat
		_aile_d.rotation.z = -0.3 - bat
	# Flash d'impact : émission blanche qui retombe.
	if _flash > 0.0 and _mat_corps != null:
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


## 0 = pas de bulle ; sinon opacité relative.
func montrer_bulle(force: float, teinte: Color) -> void:
	_bulle.visible = force > 0.0
	if force > 0.0:
		_mat_bulle.albedo_color = Color(teinte.r, teinte.g, teinte.b, 0.22 * force)
		_mat_bulle.emission = teinte

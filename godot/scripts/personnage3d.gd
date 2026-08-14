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
## Les héros au style des PLANCHES pro (Écran Personnages / Home) :
## des enfants héroïques à grosse tête expressive, cheveux en mèches,
## sweat à capuche marqué d'une lettre, short et baskets — rendu toon à
## gros contours, adapté de la direction artistique fournie par Camille.
##
## `rarete`/`role`/`descr` : la carte d'identité affichée. `stats` : les
## VRAIS modificateurs de jeu (vitesse ×, énergie max, portée d'onde).
## `cheveux`/`coiffure`/`accessoire`/`lettre` : l'apparence signature.
const PEAU := Color(1.0, 0.82, 0.64)
const FICHES := {
	"Max": {"couleur": Identite.TEINTE_MAX, "cheveux": Color(0.36, 0.22, 0.12),
		"coiffure": "meches", "lettre": "M", "accessoire": "",
		"variantes": [Identite.TEINTE_MAX, Identite.CYAN, Identite.OR, Identite.VERT],
		"rarete": "Épique", "role": "Aventurier",
		"descr": "Curieux et courageux, prêt à relever tous les défis !",
		"stats": {"vitesse": 1.0, "energie": 100.0, "portee": 0.0}},
	"Zep": {"couleur": Identite.TEINTE_ZEP, "cheveux": Color(0.91, 0.45, 0.17),
		"coiffure": "meches", "lettre": "Z", "accessoire": "lunettes",
		"variantes": [Identite.TEINTE_ZEP, Identite.MAGENTA, Identite.BLEU, Identite.ORANGE],
		"rarete": "Rare", "role": "Fusée",
		"descr": "Lunettes d'aviateur vissées : le plus rapide, mais fragile !",
		"stats": {"vitesse": 1.08, "energie": 85.0, "portee": 0.0}},
	"Nova": {"couleur": Identite.TEINTE_NOVA, "cheveux": Color(0.95, 0.82, 0.42),
		"coiffure": "long", "lettre": "N", "accessoire": "",
		"variantes": [Identite.TEINTE_NOVA, Identite.VERT, Identite.VIOLET, Identite.ROUGE],
		"rarete": "Rare", "role": "Étoile guide",
		"descr": "Calme et précise : son onde porte plus loin que les autres.",
		"stats": {"vitesse": 0.97, "energie": 100.0, "portee": 0.5}},
	"Ficelle": {"couleur": Identite.TEINTE_FICELLE, "cheveux": Color(0.96, 0.45, 0.68),
		"coiffure": "couettes", "lettre": "F", "accessoire": "casque_audio",
		"variantes": [Identite.TEINTE_FICELLE, Identite.ORANGE, Identite.CYAN, Identite.CREME],
		"rarete": "Légendaire", "role": "Gardienne",
		"descr": "Couettes roses et casque audio : lente, mais très endurante.",
		"stats": {"vitesse": 0.94, "energie": 120.0, "portee": 0.0}},
}

## LES ESPÈCES DE DRAGONS à collectionner (Sanctuaire) : du commun au
## mythique. `poids` = probabilité relative à l'éclosion d'un œuf.
## `rarete` : 0 commun, 1 rare, 2 épique, 3 légendaire, 4 mythique.
const ESPECES := {
	"Lueur": {"couleur": Color(0.45, 0.82, 0.55), "rarete": 0, "poids": 40},
	"Braise": {"couleur": Identite.ORANGE, "rarete": 1, "poids": 22},
	"Givre": {"couleur": Identite.CYAN, "rarete": 1, "poids": 22},
	"Orage": {"couleur": Identite.VIOLET, "rarete": 2, "poids": 10},
	"Solaire": {"couleur": Identite.OR, "rarete": 3, "poids": 5},
	"Éclipse": {"couleur": Identite.MAGENTA, "rarete": 4, "poids": 1},
}
const NOMS_RARETES := ["Commun", "Rare", "Épique", "Légendaire", "Mythique"]

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
var _pied_g: Node3D
var _pied_d: Node3D
var _bras_g: Node3D
var _bras_d: Node3D
var _aile_g: Node3D
var _aile_d: Node3D
var _crete: Node3D               ## (héritage : plus construit depuis les planches)
var _anneau: MeshInstance3D
var _bulle: MeshInstance3D
var _mat_bulle: StandardMaterial3D
var _eveil := 0                  ## niveau d'Éveil affiché (0..3)
var _echelle_base := Vector3.ONE ## grossit avec l'Éveil (squash la préserve)
var _anneaux_eveil: Array = []   ## anneaux au sol, un par niveau
var _ailes_lumiere: Array = []   ## ailes de lumière du niveau 3


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
		_nom_label = Label3D.new()
		_nom_label.text = etiquette
		_nom_label.pixel_size = 0.0022
		_nom_label.font_size = 130
		_nom_label.outline_size = 34
		_nom_label.modulate = Color(1.0, 1.0, 1.0, 0.95)
		_nom_label.outline_modulate = Identite.CONTOUR
		_nom_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_nom_label.no_depth_test = true
		_nom_label.position = Vector3(0.0, 1.95, 0.0)
		add_child(_nom_label)


var _nom_label: Label3D        ## étiquette flottante (masquable au lobby)


## Montre ou cache l'étiquette de nom (l'accueil du lobby s'en passe).
func montrer_nom(oui: bool) -> void:
	if _nom_label != null:
		_nom_label.visible = oui


# ---------------------------------------------------------------- Lumin

## L'ENFANT HÉROÏQUE des planches : grosse tête expressive, mèches de
## cheveux, sweat à capuche marqué d'une lettre, short, baskets.
func _construire_lumin(fiche: Dictionary) -> void:
	var peau := Materiaux.toon(PEAU)
	var cheveux: Color = fiche.get("cheveux", Color(0.36, 0.22, 0.12))
	var mat_cheveux := Materiaux.toon(cheveux)
	var short := Materiaux.toon(Color(0.13, 0.16, 0.28))
	_mat_corps = Materiaux.toon(couleur)

	# — Baskets (blanc + empeigne à la couleur du héros) et jambes —
	_pied_g = _basket(-1.0)
	_pied_d = _basket(1.0)
	for cote: float in [-1.0, 1.0]:
		Materiaux.mesh(_racine, Materiaux.cylindre(0.05, 0.22), peau,
			Vector3(cote * 0.13, 0.28, 0.0), Vector3.ONE, false)
	# — Short sombre —
	Materiaux.mesh(_racine, Materiaux.sphere(0.2), short,
		Vector3(0.0, 0.44, 0.0), Vector3(1.0, 0.72, 0.82))
	# — Sweat à capuche (la teinte du héros / de la tenue) —
	Materiaux.mesh(_racine, Materiaux.sphere(0.23), _mat_corps,
		Vector3(0.0, 0.68, 0.0), Vector3(1.0, 1.12, 0.82))
	# Capuche roulée derrière la nuque.
	var capuche := Materiaux.mesh(_racine, Materiaux.tore(0.14, 0.055), Materiaux.toon(couleur.darkened(0.18)),
		Vector3(0.0, 0.9, -0.08))
	capuche.rotation_degrees = Vector3(64.0, 0.0, 0.0)
	# Lettre du héros sur la poitrine (le « M » de la planche).
	var lettre := Label3D.new()
	lettre.text = str(fiche.get("lettre", etiquette.left(1)))
	lettre.font_size = 220
	lettre.outline_size = 40
	lettre.pixel_size = 0.001
	lettre.modulate = Identite.CREME
	lettre.outline_modulate = couleur.darkened(0.45)
	lettre.position = Vector3(0.0, 0.7, 0.195)
	lettre.no_depth_test = false
	_racine.add_child(lettre)
	# — Bras (manches) + mains —
	_bras_g = _bras(-1.0)
	_bras_d = _bras(1.0)
	# — Tête : grosse, ronde, expressive —
	Materiaux.mesh(_racine, Materiaux.sphere(0.27), peau,
		Vector3(0.0, 1.12, 0.0), Vector3(1.0, 0.96, 0.94))
	for cote: float in [-1.0, 1.0]:
		Materiaux.mesh(_racine, Materiaux.sphere(0.05), peau,
			Vector3(cote * 0.26, 1.1, 0.0), Vector3.ONE, false)
	# Yeux : grands, blancs, iris chaud, éclat de vie (planche) — posés en
	# avant de la surface du crâne pour rester lisibles.
	for cote: float in [-1.0, 1.0]:
		Materiaux.mesh(_racine, Materiaux.sphere(0.075), Materiaux.toon(Color.WHITE),
			Vector3(cote * 0.105, 1.12, 0.225), Vector3(1.0, 1.15, 0.6), false)
		Materiaux.mesh(_racine, Materiaux.sphere(0.042), Materiaux.toon(Color(0.32, 0.19, 0.1)),
			Vector3(cote * 0.1, 1.12, 0.265), Vector3.ONE, false)
		Materiaux.mesh(_racine, Materiaux.sphere(0.018), Materiaux.toon(Color.WHITE),
			Vector3(cote * 0.08, 1.15, 0.295), Vector3.ONE, false)
		# Sourcil marqué.
		var sourcil := BoxMesh.new()
		sourcil.size = Vector3(0.1, 0.025, 0.03)
		var s := Materiaux.mesh(_racine, sourcil, mat_cheveux,
			Vector3(cote * 0.105, 1.23, 0.245), Vector3.ONE, false)
		s.rotation_degrees = Vector3(0.0, 0.0, cote * -8.0)
	# Nez + sourire.
	Materiaux.mesh(_racine, Materiaux.sphere(0.024), Materiaux.toon(PEAU.darkened(0.12)),
		Vector3(0.0, 1.07, 0.275), Vector3.ONE, false)
	var sourire := BoxMesh.new()
	sourire.size = Vector3(0.09, 0.016, 0.02)
	var bouche := Materiaux.mesh(_racine, sourire, Materiaux.toon(Color(0.45, 0.2, 0.15)),
		Vector3(0.02, 1.0, 0.27), Vector3.ONE, false)
	bouche.rotation_degrees = Vector3(0.0, 0.0, 7.0)
	# — Coiffure signature —
	_construire_coiffure(str(fiche.get("coiffure", "meches")), mat_cheveux)
	# — Accessoire signature —
	match str(fiche.get("accessoire", "")):
		"lunettes":
			_accessoire_lunettes()
		"casque_audio":
			_accessoire_casque()
	# Halo fresnel discret : la lumière d'Iluminia nimbe la silhouette.
	Materiaux.mesh(_racine, Materiaux.sphere(0.5), Nuanceurs.fresnel(couleur.lightened(0.3), 0.45),
		Vector3(0.0, 0.8, 0.0), Vector3(0.72, 1.55, 0.62), false)


## Basket de la planche : semelle blanche, empeigne colorée, lacets clairs.
func _basket(cote: float) -> Node3D:
	var pied := Node3D.new()
	pied.position = Vector3(cote * 0.14, 0.0, 0.0)
	_racine.add_child(pied)
	Materiaux.mesh(pied, Materiaux.sphere(0.1), Materiaux.toon(Color(0.94, 0.94, 0.96)),
		Vector3(0.0, 0.06, 0.03), Vector3(1.0, 0.55, 1.55))
	Materiaux.mesh(pied, Materiaux.sphere(0.085), Materiaux.toon(couleur.darkened(0.05)),
		Vector3(0.0, 0.1, 0.0), Vector3(1.0, 0.7, 1.35), false)
	Materiaux.mesh(pied, Materiaux.sphere(0.04), Materiaux.toon(Color(0.94, 0.94, 0.96)),
		Vector3(0.0, 0.12, 0.1), Vector3(1.2, 0.5, 1.0), false)
	return pied


## Bras-manche + main, pivotés à l'épaule (balancés en course).
func _bras(cote: float) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = Vector3(cote * 0.21, 0.84, 0.0)
	_racine.add_child(pivot)
	var manche := Materiaux.mesh(pivot, Materiaux.cylindre(0.055, 0.24), _mat_corps,
		Vector3(cote * 0.03, -0.12, 0.0), Vector3.ONE, false)
	manche.rotation_degrees = Vector3(0.0, 0.0, cote * -12.0)
	Materiaux.mesh(pivot, Materiaux.sphere(0.055), Materiaux.toon(PEAU),
		Vector3(cote * 0.06, -0.26, 0.0), Vector3.ONE, false)
	return pivot


## Coiffures des planches : mèches en épis, cheveux longs, couettes.
func _construire_coiffure(coiffure: String, mat: Material) -> void:
	# Calotte commune qui épouse le crâne.
	Materiaux.mesh(_racine, Materiaux.sphere(0.28), mat,
		Vector3(0.0, 1.19, -0.03), Vector3(1.03, 0.82, 1.0))
	# Frange en petites boules.
	for f in 3:
		Materiaux.mesh(_racine, Materiaux.sphere(0.075), mat,
			Vector3(-0.1 + f * 0.1, 1.31, 0.18), Vector3.ONE, false)
	match coiffure:
		"meches":
			# Épis dressés (le Max de la planche).
			var epis: Array = [
				[Vector3(0.0, 1.42, 0.02), Vector3(18.0, 0.0, 6.0), 0.2],
				[Vector3(-0.11, 1.4, -0.04), Vector3(10.0, 0.0, 32.0), 0.17],
				[Vector3(0.11, 1.39, -0.02), Vector3(12.0, 0.0, -30.0), 0.18],
				[Vector3(0.02, 1.38, -0.14), Vector3(-26.0, 0.0, -6.0), 0.16],
				[Vector3(-0.06, 1.36, 0.12), Vector3(30.0, 0.0, 10.0), 0.14],
			]
			for e: Array in epis:
				var epi := Materiaux.mesh(_racine, Materiaux.cone(0.075, float(e[2])), mat,
					e[0], Vector3.ONE, false)
				epi.rotation_degrees = e[1]
		"long":
			# Chevelure qui tombe dans le dos + mèches sur les épaules (Nova).
			Materiaux.mesh(_racine, Materiaux.sphere(0.2), mat,
				Vector3(0.0, 0.95, -0.16), Vector3(1.0, 1.7, 0.6))
			for cote: float in [-1.0, 1.0]:
				Materiaux.mesh(_racine, Materiaux.sphere(0.08), mat,
					Vector3(cote * 0.22, 0.95, -0.02), Vector3(1.0, 1.9, 1.0), false)
			# Barrette étoile dorée.
			Materiaux.mesh(_racine, Materiaux.sphere(0.045), Materiaux.emissif(Identite.OR, 1.4),
				Vector3(0.17, 1.32, 0.13), Vector3.ONE, false)
		"couettes":
			# Deux couettes hautes qui rebondissent (Ficelle).
			for cote: float in [-1.0, 1.0]:
				Materiaux.mesh(_racine, Materiaux.sphere(0.1), mat,
					Vector3(cote * 0.26, 1.36, -0.04), Vector3.ONE)
				var pointe := Materiaux.mesh(_racine, Materiaux.cone(0.07, 0.2), mat,
					Vector3(cote * 0.32, 1.24, -0.06), Vector3.ONE, false)
				pointe.rotation_degrees = Vector3(0.0, 0.0, cote * 148.0)


## Lunettes d'aviateur remontées sur le front (Zep).
func _accessoire_lunettes() -> void:
	var sangle := Materiaux.mesh(_racine, Materiaux.tore(0.27, 0.025),
		Materiaux.toon(Color(0.25, 0.2, 0.16)), Vector3(0.0, 1.26, 0.0), Vector3(1.0, 1.0, 1.0), false)
	sangle.rotation_degrees = Vector3(78.0, 0.0, 0.0)
	for cote: float in [-1.0, 1.0]:
		var verre := Materiaux.mesh(_racine, Materiaux.tore(0.06, 0.022),
			Materiaux.toon(Identite.OR_SOMBRE), Vector3(cote * 0.09, 1.31, 0.21))
		verre.rotation_degrees = Vector3(72.0, 0.0, 0.0)
		Materiaux.mesh(_racine, Materiaux.sphere(0.05), Materiaux.verre(Identite.CYAN, 0.5, 1.0),
			Vector3(cote * 0.09, 1.31, 0.21), Vector3(1.0, 1.0, 0.5), false)


## Casque audio rose-violet (Ficelle).
func _accessoire_casque() -> void:
	var arceau := Materiaux.mesh(_racine, Materiaux.tore(0.28, 0.03),
		Materiaux.toon(Identite.VIOLET), Vector3(0.0, 1.16, 0.0), Vector3.ONE, false)
	arceau.rotation_degrees = Vector3(0.0, 0.0, 90.0)
	for cote: float in [-1.0, 1.0]:
		Materiaux.mesh(_racine, Materiaux.sphere(0.08), Materiaux.toon(Identite.VIOLET),
			Vector3(cote * 0.27, 1.1, 0.0), Vector3(0.6, 1.0, 1.0))
		Materiaux.mesh(_racine, Materiaux.sphere(0.03), Materiaux.emissif(Identite.CYAN, 1.6),
			Vector3(cote * 0.31, 1.1, 0.0), Vector3.ONE, false)


# ---------------------------------------------------------------- dragon

## Le bébé dragon-lumière : mêmes rondeurs, membranes et cornes émissives.
func _construire_dragon() -> void:
	_mat_corps = Materiaux.toon(couleur)
	Materiaux.mesh(_racine, Materiaux.sphere(0.42), _mat_corps,
		Vector3(0.0, 0.45, 0.0), Vector3(1.0, 0.95, 1.1))
	# Halo fresnel : le dragon-lumière irradie, on le repère de loin.
	Materiaux.mesh(_racine, Materiaux.sphere(0.5), Nuanceurs.fresnel(couleur.lightened(0.35), 1.5),
		Vector3(0.0, 0.45, 0.0), Vector3(1.0, 0.95, 1.1), false)
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
	# Pieds qui trottinent, bras qui se balancent en opposition.
	if _pied_g != null:
		var pas := sin(_t * 14.0) * (0.16 if en_marche else 0.0)
		_pied_g.position.z = pas
		_pied_d.position.z = -pas
	if _bras_g != null:
		var balancier := sin(_t * 14.0) * (0.7 if en_marche else 0.05)
		_bras_g.rotation.x = -balancier
		_bras_d.rotation.x = balancier
	# Anneaux d'Éveil qui tournent, ailes de lumière qui battent.
	for i in _anneaux_eveil.size():
		var anneau_eveil: MeshInstance3D = _anneaux_eveil[i]
		anneau_eveil.rotation.y = _t * (0.8 + 0.4 * i) * (1.0 if i % 2 == 0 else -1.0)
	for i in _ailes_lumiere.size():
		var pivot_aile: Node3D = _ailes_lumiere[i]
		var cote_aile := -1.0 if i == 0 else 1.0
		pivot_aile.rotation.z = cote_aile * (0.12 + (sin(_t * 6.0) * 0.5 + 0.5) * 0.3)
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


## Squash & stretch : écrasé à l'impact, puis retour élastique
## (vers l'échelle d'Éveil courante, pas vers 1 : l'évolution se garde).
func squash(force := 0.25) -> void:
	_racine.scale = _echelle_base * Vector3(1.0 + force, 1.0 - force, 1.0 + force)
	var tw := create_tween()
	tw.tween_property(_racine, "scale", _echelle_base, 0.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## L'ÉVEIL rend l'évolution VISIBLE : le Lumin grandit, gagne un anneau de
## lumière au sol par niveau, sa crête s'amplifie… et au niveau 3, des
## AILES DE LUMIÈRE se déploient dans son dos.
func fixer_eveil(n: int) -> void:
	n = clampi(n, 0, 3)
	if n == _eveil:
		return
	_eveil = n
	_echelle_base = Vector3.ONE * (1.0 + 0.08 * n)
	_racine.scale = _echelle_base
	squash(0.3) # petit pop de transformation
	if _crete != null:
		_crete.scale = Vector3.ONE * (1.0 + 0.25 * n)
	# Anneaux d'Éveil au sol (un par niveau, rayons croissants).
	for a in _anneaux_eveil:
		a.queue_free()
	_anneaux_eveil = []
	for i in n:
		var anneau := Materiaux.mesh(self, Materiaux.tore(0.62 + 0.16 * i, 0.035),
			Materiaux.emissif(couleur.lightened(0.25), 1.6 + 0.4 * i),
			Vector3(0.0, 0.04 + 0.02 * i, 0.0), Vector3.ONE, false)
		_anneaux_eveil.append(anneau)
	# Ailes de lumière (niveau 3) : membranes translucides dans le dos.
	if n >= 3 and _ailes_lumiere.is_empty():
		for cote: float in [-1.0, 1.0]:
			var pivot := Node3D.new()
			pivot.position = Vector3(cote * 0.24, 0.9, -0.24)
			_racine.add_child(pivot)
			var membrane := PrismMesh.new()
			membrane.size = Vector3(0.85, 0.62, 0.05)
			var mi := Materiaux.mesh(pivot, membrane, Materiaux.verre(couleur.lightened(0.35), 0.5, 1.8),
				Vector3(cote * 0.45, 0.2, -0.05))
			mi.rotation_degrees = Vector3(0.0, 0.0, cote * -24.0)
			_ailes_lumiere.append(pivot)
	elif n < 3:
		for aile in _ailes_lumiere:
			aile.queue_free()
		_ailes_lumiere = []


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

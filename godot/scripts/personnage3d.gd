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
		"coiffure": "meches", "lettre": "M", "accessoire": "", "effet": "etincelles",
		"variantes": [Identite.TEINTE_MAX, Identite.CYAN, Identite.OR, Identite.VERT],
		"rarete": "Épique", "role": "Aventurier",
		"descr": "Curieux et courageux, prêt à relever tous les défis !",
		"stats": {"vitesse": 1.0, "energie": 100.0, "portee": 0.0}},
	"Zep": {"couleur": Identite.TEINTE_ZEP, "cheveux": Color(0.91, 0.45, 0.17),
		"coiffure": "meches", "lettre": "Z", "accessoire": "lunettes", "effet": "eclairs",
		"variantes": [Identite.TEINTE_ZEP, Identite.MAGENTA, Identite.BLEU, Identite.ORANGE],
		"rarete": "Rare", "role": "Fusée",
		"descr": "Lunettes d'aviateur vissées : le plus rapide, mais fragile !",
		"stats": {"vitesse": 1.08, "energie": 85.0, "portee": 0.0}},
	"Nova": {"couleur": Identite.TEINTE_NOVA, "cheveux": Color(0.95, 0.82, 0.42),
		"coiffure": "long", "lettre": "N", "accessoire": "", "effet": "etoiles",
		"variantes": [Identite.TEINTE_NOVA, Identite.VERT, Identite.VIOLET, Identite.ROUGE],
		"rarete": "Rare", "role": "Étoile guide",
		"descr": "Calme et précise : son onde porte plus loin que les autres.",
		"stats": {"vitesse": 0.97, "energie": 100.0, "portee": 0.5}},
	"Ficelle": {"couleur": Identite.TEINTE_FICELLE, "cheveux": Color(0.96, 0.45, 0.68),
		"coiffure": "couettes", "lettre": "F", "accessoire": "casque_audio", "effet": "braises",
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

## Palier d'ÉVOLUTION PERMANENTE du héros (la Puissance, 1..5) — à fixer
## AVANT l'ajout à l'arbre. Chaque palier ajoute un attribut visible
## partout (lobby ET match) : 2 bracelets de lumière, 3 cape d'éclat,
## 4 aura au sol, 5 FORME ÉCLAT (couronne, grande cape, effets permanents).
var puissance := 1
var _effet_type := ""            ## effet signature du héros (fiche)
var _effet_delai := 0.0          ## cadence d'émission
var _lunes: Array = []           ## les lunes en orbite de Nova
var _aura: MeshInstance3D        ## aura du palier 4
var _yeux: Array = []            ## groupes d'yeux (clignement)
var _clign_delai := 2.0
var _clign_reste := 0.0


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
	# avant de la surface du crâne, groupés pour pouvoir CLIGNER.
	for cote: float in [-1.0, 1.0]:
		var oeil := Node3D.new()
		oeil.position = Vector3(cote * 0.105, 1.12, 0.0)
		_racine.add_child(oeil)
		_yeux.append(oeil)
		Materiaux.mesh(oeil, Materiaux.sphere(0.075), Materiaux.toon(Color.WHITE),
			Vector3(0.0, 0.0, 0.225), Vector3(1.0, 1.15, 0.6), false)
		Materiaux.mesh(oeil, Materiaux.sphere(0.042), Materiaux.toon(Color(0.32, 0.19, 0.1)),
			Vector3(-cote * 0.005, 0.0, 0.265), Vector3.ONE, false)
		Materiaux.mesh(oeil, Materiaux.sphere(0.018), Materiaux.toon(Color.WHITE),
			Vector3(-cote * 0.025, 0.03, 0.295), Vector3.ONE, false)
		# Sourcil marqué (hors du groupe : il ne cligne pas).
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
	# Détails d'identité, effet signature, attributs d'évolution.
	_details_signature()
	_construire_effet(str(fiche.get("effet", "etincelles")))
	_appliquer_evolution()


## Les VÊTEMENTS SIGNATURES : chaque héros a SES détails (planche).
func _details_signature() -> void:
	match etiquette:
		"Max": # Fermeture éclair et cordons de capuche.
			var zip := BoxMesh.new()
			zip.size = Vector3(0.02, 0.14, 0.015)
			Materiaux.mesh(_racine, zip, Materiaux.toon(couleur.darkened(0.4)),
				Vector3(0.0, 0.55, 0.185), Vector3.ONE, false)
			for cote: float in [-1.0, 1.0]:
				Materiaux.mesh(_racine, Materiaux.cylindre(0.012, 0.09), Materiaux.toon(Identite.CREME),
					Vector3(cote * 0.06, 0.8, 0.18), Vector3.ONE, false)
				Materiaux.mesh(_racine, Materiaux.sphere(0.018), Materiaux.toon(Identite.OR),
					Vector3(cote * 0.06, 0.75, 0.18), Vector3.ONE, false)
		"Zep": # Écharpe au vent + réacteurs aux baskets.
			var pan := BoxMesh.new()
			pan.size = Vector3(0.15, 0.34, 0.03)
			var echarpe := Materiaux.mesh(_racine, pan, Materiaux.toon(Identite.CREME),
				Vector3(0.06, 0.72, -0.22))
			echarpe.rotation_degrees = Vector3(-32.0, 8.0, 0.0)
			for pied: Node3D in [_pied_g, _pied_d]:
				Materiaux.mesh(pied, Materiaux.sphere(0.028), Materiaux.emissif(Identite.CYAN, 2.4),
					Vector3(0.0, 0.08, -0.15), Vector3.ONE, false)
		"Nova": # Jupe étoilée + diadème.
			var jupe := CylinderMesh.new()
			jupe.top_radius = 0.13
			jupe.bottom_radius = 0.24
			jupe.height = 0.16
			jupe.radial_segments = 16
			Materiaux.mesh(_racine, jupe, Materiaux.toon(couleur.lightened(0.25)),
				Vector3(0.0, 0.48, 0.0))
			var diademe := Materiaux.mesh(_racine, Materiaux.tore(0.1, 0.015),
				Materiaux.emissif(Identite.OR, 1.6), Vector3(0.0, 1.32, 0.1), Vector3.ONE, false)
			diademe.rotation_degrees = Vector3(64.0, 0.0, 0.0)
		"Ficelle": # Bretelles de salopette à boucles dorées.
			for cote: float in [-1.0, 1.0]:
				var bretelle := BoxMesh.new()
				bretelle.size = Vector3(0.05, 0.22, 0.018)
				var mi := Materiaux.mesh(_racine, bretelle, Materiaux.toon(couleur.darkened(0.35)),
					Vector3(cote * 0.09, 0.76, 0.18), Vector3.ONE, false)
				mi.rotation_degrees = Vector3(-8.0, 0.0, cote * -6.0)
				Materiaux.mesh(_racine, Materiaux.sphere(0.022), Materiaux.toon(Identite.OR),
					Vector3(cote * 0.09, 0.66, 0.195), Vector3.ONE, false)


## Les EFFETS SIGNATURES : une mécanique visuelle PROPRE à chaque héros —
## pas une simple recoloration. Max sème des étoiles qui tournoient, Zep
## crépite d'arcs électriques en zigzag, Nova est escortée par des lunes
## en orbite (et laisse un voile stellaire), Ficelle exhale des cœurs de
## braise qui montent en ondulant.
func _construire_effet(type: String) -> void:
	_effet_type = type
	if type == "etoiles":
		_construire_lunes()


## Les deux lunes de Nova : en orbite permanente, même à l'arrêt.
func _construire_lunes() -> void:
	for i in 2:
		var lune := Materiaux.mesh(_racine, Materiaux.sphere(0.05 if i == 0 else 0.035),
			Materiaux.emissif(Identite.CREME if i == 0 else Identite.VIOLET, 2.2),
			Vector3.ZERO, Vector3.ONE, false)
		_lunes.append(lune)


## Émission cadencée des effets signatures (dans le MONDE : ils traînent
## derrière le héros en mouvement).
func _emettre_effet() -> void:
	var monde := get_parent()
	if monde == null or not visible:
		return
	var e := scale.x # les effets suivent l'échelle d'affichage du héros
	match _effet_type:
		"etincelles": # Max : étoile d'or qui tournoie en retombant.
			var etoile := Node3D.new()
			for k in 2:
				var branche := BoxMesh.new()
				branche.size = Vector3(0.16, 0.035, 0.02) * e
				var mi := MeshInstance3D.new()
				mi.mesh = branche
				mi.material_override = Materiaux.emissif(Identite.OR, 2.6)
				mi.rotation_degrees = Vector3(0.0, 0.0, 90.0 * k + 45.0)
				etoile.add_child(mi)
			etoile.position = global_position + Vector3(randf_range(-0.2, 0.2) * e, 0.25 * e, randf_range(-0.2, 0.2) * e)
			monde.add_child(etoile)
			var tw := etoile.create_tween()
			tw.set_parallel(true)
			tw.tween_property(etoile, "rotation:y", TAU * 1.5, 0.55)
			tw.tween_property(etoile, "position:y", etoile.position.y + 0.5 * e, 0.55)
			tw.tween_property(etoile, "scale", Vector3.ONE * 0.05, 0.55).set_ease(Tween.EASE_IN)
			tw.chain().tween_callback(etoile.queue_free)
		"eclairs": # Zep : arc électrique en zigzag, flash bref.
			var arc := Node3D.new()
			var teinte := Identite.CYAN if randf() < 0.75 else Color.WHITE
			var p := Vector3.ZERO
			var zig := 1.0
			for k in 3:
				var seg := BoxMesh.new()
				seg.size = Vector3(0.022, 0.14, 0.022) * e
				var mi := MeshInstance3D.new()
				mi.mesh = seg
				mi.material_override = Materiaux.emissif(teinte, 3.0)
				mi.position = p + Vector3(zig * 0.045, 0.1, 0.0) * e
				mi.rotation_degrees = Vector3(0.0, randf_range(-30.0, 30.0), zig * 38.0)
				arc.add_child(mi)
				p = mi.position + Vector3(zig * 0.045, 0.1, 0.0) * e
				zig = -zig
			arc.position = global_position + Vector3(randf_range(-0.35, 0.35) * e, 0.5 * e, randf_range(-0.35, 0.35) * e)
			arc.rotation.y = randf_range(0.0, TAU)
			monde.add_child(arc)
			var tw := arc.create_tween()
			tw.tween_property(arc, "scale", Vector3.ONE * 0.4, 0.13).set_ease(Tween.EASE_IN)
			tw.tween_callback(arc.queue_free)
		"etoiles": # Nova : voile stellaire — motes qui flottent sur place.
			var mote := MeshInstance3D.new()
			mote.mesh = Materiaux.sphere(0.035 * e)
			mote.material_override = Materiaux.emissif(Identite.CREME, 2.2)
			mote.position = global_position + Vector3(randf_range(-0.3, 0.3) * e, randf_range(0.4, 1.1) * e, randf_range(-0.3, 0.3) * e)
			monde.add_child(mote)
			var tw := mote.create_tween()
			tw.set_parallel(true)
			tw.tween_property(mote, "position:y", mote.position.y + 0.4 * e, 1.1)
			tw.tween_property(mote, "scale", Vector3.ONE * 0.05, 1.1).set_ease(Tween.EASE_IN)
			tw.chain().tween_callback(mote.queue_free)
		"braises": # Ficelle : cœur de braise qui monte en ondulant.
			var coeur := Node3D.new()
			var mat := Materiaux.emissif(Identite.MAGENTA, 2.4)
			for cote: float in [-1.0, 1.0]:
				var lobe := MeshInstance3D.new()
				lobe.mesh = Materiaux.sphere(0.045 * e)
				lobe.material_override = mat
				lobe.position = Vector3(cote * 0.032 * e, 0.02 * e, 0.0)
				coeur.add_child(lobe)
			var pointe := MeshInstance3D.new()
			pointe.mesh = Materiaux.cone(0.055 * e, 0.09 * e)
			pointe.material_override = mat
			pointe.rotation_degrees = Vector3(180.0, 0.0, 0.0)
			pointe.position = Vector3(0.0, -0.03 * e, 0.0)
			coeur.add_child(pointe)
			coeur.position = global_position + Vector3(randf_range(-0.25, 0.25) * e, 0.6 * e, randf_range(-0.25, 0.25) * e)
			monde.add_child(coeur)
			var tw := coeur.create_tween()
			tw.set_parallel(true)
			tw.tween_property(coeur, "position:y", coeur.position.y + 0.85 * e, 0.9)
			tw.tween_property(coeur, "position:x", coeur.position.x + randf_range(-0.15, 0.15) * e, 0.9) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tw.tween_property(coeur, "scale", Vector3.ONE * 0.1, 0.9).set_ease(Tween.EASE_IN)
			tw.chain().tween_callback(coeur.queue_free)


## Les ATTRIBUTS D'ÉVOLUTION : le but visible de la progression — chaque
## palier de Puissance change le héros pour de bon.
func _appliquer_evolution() -> void:
	var p := clampi(puissance, 1, 5)
	if p >= 2:
		# Palier 2 : BRACELETS DE LUMIÈRE aux poignets.
		var cotes: Array = [-1.0, 1.0]
		for i in 2:
			var pivot: Node3D = [_bras_g, _bras_d][i]
			var bracelet := Materiaux.mesh(pivot, Materiaux.tore(0.065, 0.02),
				Materiaux.emissif(couleur.lightened(0.25), 1.8),
				Vector3(float(cotes[i]) * 0.05, -0.2, 0.0), Vector3.ONE, false)
			bracelet.rotation_degrees = Vector3(0.0, 0.0, 90.0)
	if p >= 3:
		# Palier 3 : CAPE D'ÉCLAT (grande à la Forme Éclat).
		var cape := BoxMesh.new()
		cape.size = Vector3(0.4, 0.78 if p >= 5 else 0.52, 0.045)
		var mi := Materiaux.mesh(_racine, cape,
			Materiaux.toon(couleur.darkened(0.35)),
			Vector3(0.0, 0.86 - cape.size.y / 2.0, -0.21))
		mi.rotation_degrees = Vector3(-8.0, 0.0, 0.0)
		# Doublure émissive : la cape porte la lumière du héros.
		var doublure := BoxMesh.new()
		doublure.size = Vector3(0.34, cape.size.y - 0.08, 0.012)
		Materiaux.mesh(mi, doublure, Materiaux.emissif(couleur.lightened(0.2), 0.7),
			Vector3(0.0, 0.0, 0.032), Vector3.ONE, false)
	if p >= 4:
		# Palier 4 : AURA AU SOL, en rotation lente.
		_aura = Materiaux.mesh(self, Materiaux.tore(0.52, 0.03),
			Materiaux.emissif(couleur.lightened(0.15), 1.5),
			Vector3(0.0, 0.05, 0.0), Vector3.ONE, false)
	if p >= 5:
		# Palier 5 — FORME ÉCLAT : couronne d'or, effets permanents.
		Materiaux.mesh(_racine, Materiaux.tore(0.13, 0.025), Materiaux.emissif(Identite.OR, 2.0),
			Vector3(0.0, 1.4, 0.0), Vector3.ONE, false)
		for i in 3:
			Materiaux.mesh(_racine, Materiaux.cone(0.03, 0.1), Materiaux.emissif(Identite.OR, 2.0),
				Vector3(-0.09 + i * 0.09, 1.47, 0.0), Vector3.ONE, false)


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
	var cap_avant := _cap
	_cap = lerp_angle(_cap, _cible_cap, minf(delta * 12.0, 1.0))
	_racine.rotation.y = _cap
	# GAME FEEL de course : penché vers l'avant quand on court, roulis
	# dans les virages (le personnage « prend » son virage).
	var pente_cible := 0.14 if en_marche else 0.0
	_racine.rotation.x = lerpf(_racine.rotation.x, pente_cible, minf(delta * 8.0, 1.0))
	var virage := clampf(wrapf(_cap - cap_avant, -PI, PI) / maxf(delta, 0.001) * 0.06, -0.3, 0.3)
	_racine.rotation.z = lerpf(_racine.rotation.z, -virage if en_marche else 0.0, minf(delta * 6.0, 1.0))
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
	# Effets signatures : émis en course, en permanence à la Forme Éclat.
	if _effet_type != "" and genre != "dragon" and (en_marche or puissance >= 5):
		var cadence: float = {"etincelles": 0.16, "eclairs": 0.09,
			"etoiles": 0.22, "braises": 0.28}.get(_effet_type, 0.2)
		_effet_delai -= delta
		if _effet_delai <= 0.0:
			_effet_delai = cadence
			_emettre_effet()
	# Les lunes de Nova orbitent en permanence, même à l'arrêt.
	for i in _lunes.size():
		var lune: MeshInstance3D = _lunes[i]
		var a := _t * (1.6 if i == 0 else -1.1) + i * PI
		lune.position = Vector3(cos(a) * 0.42, 0.95 + sin(_t * 2.0 + i) * 0.08, sin(a) * 0.42)
	# Clignement des yeux : la vie dans le regard.
	_clign_delai -= delta
	if _clign_delai <= 0.0:
		_clign_delai = randf_range(2.4, 4.6)
		_clign_reste = 0.11
	_clign_reste = maxf(_clign_reste - delta, 0.0)
	for oeil in _yeux:
		oeil.scale.y = 0.12 if _clign_reste > 0.0 else 1.0
	if _aura != null:
		_aura.rotation.y += delta * 0.8
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

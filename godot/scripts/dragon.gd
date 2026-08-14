class_name Dragon
extends Node3D
## Le bébé dragon de l'arène. Libre, il FUIT le chasseur le plus proche
## (trottinement à 5,5 u, panique à 2,6 u — toujours plus lent que les
## chasseurs) avec un biais vers le centre pour ne pas se coincer au bord.
## Porté, il se blottit dans les bras du porteur. Valeurs du spike Three.js
## (docs/mecaniques-arene.md), unités identiques (1 u = 1 m).

const RAYON_CONTACT := 1.1   ## « l'attraper = marcher dessus »
const DETECTION := 5.5       ## commence à trottiner à l'opposé
const PANIQUE := 2.6         ## fuite paniquée, petits bonds
const VITESSE_CALME := 2.0
const VITESSE_FUITE := 2.6   ## toujours plus lent que bots (3,2) et joueur (4,4)

## LA CAGNOTTE : porté, le dragon se charge de lumière (+8 pts/s, plafond
## +80). Déposer vite = sûr mais petit ; garder = gros mais risqué — et
## VOLER un dragon plein, c'est le jackpot. La stratégie de la partie.
const CAGNOTTE_PAR_SECONDE := 8.0
const CAGNOTTE_MAX := 80

var arene: Arene
var porteur: Chasseur = null
var visuel: Personnage3D
var cagnotte := 0        ## bonus accumulé, encaissé au dépôt (ou volé !)
var _acc_cagnotte := 0.0
var _label_cagnotte: Label3D
var _temps_libre := 0.0  ## le dragon s'essouffle après 8 s de fuite


var _balise: Node3D  ## colonne de lumière + flèche dorée : IMPOSSIBLE à rater


func _ready() -> void:
	visuel = Personnage3D.new()
	visuel.genre = "dragon"
	visuel.couleur = Color(0.45, 0.82, 0.55)
	visuel.scale = Vector3.ONE * 1.35 # l'objet de la convoitise se voit de loin
	add_child(visuel)
	# Balise du dragon libre : faisceau doré + flèche qui rebondit au-dessus.
	_balise = Node3D.new()
	add_child(_balise)
	var faisceau := CylinderMesh.new()
	faisceau.top_radius = 0.55
	faisceau.bottom_radius = 0.55
	faisceau.height = 5.0
	faisceau.radial_segments = 16
	faisceau.cap_top = false
	faisceau.cap_bottom = false
	Materiaux.mesh(_balise, faisceau, Materiaux.verre(Identite.OR, 0.22, 1.2),
		Vector3(0.0, 2.5, 0.0), Vector3.ONE, false)
	var fleche := Materiaux.mesh(_balise, Materiaux.cone(0.4, 0.7),
		Materiaux.emissif(Identite.OR, 2.2), Vector3(0.0, 2.6, 0.0), Vector3.ONE, false)
	fleche.rotation_degrees = Vector3(180.0, 0.0, 0.0)
	fleche.name = "Fleche"
	# La cagnotte flotte au-dessus du dragon porté : tout le monde la voit.
	_label_cagnotte = Label3D.new()
	_label_cagnotte.font_size = 96
	_label_cagnotte.outline_size = 26
	_label_cagnotte.pixel_size = 0.0022
	_label_cagnotte.modulate = Identite.OR
	_label_cagnotte.outline_modulate = Materiaux.COULEUR_CONTOUR
	_label_cagnotte.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label_cagnotte.no_depth_test = true
	_label_cagnotte.position = Vector3(0.0, 1.5, 0.0)
	_label_cagnotte.visible = false
	add_child(_label_cagnotte)


func pos2() -> Vector2:
	return Vector2(position.x, position.z)


func fixer_pos2(v: Vector2) -> void:
	position = Vector3(v.x, position.y, v.y)


func libre() -> bool:
	return porteur == null


func _process(delta: float) -> void:
	# Porté par un chasseur embusqué : caché avec lui (sauf pour l'écran
	# du joueur-porteur) — la boussole, elle, le pointe toujours.
	visible = porteur == null or porteur.est_joueur or not porteur.cache
	# La balise ne brille que quand le dragon est à prendre.
	_balise.visible = porteur == null
	if _balise.visible:
		var fleche := _balise.get_node("Fleche") as Node3D
		fleche.position.y = 2.6 + absf(sin(Time.get_ticks_msec() / 280.0)) * 0.4
		fleche.rotation.y += delta * 2.0
	if porteur != null:
		_temps_libre = 0.0
		# La cagnotte grossit tant qu'on le porte — la tension aussi.
		_acc_cagnotte += delta * CAGNOTTE_PAR_SECONDE
		cagnotte = mini(int(_acc_cagnotte), CAGNOTTE_MAX)
		_label_cagnotte.text = "+%d" % cagnotte
		_label_cagnotte.visible = cagnotte > 0
		# Dans les bras du porteur, légèrement devant lui, soulevé.
		var devant := porteur.pos2() + porteur.regard() * 0.55
		position = Vector3(devant.x, 0.55, devant.y)
		visuel.regarder(porteur.regard())
		visuel.en_marche = false
		return
	_label_cagnotte.visible = false
	position.y = 0.0
	_temps_libre += delta

	var proche := arene.chasseur_le_plus_proche(pos2(), true)
	if proche == null:
		visuel.en_marche = false
		return
	var d := pos2().distance_to(proche.pos2())
	if d < DETECTION:
		var fuite := (pos2() - proche.pos2()).normalized()
		# Biais vers le centre, d'autant plus fort qu'on approche du bord.
		var poids_centre := pos2().length() / Arene.RAYON_ARENE
		var dir := (fuite + (-pos2().normalized()) * poids_centre * 0.9).normalized()
		var v := VITESSE_FUITE if d < PANIQUE else VITESSE_CALME
		# Après 8 s de course, il s'essouffle : la capture arrive toujours.
		if _temps_libre > 8.0:
			v *= 0.7
		fixer_pos2(arene.borner(pos2() + dir * v * delta))
		visuel.regarder(dir)
		visuel.en_marche = true
		# Poussière de panique.
		if d < PANIQUE and randf() < 6.0 * delta:
			arene.fx.eclat_etoiles(pos2(), Color(0.75, 0.68, 0.55), 3)
	else:
		visuel.en_marche = false

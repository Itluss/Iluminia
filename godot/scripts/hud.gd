class_name HUD
extends CanvasLayer
## Interface cartoon, tactile d'abord : joystick virtuel flottant (moitié
## gauche de l'écran), trois gros boutons de compétences (min. 76 px),
## barres PV/XP « glossy », minimap circulaire en bas à droite, boussole
## vers le boss, compteurs de secrets et d'exploration, messages.

const CONTOUR := Color(0.13, 0.10, 0.16)
const FOND_PANNEAU := Color(0.16, 0.13, 0.22, 0.82)
const RAYON_JOYSTICK := 70.0

var joueur: Joueur
var monde: Monde
var vecteur_joystick := Vector2.ZERO

# Joystick flottant : apparaît là où le pouce se pose (moitié gauche).
var _doigt_joystick := -1
var _origine_joystick := Vector2.ZERO
var _pos_joystick := Vector2.ZERO

var _boutons: Array = []      ## recalculés chaque frame {centre, rayon, action, touche}
var _doigts_boutons := {}     ## doigt → action (état enfoncé)
var _message := ""
var _message_temps := 0.0
var _message_duree := 1.0
var _zone_courante := 0
var surface: Control


func _ready() -> void:
	surface = Surface.new()
	surface.hud = self
	surface.set_anchors_preset(Control.PRESET_FULL_RECT)
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(surface)


func message(texte: String, duree := 2.0) -> void:
	_message = texte
	_message_temps = duree
	_message_duree = duree


func _process(delta: float) -> void:
	if _message_temps > 0.0:
		_message_temps -= delta
	if monde != null and joueur != null:
		# Annonce le passage d'une zone à l'autre.
		var z := monde.zone_de(joueur.position)
		if z != _zone_courante:
			_zone_courante = z
			message("— %s (niveau %d) —" % [Monde.NOMS_ZONES[z - 1], Monde.NIVEAUX_ZONES[z - 1]], 2.2)
	_boutons = _calculer_boutons()
	surface.queue_redraw()


## Positions des trois boutons : arc au pouce droit, à gauche de la minimap.
func _calculer_boutons() -> Array:
	var t := surface.size
	if joueur == null:
		return []
	return [
		{"centre": Vector2(t.x - 332.0, t.y - 70.0), "rayon": 40.0, "action": "tourbillon", "touche": "E",
			"cd": joueur.cd_tourbillon, "cd_max": Joueur.CD_TOURBILLON, "teinte": Color(0.45, 0.75, 1.0)},
		{"centre": Vector2(t.x - 238.0, t.y - 108.0), "rayon": 40.0, "action": "nova", "touche": "R",
			"cd": joueur.cd_nova, "cd_max": Joueur.CD_NOVA, "teinte": Color(1.0, 0.75, 0.3)},
		{"centre": Vector2(t.x - 144.0, t.y - 174.0), "rayon": 44.0, "action": "roulade", "touche": "␣",
			"cd": joueur.cd_roulade, "cd_max": Joueur.CD_ROULADE, "teinte": Color(0.6, 1.0, 0.6)},
	]


# ---------------------------------------------------------------- entrées tactiles

func _input(event: InputEvent) -> void:
	if surface == null:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			var action := _bouton_sous(event.position)
			if action != "":
				_doigts_boutons[event.index] = action
				_declencher(action)
			elif event.position.x < surface.size.x * 0.5 and _doigt_joystick == -1:
				_doigt_joystick = event.index
				_origine_joystick = event.position
				_pos_joystick = event.position
				vecteur_joystick = Vector2.ZERO
		else:
			if event.index == _doigt_joystick:
				_doigt_joystick = -1
				vecteur_joystick = Vector2.ZERO
			_doigts_boutons.erase(event.index)
	elif event is InputEventScreenDrag and event.index == _doigt_joystick:
		_pos_joystick = event.position
		var v: Vector2 = (event.position - _origine_joystick) / RAYON_JOYSTICK
		if v.length() > 1.0:
			# Le socle suit le pouce quand on s'éloigne : joystick « flottant ».
			_origine_joystick = event.position - v.normalized() * RAYON_JOYSTICK
			v = v.normalized()
		vecteur_joystick = v


func _declencher(action: String) -> void:
	if joueur == null:
		return
	match action:
		"tourbillon":
			joueur.utiliser_tourbillon()
		"nova":
			joueur.utiliser_nova()
		"roulade":
			joueur.utiliser_roulade()


func _bouton_sous(pos: Vector2) -> String:
	for b in _boutons:
		if pos.distance_to(b.centre) <= b.rayon + 8.0:
			return b.action
	return ""


# ---------------------------------------------------------------- dessin

## Appelé par Surface._draw() : `c` est le canvas plein écran.
func _dessiner(c: Control) -> void:
	if joueur == null or monde == null:
		return
	var police := ThemeDB.fallback_font
	_dessiner_stats(c, police)
	_dessiner_boss(c, police)
	_dessiner_boutons(c, police)
	_dessiner_minimap(c)
	_dessiner_joystick(c)
	_dessiner_message(c, police)
	if not joueur.vivant:
		c.draw_rect(Rect2(Vector2.ZERO, c.size), Color(0.1, 0.0, 0.0, 0.35))


func _panneau(c: Control, rect: Rect2) -> void:
	# Ombre portée + fond + gros contour : style panneau cartoon.
	c.draw_rect(Rect2(rect.position + Vector2(3.0, 4.0), rect.size), Color(0.0, 0.0, 0.0, 0.3))
	c.draw_rect(rect.grow(3.0), CONTOUR)
	c.draw_rect(rect, FOND_PANNEAU)


func _barre(c: Control, rect: Rect2, ratio: float, teinte: Color) -> void:
	c.draw_rect(rect.grow(3.0), CONTOUR)
	c.draw_rect(rect, Color(0.22, 0.18, 0.28))
	var largeur := maxf(rect.size.x * clampf(ratio, 0.0, 1.0), 0.0)
	if largeur > 0.5:
		c.draw_rect(Rect2(rect.position, Vector2(largeur, rect.size.y)), teinte)
		# Reflet « glossy » sur la moitié haute.
		c.draw_rect(Rect2(rect.position, Vector2(largeur, rect.size.y * 0.45)), Color(1.0, 1.0, 1.0, 0.25))


func _texte(c: Control, pos: Vector2, texte: String, taille: int, teinte: Color, centre := false) -> void:
	var police := ThemeDB.fallback_font
	var p := pos
	if centre:
		p.x -= police.get_string_size(texte, HORIZONTAL_ALIGNMENT_LEFT, -1, taille).x / 2.0
	c.draw_string_outline(police, p, texte, HORIZONTAL_ALIGNMENT_LEFT, -1, taille, 5, CONTOUR)
	c.draw_string(police, p, texte, HORIZONTAL_ALIGNMENT_LEFT, -1, taille, teinte)


func _dessiner_stats(c: Control, _police: Font) -> void:
	_panneau(c, Rect2(10.0, 10.0, 268.0, 118.0))
	# Pastille de niveau.
	c.draw_circle(Vector2(40.0, 44.0), 24.0, CONTOUR)
	c.draw_circle(Vector2(40.0, 44.0), 20.0, Color(1.0, 0.85, 0.3))
	_texte(c, Vector2(40.0, 51.0), str(joueur.niveau), 20, CONTOUR, true)
	# Barres PV et XP.
	_barre(c, Rect2(76.0, 24.0, 186.0, 22.0), joueur.pv / joueur.pv_max, Color(0.35, 0.8, 0.35))
	_texte(c, Vector2(169.0, 41.0), "%d / %d" % [int(ceil(joueur.pv)), int(joueur.pv_max)], 14, Color.WHITE, true)
	_barre(c, Rect2(76.0, 54.0, 186.0, 12.0), joueur.xp / joueur.xp_requise(), Color(0.72, 0.45, 1.0))
	# Ligne de statistiques et compteurs.
	_texte(c, Vector2(20.0, 90.0), "ATQ %d   DÉF %d" % [int(joueur.attaque_totale()), int(joueur.defense_totale())], 14, Color(1.0, 0.9, 0.7))
	_texte(c, Vector2(20.0, 112.0), "Orbes %d/%d    Exploré %d %%" % [monde.secrets_trouves, Monde.NB_SECRETS, int(monde.exploration_pourcent())], 14, Color(0.8, 0.9, 1.0))


func _dessiner_boss(c: Control, _police: Font) -> void:
	var b := monde.boss
	if b == null or not is_instance_valid(b):
		return
	# Barre de vie du boss quand il est en chasse.
	if b.etat == Ennemi.Etat.POURSUITE:
		var largeur := minf(c.size.x * 0.5, 420.0)
		var rect := Rect2((c.size.x - largeur) / 2.0, 18.0, largeur, 18.0)
		_barre(c, rect, b.pv / b.pv_max, Color(0.9, 0.25, 0.2))
		_texte(c, Vector2(c.size.x / 2.0, 14.0), "Dragon des Terres Brûlées", 15, Color(1.0, 0.75, 0.7), true)
	# Boussole : flèche pointant vers le boss depuis le bord du centre-écran.
	var centre := c.size / 2.0
	var dir := (b.position - joueur.position)
	var distance := dir.length()
	if distance < 200.0:
		return
	var d := dir.normalized()
	var base := centre + d * 120.0
	var pts := PackedVector2Array([
		base + d * 18.0,
		base + d.rotated(2.6) * 10.0,
		base + d.rotated(-2.6) * 10.0,
	])
	c.draw_colored_polygon(PackedVector2Array([
		base + d * 22.0, base + d.rotated(2.6) * 13.0, base + d.rotated(-2.6) * 13.0,
	]), CONTOUR)
	c.draw_colored_polygon(pts, Color(1.0, 0.45, 0.3))
	_texte(c, base + d * 34.0 + Vector2(0.0, 5.0), "%d m" % int(distance / 10.0), 12, Color(1.0, 0.6, 0.45), true)


func _dessiner_boutons(c: Control, _police: Font) -> void:
	for b in _boutons:
		var enfonce: bool = _doigts_boutons.values().has(b.action) or b.cd > 0.9 * b.cd_max
		var rayon: float = b.rayon * (0.92 if enfonce else 1.0)
		c.draw_circle(b.centre + Vector2(0.0, 4.0), rayon + 4.0, Color(0.0, 0.0, 0.0, 0.3))
		c.draw_circle(b.centre, rayon + 4.0, CONTOUR)
		c.draw_circle(b.centre, rayon, b.teinte if b.cd <= 0.0 else Color(0.35, 0.32, 0.42))
		c.draw_circle(b.centre + Vector2(0.0, -rayon * 0.35), rayon * 0.55, Color(1.0, 1.0, 1.0, 0.22))
		_icone_bouton(c, b)
		# Camembert + décompte pendant la recharge.
		if b.cd > 0.0:
			var frac: float = b.cd / b.cd_max
			var pts := PackedVector2Array([b.centre])
			var n := 24
			for i in n + 1:
				var ang := -PI / 2.0 + TAU * frac * float(i) / float(n)
				pts.append(b.centre + Vector2.from_angle(ang) * rayon)
			c.draw_colored_polygon(pts, Color(0.1, 0.08, 0.14, 0.55))
			_texte(c, b.centre + Vector2(0.0, 7.0), "%.1f" % b.cd, 18, Color.WHITE, true)
		else:
			_texte(c, b.centre + Vector2(0.0, b.rayon + 18.0), str(b.touche), 12, Color(1.0, 1.0, 1.0, 0.7), true)


func _icone_bouton(c: Control, b: Dictionary) -> void:
	var p: Vector2 = b.centre
	match b.action:
		"tourbillon":
			# Spirale de lames.
			for i in 3:
				var a0 := TAU * i / 3.0
				c.draw_arc(p, b.rayon * 0.55, a0, a0 + 1.6, 10, CONTOUR, 5.0)
		"nova":
			# Étoile à 5 branches.
			var pts := PackedVector2Array()
			for i in 10:
				var r: float = b.rayon * (0.62 if i % 2 == 0 else 0.28)
				pts.append(p + Vector2.from_angle(-PI / 2.0 + TAU * i / 10.0) * r)
			c.draw_colored_polygon(pts, CONTOUR)
		"roulade":
			# Flèche d'élan.
			c.draw_arc(p, b.rayon * 0.5, PI * 0.7, PI * 2.1, 12, CONTOUR, 5.0)
			var bout: Vector2 = p + Vector2.from_angle(PI * 2.1) * b.rayon * 0.5
			c.draw_colored_polygon(PackedVector2Array([
				bout + Vector2(6.0, -2.0), bout + Vector2(-4.0, -8.0), bout + Vector2(-2.0, 6.0),
			]), CONTOUR)


func _dessiner_minimap(c: Control) -> void:
	var centre := Vector2(c.size.x - 78.0, c.size.y - 78.0)
	var rayon := 62.0
	c.draw_circle(centre + Vector2(0.0, 4.0), rayon + 6.0, Color(0.0, 0.0, 0.0, 0.3))
	c.draw_circle(centre, rayon + 6.0, CONTOUR)
	var echelle := rayon / Monde.RAYON_MONDE
	for i in range(3, -1, -1):
		c.draw_circle(centre, Monde.RAYONS_ZONES[i] * echelle, Monde.COULEURS_SOL[i])
	# Ennemis (points sombres), boss (gros point orange), joueur (point blanc).
	for e in monde.ennemis:
		if is_instance_valid(e):
			c.draw_circle(centre + e.position * echelle, 1.6, Color(0.45, 0.1, 0.1, 0.8))
	if monde.boss != null and is_instance_valid(monde.boss):
		c.draw_circle(centre + monde.boss.position * echelle, 4.0, Color(1.0, 0.55, 0.15))
	var pj := centre + joueur.position * echelle
	c.draw_circle(pj, 4.5, CONTOUR)
	c.draw_circle(pj, 3.0, Color.WHITE)


func _dessiner_joystick(c: Control) -> void:
	if _doigt_joystick == -1:
		return
	c.draw_circle(_origine_joystick, RAYON_JOYSTICK + 4.0, Color(0.13, 0.10, 0.16, 0.35))
	c.draw_circle(_origine_joystick, RAYON_JOYSTICK, Color(1.0, 1.0, 1.0, 0.12))
	var pommeau := _origine_joystick + vecteur_joystick * (RAYON_JOYSTICK - 16.0)
	c.draw_circle(pommeau, 30.0, Color(0.13, 0.10, 0.16, 0.5))
	c.draw_circle(pommeau, 25.0, Color(1.0, 1.0, 1.0, 0.45))


func _dessiner_message(c: Control, _police: Font) -> void:
	if _message_temps <= 0.0:
		return
	var alpha := clampf(_message_temps / minf(_message_duree, 0.5), 0.0, 1.0)
	var pos := Vector2(c.size.x / 2.0, c.size.y * 0.24)
	var police := ThemeDB.fallback_font
	var taille := 24
	var largeur := police.get_string_size(_message, HORIZONTAL_ALIGNMENT_LEFT, -1, taille).x
	var p := pos - Vector2(largeur / 2.0, 0.0)
	c.draw_string_outline(police, p, _message, HORIZONTAL_ALIGNMENT_LEFT, -1, taille, 7, Color(0.13, 0.10, 0.16, alpha))
	c.draw_string(police, p, _message, HORIZONTAL_ALIGNMENT_LEFT, -1, taille, Color(1.0, 0.97, 0.9, alpha))


## Canvas plein écran : délègue tout le dessin au HUD parent.
class Surface extends Control:
	var hud = null

	func _draw() -> void:
		if hud != null:
			hud._dessiner(self)

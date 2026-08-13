class_name HUD
extends CanvasLayer
## Interface cartoon, tactile d'abord, de l'arène « Chasse au dragon » :
## panneau de QUESTION (grand, centré, décompte 6 s), panneau latéral des
## réponses pendant le jeu (choix modifiable, refus barrés), joystick
## virtuel flottant (moitié gauche), trois gros boutons de pouvoirs avec
## anneau de recharge, jauge d'énergie, chronos de manche et de match,
## indicateurs de bord d'écran (dragon et zones hors champ, avec distance),
## toasts pédagogiques et podium de fin de match.

const CONTOUR := Color(0.10, 0.08, 0.14)
const FOND_PANNEAU := Color(0.16, 0.13, 0.22, 0.9)
const RAYON_JOYSTICK := 70.0

var joueur: Chasseur
var arene: Arene
var vecteur_joystick := Vector2.ZERO

# Joystick flottant.
var _doigt_joystick := -1
var _origine_joystick := Vector2.ZERO

var _boutons: Array = []          ## boutons de pouvoirs {centre, rayon, action, …}
var _rects_reponses: Array = []   ## zones cliquables des réponses {rect, indice}
var _doigts_boutons := {}
var _refus := {}                  ## action → temps de secousse « denied »
var _toast := ""
var _toast_temps := 0.0
var _toast_pedago_delai := 0.0    ## anti-spam du toast pédagogique (20 s)
var _flash_mauvaise := 0.0
var surface: Control


func _ready() -> void:
	surface = Surface.new()
	surface.hud = self
	surface.set_anchors_preset(Control.PRESET_FULL_RECT)
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(surface)


# ---------------------------------------------------------------- événements

func sur_nouvelle_question() -> void:
	_flash_mauvaise = 0.0


func sur_mauvaise_reponse() -> void:
	_flash_mauvaise = 1.6


func sur_podium() -> void:
	pass # tout se dessine à partir de arene.etat


func toast(texte: String) -> void:
	_toast = texte
	_toast_temps = 3.0


## « Pousse le porteur pour lui voler le dragon ! » — max une fois / 20 s.
func toast_pedagogique() -> void:
	if _toast_pedago_delai > 0.0:
		return
	_toast_pedago_delai = 20.0
	toast("Pousse le porteur avec l'Onde pour lui voler le dragon !")


## Secousse « denied » d'un bouton utilisé pendant sa recharge.
func refus(action: String) -> void:
	_refus[action] = 0.25
	Audio.jouer("denied")


func _process(delta: float) -> void:
	_toast_temps = maxf(_toast_temps - delta, 0.0)
	_toast_pedago_delai = maxf(_toast_pedago_delai - delta, 0.0)
	_flash_mauvaise = maxf(_flash_mauvaise - delta, 0.0)
	for action in _refus:
		_refus[action] = maxf(_refus[action] - delta, 0.0)
	_boutons = _calculer_boutons()
	surface.queue_redraw()
	# Réponses au clavier (1-4).
	if joueur != null:
		for i in 4:
			if Input.is_action_just_pressed("rep_%d" % (i + 1)):
				_choisir_reponse(i)


func _calculer_boutons() -> Array:
	var t := surface.size
	if joueur == null:
		return []
	return [
		{"centre": Vector2(t.x - 332.0, t.y - 70.0), "rayon": 40.0, "action": "onde", "touche": "E",
			"cd": joueur.cd_onde, "cd_max": Chasseur.CD_ONDE, "teinte": Color(1.0, 0.62, 0.3)},
		{"centre": Vector2(t.x - 238.0, t.y - 108.0), "rayon": 40.0, "action": "dash", "touche": "R",
			"cd": joueur.cd_dash, "cd_max": Chasseur.CD_DASH, "teinte": Color(0.45, 0.85, 1.0)},
		{"centre": Vector2(t.x - 144.0, t.y - 174.0), "rayon": 44.0, "action": "bouclier", "touche": "␣",
			"cd": joueur.cd_bouclier, "cd_max": Chasseur.CD_BOUCLIER, "teinte": Color(0.72, 0.5, 1.0)},
	]


# ---------------------------------------------------------------- entrées tactiles

func _input(event: InputEvent) -> void:
	if surface == null or joueur == null:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_toucher(event.position, event.index)
		else:
			if event.index == _doigt_joystick:
				_doigt_joystick = -1
				vecteur_joystick = Vector2.ZERO
			_doigts_boutons.erase(event.index)
	elif event is InputEventScreenDrag and event.index == _doigt_joystick:
		var v: Vector2 = (event.position - _origine_joystick) / RAYON_JOYSTICK
		if v.length() > 1.0:
			# Le socle suit le pouce : joystick « flottant ».
			_origine_joystick = event.position - v.normalized() * RAYON_JOYSTICK
			v = v.normalized()
		vecteur_joystick = v


func _toucher(pos: Vector2, doigt: int) -> void:
	# Podium : n'importe quel toucher relance un match.
	if arene.etat == Arene.Etat.PODIUM:
		arene.rejouer()
		return
	# Réponses (panneau de question ou panneau latéral).
	for r in _rects_reponses:
		var rect: Rect2 = r.rect
		if rect.has_point(pos):
			_choisir_reponse(int(r.indice))
			return
	# Boutons de pouvoirs.
	for b in _boutons:
		var centre: Vector2 = b.centre
		if pos.distance_to(centre) <= float(b.rayon) + 8.0:
			_doigts_boutons[doigt] = b.action
			_declencher(str(b.action))
			return
	# Joystick sur la moitié gauche.
	if pos.x < surface.size.x * 0.5 and _doigt_joystick == -1:
		_doigt_joystick = doigt
		_origine_joystick = pos
		vecteur_joystick = Vector2.ZERO


func _choisir_reponse(i: int) -> void:
	if joueur.testees.has(i):
		Audio.jouer("denied")
		return
	if arene.etat != Arene.Etat.QUESTION and arene.etat != Arene.Etat.JEU:
		return
	joueur.choix = i
	Audio.jouer("clic")


func _declencher(action: String) -> void:
	match action:
		"onde":
			if joueur.cd_onde > 0.0:
				refus("onde")
			else:
				joueur.utiliser_onde()
		"dash":
			if joueur.cd_dash > 0.0:
				refus("dash")
			else:
				joueur.utiliser_dash()
		"bouclier":
			if joueur.cd_bouclier > 0.0:
				refus("bouclier")
			else:
				joueur.utiliser_bouclier()


# ---------------------------------------------------------------- dessin

func _dessiner(c: Control) -> void:
	if joueur == null or arene == null:
		return
	_rects_reponses = []
	match arene.etat:
		Arene.Etat.QUESTION:
			_dessiner_pilules(c)
			_dessiner_question_grande(c)
		Arene.Etat.JEU:
			_dessiner_pilules(c)
			_dessiner_panneau_lateral(c)
			_dessiner_bords_ecran(c)
			_dessiner_energie(c)
			_dessiner_boutons(c)
			_dessiner_joystick(c)
			if joueur.ko_restant > 0.0:
				_texte(c, c.size / 2.0, "K.O. ! Réapparition dans %.1f s" % joueur.ko_restant, 26, Color(1.0, 0.6, 0.4), true)
			elif joueur.gel_restant > 0.0:
				_texte(c, c.size / 2.0, "Gelé %.1f s…" % joueur.gel_restant, 24, Color(0.7, 0.9, 1.0), true)
			if _flash_mauvaise > 0.0:
				_texte(c, Vector2(c.size.x / 2.0, c.size.y * 0.3), "✗ MAUVAISE RÉPONSE",
					32, Color(1.0, 0.3, 0.25, minf(_flash_mauvaise, 1.0)), true)
		Arene.Etat.INTERLUDE:
			_dessiner_pilules(c)
			_dessiner_energie(c)
			_panneau(c, Rect2(c.size.x / 2.0 - 300.0, c.size.y * 0.36, 600.0, 90.0))
			_texte(c, Vector2(c.size.x / 2.0, c.size.y * 0.36 + 55.0), arene.message_interlude, 24, Color(1.0, 0.95, 0.8), true)
		Arene.Etat.PODIUM:
			_dessiner_podium(c)
	if _toast_temps > 0.0:
		var alpha := clampf(_toast_temps / 0.4, 0.0, 1.0)
		_texte(c, Vector2(c.size.x / 2.0, c.size.y - 44.0), _toast, 19, Color(1.0, 0.95, 0.75, alpha), true)


func _panneau(c: Control, rect: Rect2) -> void:
	c.draw_rect(Rect2(rect.position + Vector2(3.0, 5.0), rect.size), Color(0.0, 0.0, 0.0, 0.3))
	c.draw_rect(rect.grow(3.0), CONTOUR)
	c.draw_rect(rect, FOND_PANNEAU)


func _texte(c: Control, pos: Vector2, texte: String, taille: int, teinte: Color, centre := false) -> void:
	var police := ThemeDB.fallback_font
	var p := pos
	if centre:
		p.x -= police.get_string_size(texte, HORIZONTAL_ALIGNMENT_LEFT, -1, taille).x / 2.0
	c.draw_string_outline(police, p, texte, HORIZONTAL_ALIGNMENT_LEFT, -1, taille, 6,
		Color(CONTOUR.r, CONTOUR.g, CONTOUR.b, teinte.a))
	c.draw_string(police, p, texte, HORIZONTAL_ALIGNMENT_LEFT, -1, taille, teinte)


## Pilules du haut : chrono de MANCHE (dragon) au centre, chrono du MATCH
## et score du joueur.
func _dessiner_pilules(c: Control) -> void:
	var centre_x := c.size.x / 2.0
	# Pilule manche (pendant le jeu) ou décompte question.
	var texte_manche := ""
	if arene.etat == Arene.Etat.JEU:
		texte_manche = "%d s" % int(ceil(arene.temps_etat))
	elif arene.etat == Arene.Etat.QUESTION:
		texte_manche = "Départ dans %d…" % int(ceil(arene.temps_etat))
	if texte_manche != "":
		_panneau(c, Rect2(centre_x - 80.0, 12.0, 160.0, 36.0))
		# Petit dragon stylisé dans la pilule.
		c.draw_circle(Vector2(centre_x - 52.0, 30.0), 9.0, CONTOUR)
		c.draw_circle(Vector2(centre_x - 52.0, 30.0), 7.0, Color(0.45, 0.82, 0.55))
		_texte(c, Vector2(centre_x + 8.0, 38.0), texte_manche, 18, Color.WHITE, true)
	# Chrono du match + score, en haut à gauche.
	_panneau(c, Rect2(10.0, 12.0, 200.0, 64.0))
	var m := int(maxf(arene.temps_match, 0.0)) / 60
	var s := int(maxf(arene.temps_match, 0.0)) % 60
	_texte(c, Vector2(22.0, 38.0), "Match %d:%02d" % [m, s], 16, Color(0.85, 0.9, 1.0))
	_texte(c, Vector2(22.0, 64.0), "%s — %d pts" % [joueur.nom, joueur.score], 17, Color(1.0, 0.9, 0.5))


## Grand panneau de question : décompte, question, réponses empilées.
func _dessiner_question_grande(c: Control) -> void:
	var largeur := minf(c.size.x - 80.0, 620.0)
	var hauteur := 320.0
	var rect := Rect2((c.size.x - largeur) / 2.0, (c.size.y - hauteur) / 2.0 - 20.0, largeur, hauteur)
	_panneau(c, rect)
	# Barre de décompte.
	var ratio := clampf(arene.temps_etat / Arene.COMPTE_QUESTION, 0.0, 1.0)
	c.draw_rect(Rect2(rect.position + Vector2(16.0, 14.0), Vector2(largeur - 32.0, 10.0)), Color(0.25, 0.2, 0.33))
	c.draw_rect(Rect2(rect.position + Vector2(16.0, 14.0), Vector2((largeur - 32.0) * ratio, 10.0)), Color(1.0, 0.8, 0.3))
	_texte(c, Vector2(c.size.x / 2.0, rect.position.y + 62.0), str(arene.question.enonce), 26, Color.WHITE, true)
	_dessiner_reponses(c, Rect2(rect.position + Vector2(24.0, 84.0), Vector2(largeur - 48.0, hauteur - 100.0)), 44.0, 20)
	_texte(c, Vector2(c.size.x / 2.0, rect.end.y + 30.0), "Choisis ta réponse — tu pourras changer jusqu'au départ !", 15, Color(0.8, 0.85, 1.0), true)


## Panneau latéral compact pendant le jeu (choix modifiable, refus barrés).
func _dessiner_panneau_lateral(c: Control) -> void:
	var largeur := 250.0
	var rect := Rect2(c.size.x - largeur - 12.0, 70.0, largeur, 196.0)
	_panneau(c, rect)
	_texte(c, rect.position + Vector2(12.0, 24.0), str(arene.question.enonce), 14, Color(0.95, 0.95, 1.0))
	_dessiner_reponses(c, Rect2(rect.position + Vector2(10.0, 36.0), Vector2(largeur - 20.0, 152.0)), 34.0, 15)
	if joueur.choix == -1:
		# Rappel pulsé : il faut choisir une réponse.
		var pulse := 0.6 + 0.4 * absf(sin(Time.get_ticks_msec() / 250.0))
		c.draw_rect(rect.grow(4.0), Color(1.0, 0.8, 0.3, pulse * 0.5), false, 3.0)
		_texte(c, Vector2(rect.position.x + largeur / 2.0, rect.end.y + 20.0), "Choisis ta réponse !", 15,
			Color(1.0, 0.85, 0.4, pulse), true)


## Rangées de réponses cliquables (partagées entre grand panneau et latéral).
func _dessiner_reponses(c: Control, zone: Rect2, hauteur_rangee: float, taille_texte: int) -> void:
	var pas := (zone.size.y - hauteur_rangee) / 3.0
	for i in 4:
		var rect := Rect2(zone.position + Vector2(0.0, i * pas), Vector2(zone.size.x, hauteur_rangee))
		var teinte: Color = Arene.COULEURS_ZONES[i]
		var testee: bool = joueur.testees.has(i)
		var choisie := joueur.choix == i
		var fond := Color(teinte.r, teinte.g, teinte.b, 0.85 if choisie else 0.45)
		if testee:
			fond = Color(0.4, 0.4, 0.45, 0.5)
		c.draw_rect(rect.grow(2.0), CONTOUR)
		c.draw_rect(rect, fond)
		if choisie:
			c.draw_rect(rect.grow(3.0), Color.WHITE, false, 3.0)
		# Pastille de lettre.
		c.draw_circle(rect.position + Vector2(hauteur_rangee / 2.0, hauteur_rangee / 2.0), hauteur_rangee * 0.32, CONTOUR)
		_texte(c, rect.position + Vector2(hauteur_rangee / 2.0, hauteur_rangee / 2.0 + taille_texte * 0.35),
			Arene.LETTRES[i], taille_texte, Color.WHITE, true)
		var texte := str(arene.question.reponses[i])
		_texte(c, rect.position + Vector2(hauteur_rangee + 8.0, hauteur_rangee / 2.0 + taille_texte * 0.35),
			texte, taille_texte, Color(0.75, 0.75, 0.8) if testee else Color.WHITE)
		if testee:
			var y := rect.position.y + hauteur_rangee / 2.0
			c.draw_line(Vector2(rect.position.x + hauteur_rangee + 4.0, y), Vector2(rect.end.x - 10.0, y),
				Color(0.9, 0.25, 0.2, 0.9), 3.0)
		_rects_reponses.append({"rect": rect, "indice": i})


func _dessiner_energie(c: Control) -> void:
	var rect := Rect2(10.0, 86.0, 200.0, 20.0)
	var ratio := joueur.energie / Chasseur.ENERGIE_MAX
	var teinte := Color(0.35, 0.85, 0.45)
	if ratio < 0.25:
		# La jauge pulse sous 25 %.
		teinte = Color(1.0, 0.3, 0.25).lerp(Color(1.0, 0.6, 0.3), absf(sin(Time.get_ticks_msec() / 180.0)))
	c.draw_rect(rect.grow(3.0), CONTOUR)
	c.draw_rect(rect, Color(0.22, 0.18, 0.28))
	if ratio > 0.01:
		c.draw_rect(Rect2(rect.position, Vector2(rect.size.x * ratio, rect.size.y)), teinte)
		c.draw_rect(Rect2(rect.position, Vector2(rect.size.x * ratio, rect.size.y * 0.45)), Color(1.0, 1.0, 1.0, 0.25))
	_texte(c, rect.position + Vector2(rect.size.x / 2.0, 15.0), "Énergie %d" % int(joueur.energie), 12, Color.WHITE, true)


func _dessiner_boutons(c: Control) -> void:
	for b in _boutons:
		var centre: Vector2 = b.centre
		var action := str(b.action)
		var cd := float(b.cd)
		var cd_max := float(b.cd_max)
		var teinte: Color = b.teinte
		var rayon := float(b.rayon)
		# Secousse « denied ».
		if _refus.get(action, 0.0) > 0.0:
			centre += Vector2(randf_range(-3.0, 3.0), randf_range(-3.0, 3.0))
		# L'onde pulse en doré quand le porteur adverse est à portée de vol.
		if action == "onde" and cd <= 0.0 and arene.dragon != null and arene.dragon.porteur != null \
				and not arene.dragon.porteur.est_joueur \
				and joueur.position.distance_to(arene.dragon.porteur.position) <= Chasseur.PORTEE_ONDE + 20.0:
			var halo := rayon + 8.0 + sin(Time.get_ticks_msec() / 90.0) * 3.0
			c.draw_circle(centre, halo, Color(1.0, 0.85, 0.2, 0.4))
		var enfonce: bool = _doigts_boutons.values().has(action)
		var r := rayon * (0.92 if enfonce else 1.0)
		c.draw_circle(centre + Vector2(0.0, 4.0), r + 4.0, Color(0.0, 0.0, 0.0, 0.3))
		c.draw_circle(centre, r + 4.0, CONTOUR)
		c.draw_circle(centre, r, teinte if cd <= 0.0 else Color(0.35, 0.32, 0.42))
		c.draw_circle(centre + Vector2(0.0, -r * 0.35), r * 0.55, Color(1.0, 1.0, 1.0, 0.22))
		_icone_bouton(c, centre, r, action)
		if cd > 0.0:
			# Anneau de recharge + décompte en secondes dans le bouton.
			var frac := cd / cd_max
			c.draw_arc(centre, r - 4.0, -PI / 2.0, -PI / 2.0 + TAU * (1.0 - frac), 32, Color(1.0, 1.0, 1.0, 0.85), 5.0)
			_texte(c, centre + Vector2(0.0, 7.0), "%.1f" % cd, 18, Color.WHITE, true)
		else:
			_texte(c, centre + Vector2(0.0, rayon + 18.0), str(b.touche), 12, Color(1.0, 1.0, 1.0, 0.7), true)


func _icone_bouton(c: Control, p: Vector2, r: float, action: String) -> void:
	match action:
		"onde":
			# Cône d'onde de choc.
			for i in 3:
				c.draw_arc(p + Vector2(-r * 0.3, 0.0), r * (0.25 + 0.18 * i), -0.7, 0.7, 10, CONTOUR, 4.0)
		"dash":
			# Double chevron d'élan.
			for i in 2:
				var px := p + Vector2(-r * 0.35 + i * r * 0.4, 0.0)
				c.draw_line(px + Vector2(-r * 0.2, -r * 0.35), px + Vector2(r * 0.15, 0.0), CONTOUR, 5.0)
				c.draw_line(px + Vector2(-r * 0.2, r * 0.35), px + Vector2(r * 0.15, 0.0), CONTOUR, 5.0)
		"bouclier":
			# Écusson.
			c.draw_colored_polygon(PackedVector2Array([
				p + Vector2(-r * 0.4, -r * 0.35), p + Vector2(r * 0.4, -r * 0.35),
				p + Vector2(r * 0.4, r * 0.1), p + Vector2(0.0, r * 0.45), p + Vector2(-r * 0.4, r * 0.1),
			]), CONTOUR)


## Indicateurs de bord d'écran : dragon et zones hors champ, avec distance.
func _dessiner_bords_ecran(c: Control) -> void:
	var centre := c.size / 2.0
	var marge := 40.0
	# Dragon.
	if arene.dragon != null and arene.dragon.libre():
		_indicateur(c, centre, marge, arene.dragon.position, Color(0.45, 0.82, 0.55), "")
	# Zones.
	for i in arene.zones.size():
		var z: Dictionary = arene.zones[i]
		_indicateur(c, centre, marge, z.pos, z.teinte, str(z.lettre))


func _indicateur(c: Control, centre: Vector2, marge: float, pos_monde: Vector2, teinte: Color, lettre: String) -> void:
	var relatif: Vector2 = pos_monde - joueur.position
	var ecran := centre + relatif
	# Visible à l'écran : pas d'indicateur.
	if ecran.x > marge and ecran.x < c.size.x - marge and ecran.y > marge and ecran.y < c.size.y - marge:
		return
	# Le bord haut est clampé sous les panneaux (chronos, énergie, question).
	var borne := Vector2(clampf(ecran.x, marge, c.size.x - marge), clampf(ecran.y, 126.0, c.size.y - marge))
	# Ne pas passer sous le panneau latéral de question (en haut à droite).
	if borne.x > c.size.x - 290.0 and borne.y < 300.0:
		borne.y = 300.0
	var dir := relatif.normalized()
	c.draw_colored_polygon(PackedVector2Array([
		borne + dir * 16.0, borne + dir.rotated(2.5) * 9.0, borne + dir.rotated(-2.5) * 9.0,
	]), CONTOUR)
	c.draw_circle(borne, 11.0, CONTOUR)
	c.draw_circle(borne, 9.0, teinte)
	if lettre != "":
		_texte(c, borne + Vector2(0.0, 5.0), lettre, 13, Color.WHITE, true)
	_texte(c, borne - dir * 24.0 + Vector2(0.0, 5.0), "%d m" % int(relatif.length() / 60.0), 12,
		Color(1.0, 1.0, 1.0, 0.85), true)


func _dessiner_joystick(c: Control) -> void:
	if _doigt_joystick == -1:
		return
	c.draw_circle(_origine_joystick, RAYON_JOYSTICK + 4.0, Color(0.10, 0.08, 0.14, 0.35))
	c.draw_circle(_origine_joystick, RAYON_JOYSTICK, Color(1.0, 1.0, 1.0, 0.12))
	var pommeau := _origine_joystick + vecteur_joystick * (RAYON_JOYSTICK - 16.0)
	c.draw_circle(pommeau, 30.0, Color(0.10, 0.08, 0.14, 0.5))
	c.draw_circle(pommeau, 25.0, Color(1.0, 1.0, 1.0, 0.45))


func _dessiner_podium(c: Control) -> void:
	var largeur := minf(c.size.x - 80.0, 520.0)
	var rect := Rect2((c.size.x - largeur) / 2.0, c.size.y * 0.2, largeur, 300.0)
	_panneau(c, rect)
	_texte(c, Vector2(c.size.x / 2.0, rect.position.y + 44.0), "Fin du match !", 30, Color(1.0, 0.9, 0.4), true)
	var classement: Array = arene.chasseurs.duplicate()
	classement.sort_custom(func(a, b): return a.score > b.score)
	for i in classement.size():
		var ch: Chasseur = classement[i]
		var y := rect.position.y + 90.0 + i * 44.0
		c.draw_circle(Vector2(rect.position.x + 44.0, y - 7.0), 14.0, CONTOUR)
		c.draw_circle(Vector2(rect.position.x + 44.0, y - 7.0), 11.0, ch.teinte)
		var medaille: String = ["1er", "2e", "3e", "4e"][i]
		_texte(c, Vector2(rect.position.x + 76.0, y), "%s  %s" % [medaille, ch.nom], 22,
			Color(1.0, 0.9, 0.5) if i == 0 else Color.WHITE)
		_texte(c, Vector2(rect.end.x - 110.0, y), "%d pts" % ch.score, 22, Color(0.85, 0.9, 1.0))
	_texte(c, Vector2(c.size.x / 2.0, rect.end.y - 20.0), "Touche l'écran pour rejouer", 16,
		Color(0.8, 0.85, 1.0, 0.6 + 0.4 * absf(sin(Time.get_ticks_msec() / 300.0))), true)


## Canvas plein écran : délègue tout le dessin au HUD parent.
class Surface extends Control:
	var hud: HUD = null

	func _draw() -> void:
		if hud != null:
			hud._dessiner(self)

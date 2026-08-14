class_name HUD
extends CanvasLayer
## Interface en jeu, portage fidèle de la planche ILLUMINIA
## (style-guide-fantasypop.png) via le kit ui.gd : panneaux marine à gros
## contours, panneau de question à hexagone violet, réponses aux quatre
## couleurs liées aux zones, boutons de pouvoirs carrés arrondis à anneau
## de recharge doré, jauge d'énergie à éclair, bannière dorée, podium.

const RAYON_JOYSTICK := 70.0

var joueur: Chasseur
var arene: Arene
var camera: Camera3D
var vecteur_joystick := Vector2.ZERO

# Joystick flottant.
var _doigt_joystick := -1
var _origine_joystick := Vector2.ZERO

var _boutons: Array = []          ## boutons de pouvoirs {centre, cote, action, …}
var _rects_reponses: Array = []   ## zones cliquables des réponses {rect, indice}
var _doigts_boutons := {}
var _refus := {}                  ## action → temps de secousse « denied »
var _toast := ""
var _toast_temps := 0.0
var _toast_pedago_delai := 0.0
var _flash_mauvaise := 0.0
var _guide_etape := 0            ## tutoriel de première partie (0 = éteint)
var _guide_depart := Vector2.ZERO
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
	pass


func toast(texte: String) -> void:
	_toast = texte
	_toast_temps = 3.0


## « Pousse le porteur pour lui voler le dragon ! » — max une fois / 20 s.
func toast_pedagogique() -> void:
	if _toast_pedago_delai > 0.0:
		return
	_toast_pedago_delai = 20.0
	toast("Pousse le porteur avec l'Onde pour lui voler le dragon !")


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
	_guider()
	surface.queue_redraw()
	if joueur != null:
		for i in 4:
			if Input.is_action_just_pressed("rep_%d" % (i + 1)):
				_choisir_reponse(i)


## Tutoriel de la toute première partie : trois consignes contextuelles,
## une seule à la fois, jusqu'à la fin de la première manche.
func _guider() -> void:
	if Profil.tutoriel_fait or joueur == null or arene == null:
		return
	match _guide_etape:
		0:
			if arene.etat == Arene.Etat.JEU:
				_guide_etape = 1
				_guide_depart = joueur.pos2()
		1:
			if joueur.pos2().distance_to(_guide_depart) > 2.0:
				_guide_etape = 2
		2:
			if arene.dragon != null and arene.dragon.porteur != null:
				_guide_etape = 3
		3:
			pass
	# La première manche terminée, le tutoriel est acquis.
	if _guide_etape > 0 and (arene.etat == Arene.Etat.INTERLUDE or arene.etat == Arene.Etat.PODIUM):
		Profil.tutoriel_fait = true
		Profil.sauver()
		_guide_etape = 0


func _texte_guide() -> String:
	match _guide_etape:
		1:
			return "Pose ton pouce à GAUCHE et bouge le joystick !"
		2:
			return "Attrape le bébé dragon — suis la pastille verte !"
		3:
			if joueur.porte_dragon():
				return "Bravo ! Suis les chevrons vers la zone de TA réponse !"
			return "Approche du porteur et touche le bouton ORANGE pour lui voler !"
	return ""


## Boutons de pouvoirs : carrés arrondis (barre de compétences de la
## planche), ≥ 76 px, en arc au pouce droit.
func _calculer_boutons() -> Array:
	var t := surface.size
	if joueur == null:
		return []
	return [
		{"centre": Vector2(t.x - 338.0, t.y - 64.0), "cote": 84.0, "action": "onde", "touche": "E",
			"cd": joueur.cd_onde, "cd_max": Chasseur.CD_ONDE, "teinte": Identite.ORANGE},
		{"centre": Vector2(t.x - 238.0, t.y - 106.0), "cote": 84.0, "action": "dash", "touche": "R",
			"cd": joueur.cd_dash, "cd_max": Chasseur.CD_DASH, "teinte": Identite.BLEU},
		{"centre": Vector2(t.x - 132.0, t.y - 168.0), "cote": 92.0, "action": "bouclier", "touche": "␣",
			"cd": joueur.cd_bouclier, "cd_max": Chasseur.CD_BOUCLIER, "teinte": Identite.VIOLET},
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
			_origine_joystick = event.position - v.normalized() * RAYON_JOYSTICK
			v = v.normalized()
		vecteur_joystick = v


func _toucher(pos: Vector2, doigt: int) -> void:
	if arene.etat == Arene.Etat.PODIUM:
		Audio.jouer("clic")
		arene.rejouer()
		return
	for r in _rects_reponses:
		var rect: Rect2 = r.rect
		if rect.has_point(pos):
			_choisir_reponse(int(r.indice))
			return
	for b in _boutons:
		var centre: Vector2 = b.centre
		var demi: float = float(b.cote) / 2.0 + 8.0
		if absf(pos.x - centre.x) <= demi and absf(pos.y - centre.y) <= demi:
			_doigts_boutons[doigt] = b.action
			_declencher(str(b.action))
			return
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
			# Anneau de dépôt canalisé au-dessus du porteur.
			var canal: Dictionary = arene.canal
			if not canal.is_empty() and is_instance_valid(canal.chasseur) and camera != null:
				var ch: Chasseur = canal.chasseur
				var ecran := camera.unproject_position(ch.position + Vector3(0.0, 1.9, 0.0))
				var frac := clampf(float(canal.progres), 0.0, 1.0)
				c.draw_arc(ecran, 34.0, 0.0, TAU, 40, Color(1.0, 1.0, 1.0, 0.25), 8.0)
				c.draw_arc(ecran, 34.0, -PI / 2.0, -PI / 2.0 + TAU * frac, 40, Identite.OR, 8.0)
				UI.texte(c, ecran + Vector2(0.0, 60.0), "DÉPÔT…", 14, Identite.OR, true, 4)
			# Consigne du tutoriel (première partie seulement).
			var consigne := _texte_guide()
			if consigne != "":
				UI.banniere(c, Vector2(c.size.x / 2.0, c.size.y - 120.0),
					minf(c.size.x - 200.0, 660.0), consigne, 18)
			if joueur.ko_restant > 0.0:
				UI.texte(c, c.size / 2.0, "K.O. ! Réapparition dans %.1f s" % joueur.ko_restant,
					26, Identite.ORANGE, true)
			elif joueur.gel_restant > 0.0:
				UI.texte(c, c.size / 2.0, "Gelé %.1f s…" % joueur.gel_restant, 24, Identite.CYAN, true)
			if _flash_mauvaise > 0.0:
				UI.texte(c, Vector2(c.size.x / 2.0, c.size.y * 0.3), "✗ MAUVAISE RÉPONSE",
					32, Color(Identite.ROUGE.r, Identite.ROUGE.g, Identite.ROUGE.b, minf(_flash_mauvaise, 1.0)), true)
		Arene.Etat.INTERLUDE:
			_dessiner_pilules(c)
			_dessiner_energie(c)
			UI.banniere(c, Vector2(c.size.x / 2.0, c.size.y * 0.4), minf(c.size.x - 160.0, 620.0),
				arene.message_interlude, 22)
		Arene.Etat.PODIUM:
			_dessiner_podium(c)
	if _toast_temps > 0.0:
		var alpha := clampf(_toast_temps / 0.4, 0.0, 1.0)
		UI.texte(c, Vector2(c.size.x / 2.0, c.size.y - 44.0), _toast, 19,
			Color(Identite.CREME.r, Identite.CREME.g, Identite.CREME.b, alpha), true)


## Pilules du haut : chrono de MANCHE au centre, chrono du MATCH + score.
func _dessiner_pilules(c: Control) -> void:
	var centre_x := c.size.x / 2.0
	var texte_manche := ""
	if arene.etat == Arene.Etat.JEU:
		texte_manche = "%d s" % int(ceil(arene.temps_etat))
	elif arene.etat == Arene.Etat.QUESTION:
		texte_manche = "Départ dans %d…" % int(ceil(arene.temps_etat))
	if texte_manche != "":
		c.draw_style_box(UI.style("pilule", Identite.PANNEAU, Identite.OR, 20),
			Rect2(centre_x - 98.0, 10.0, 196.0, 44.0))
		c.draw_circle(Vector2(centre_x - 64.0, 32.0), 12.0, Identite.CONTOUR)
		c.draw_circle(Vector2(centre_x - 64.0, 32.0), 10.0, Identite.VERT)
		UI.texte(c, Vector2(centre_x + 12.0, 41.0), texte_manche, 21, Identite.TEXTE, true)
	UI.panneau(c, Rect2(10.0, 10.0, 218.0, 72.0))
	var m := int(maxf(arene.temps_match, 0.0)) / 60
	var s := int(maxf(arene.temps_match, 0.0)) % 60
	UI.texte(c, Vector2(24.0, 38.0), "Match %d:%02d" % [m, s], 17, Identite.TEXTE_ATTENUE)
	UI.texte(c, Vector2(24.0, 66.0), "%s — %d pts" % [joueur.nom, joueur.score], 19, Identite.OR)


## Grand panneau de question (planche : hexagone « ? » violet + décompte).
func _dessiner_question_grande(c: Control) -> void:
	var largeur := minf(c.size.x - 80.0, 620.0)
	var hauteur := 330.0
	var rect := Rect2((c.size.x - largeur) / 2.0, (c.size.y - hauteur) / 2.0 - 16.0, largeur, hauteur)
	UI.panneau(c, rect)
	UI.hexagone(c, rect.position + Vector2(34.0, 34.0), 24.0, Identite.VIOLET, "?", 24)
	# Barre de décompte dorée.
	UI.barre(c, Rect2(rect.position + Vector2(70.0, 20.0), Vector2(largeur - 90.0, 16.0)),
		arene.temps_etat / Arene.COMPTE_QUESTION, Identite.OR)
	UI.texte(c, Vector2(c.size.x / 2.0, rect.position.y + 84.0), str(arene.question.enonce), 26, Identite.TEXTE, true)
	_dessiner_reponses(c, Rect2(rect.position + Vector2(24.0, 104.0), Vector2(largeur - 48.0, hauteur - 122.0)), 44.0, 20)
	UI.texte(c, Vector2(c.size.x / 2.0, rect.end.y + 30.0),
		"Choisis ta réponse — tu pourras changer jusqu'au départ !", 15, Identite.TEXTE_ATTENUE, true)


## Panneau latéral compact pendant le jeu (choix modifiable, refus barrés).
func _dessiner_panneau_lateral(c: Control) -> void:
	var largeur := 280.0
	var rect := Rect2(c.size.x - largeur - 10.0, 64.0, largeur, 206.0)
	UI.panneau(c, rect)
	UI.texte(c, rect.position + Vector2(14.0, 28.0), str(arene.question.enonce), 15, Identite.TEXTE)
	_dessiner_reponses(c, Rect2(rect.position + Vector2(12.0, 40.0), Vector2(largeur - 24.0, 158.0)), 36.0, 16)
	if joueur.choix == -1:
		var pulse := 0.6 + 0.4 * absf(sin(Time.get_ticks_msec() / 250.0))
		c.draw_rect(rect.grow(4.0), Color(Identite.OR.r, Identite.OR.g, Identite.OR.b, pulse * 0.6), false, 3.0)
		UI.texte(c, Vector2(rect.position.x + largeur / 2.0, rect.position.y - 12.0), "Choisis ta réponse !", 17,
			Color(Identite.OR.r, Identite.OR.g, Identite.OR.b, pulse), true)


## Rangées de réponses : boutons joufflus aux couleurs des zones.
func _dessiner_reponses(c: Control, zone: Rect2, hauteur_rangee: float, taille_texte: int) -> void:
	var pas := (zone.size.y - hauteur_rangee) / 3.0
	for i in 4:
		var rect := Rect2(zone.position + Vector2(0.0, i * pas), Vector2(zone.size.x, hauteur_rangee))
		var teinte: Color = Identite.COULEURS_REPONSES[i]
		var testee: bool = joueur.testees.has(i)
		var choisie := joueur.choix == i
		if testee:
			c.draw_style_box(UI.style("rep_testee", Color(0.2, 0.22, 0.32), Identite.CONTOUR,
				Identite.RAYON_SM, Identite.BORD, 2), rect)
		else:
			UI.bouton(c, rect, teinte.darkened(0.05 if choisie else 0.3),
				"rep_%d_%s" % [i, str(choisie)], false, Identite.RAYON_SM)
		if choisie:
			c.draw_rect(rect.grow(3.0), Color.WHITE, false, 3.0)
		UI.pastille(c, rect.position + Vector2(hauteur_rangee / 2.0, hauteur_rangee / 2.0),
			hauteur_rangee * 0.3, teinte.darkened(0.35) if not testee else Color(0.35, 0.36, 0.45),
			Arene.LETTRES[i], taille_texte)
		UI.texte(c, rect.position + Vector2(hauteur_rangee + 10.0, hauteur_rangee / 2.0 + taille_texte * 0.35),
			str(arene.question.reponses[i]), taille_texte,
			Color(0.65, 0.68, 0.78) if testee else Identite.TEXTE)
		if testee:
			var y := rect.position.y + hauteur_rangee / 2.0
			c.draw_line(Vector2(rect.position.x + hauteur_rangee + 6.0, y), Vector2(rect.end.x - 12.0, y),
				Identite.ROUGE, 3.0)
		_rects_reponses.append({"rect": rect, "indice": i})


## Jauge d'énergie bleue à éclair (planche : « énergie / mana »).
func _dessiner_energie(c: Control) -> void:
	var rect := Rect2(40.0, 94.0, 208.0, 28.0)
	var ratio := joueur.energie / Chasseur.ENERGIE_MAX
	var teinte := Identite.BLEU
	if ratio < 0.25:
		teinte = Identite.ROUGE.lerp(Identite.ORANGE, absf(sin(Time.get_ticks_msec() / 180.0)))
	UI.barre(c, rect, ratio, teinte)
	UI.eclair(c, Vector2(26.0, 108.0), 26.0, Identite.OR)
	UI.texte(c, rect.position + Vector2(rect.size.x / 2.0, 20.0), str(int(joueur.energie)), 15, Identite.TEXTE, true, 4)


## Boutons de pouvoirs : carrés arrondis + anneau de recharge doré.
func _dessiner_boutons(c: Control) -> void:
	for b in _boutons:
		var centre: Vector2 = b.centre
		var action := str(b.action)
		var cd := float(b.cd)
		var cd_max := float(b.cd_max)
		var teinte: Color = b.teinte
		var cote := float(b.cote)
		if _refus.get(action, 0.0) > 0.0:
			centre += Vector2(randf_range(-3.0, 3.0), randf_range(-3.0, 3.0))
		# L'onde pulse en doré quand le porteur adverse est à portée de vol.
		if action == "onde" and cd <= 0.0 and arene.dragon != null and arene.dragon.porteur != null \
				and not arene.dragon.porteur.est_joueur \
				and joueur.pos2().distance_to(arene.dragon.porteur.pos2()) <= Chasseur.PORTEE_ONDE + 0.35:
			var halo := cote / 2.0 + 9.0 + sin(Time.get_ticks_msec() / 90.0) * 3.0
			c.draw_circle(centre, halo, Color(Identite.OR.r, Identite.OR.g, Identite.OR.b, 0.45))
		var enfonce: bool = _doigts_boutons.values().has(action)
		var rect := Rect2(centre - Vector2(cote, cote) / 2.0, Vector2(cote, cote))
		UI.bouton(c, rect, teinte if cd <= 0.0 else Color(0.24, 0.27, 0.4),
			"pouvoir_%s_%s" % [action, str(cd <= 0.0)], enfonce, Identite.RAYON_MD)
		UI.icone_pouvoir(c, centre, cote * 0.5, action)
		if cd > 0.0:
			var frac := cd / cd_max
			c.draw_arc(centre, cote / 2.0 - 5.0, -PI / 2.0, -PI / 2.0 + TAU * (1.0 - frac), 32,
				Identite.OR, 5.0)
			UI.texte(c, centre + Vector2(0.0, 7.0), "%.1f" % cd, 18, Identite.TEXTE, true)
		else:
			UI.texte(c, centre + Vector2(0.0, cote / 2.0 + 16.0), str(b.touche), 12,
				Color(1.0, 1.0, 1.0, 0.7), true, 4)


## Indicateurs de bord d'écran : dragon et zones hors champ, avec distance.
func _dessiner_bords_ecran(c: Control) -> void:
	if camera == null:
		return
	if arene.dragon != null and arene.dragon.libre():
		_indicateur(c, arene.dragon.pos2(), Identite.VERT, "")
	for i in arene.zones.size():
		var z: Dictionary = arene.zones[i]
		_indicateur(c, z.pos, z.teinte, str(z.lettre))


func _indicateur(c: Control, pos_monde: Vector2, teinte: Color, lettre: String) -> void:
	var marge := 40.0
	var ecran := camera.unproject_position(Vector3(pos_monde.x, 0.8, pos_monde.y))
	if ecran.x > marge and ecran.x < c.size.x - marge and ecran.y > marge and ecran.y < c.size.y - marge:
		return
	# Marge droite élargie : la colonne de droite est occupée (panneau de
	# question en haut, boutons de pouvoirs en bas).
	var borne := Vector2(clampf(ecran.x, marge, c.size.x - 330.0), clampf(ecran.y, 136.0, c.size.y - marge))
	var dir := (ecran - c.size / 2.0).normalized()
	c.draw_colored_polygon(PackedVector2Array([
		borne + dir * 16.0, borne + dir.rotated(2.5) * 9.0, borne + dir.rotated(-2.5) * 9.0,
	]), Identite.CONTOUR)
	UI.pastille(c, borne, 9.0, teinte, lettre, 13)
	var distance := joueur.pos2().distance_to(pos_monde)
	UI.texte(c, borne - dir * 24.0 + Vector2(0.0, 5.0), "%d m" % int(distance), 12,
		Color(1.0, 1.0, 1.0, 0.85), true, 4)


## Joystick de la planche : socle marine, pommeau bleu glossy.
func _dessiner_joystick(c: Control) -> void:
	if _doigt_joystick == -1:
		return
	c.draw_circle(_origine_joystick, RAYON_JOYSTICK + 5.0, Identite.CONTOUR)
	c.draw_circle(_origine_joystick, RAYON_JOYSTICK, Color(Identite.PANNEAU.r, Identite.PANNEAU.g, Identite.PANNEAU.b, 0.75))
	c.draw_circle(_origine_joystick, RAYON_JOYSTICK - 10.0, Color(Identite.NUIT.r, Identite.NUIT.g, Identite.NUIT.b, 0.6))
	var pommeau := _origine_joystick + vecteur_joystick * (RAYON_JOYSTICK - 18.0)
	c.draw_circle(pommeau, 30.0, Identite.CONTOUR)
	c.draw_circle(pommeau, 26.0, Identite.BLEU)
	c.draw_circle(pommeau + Vector2(0.0, -8.0), 14.0, Color(1.0, 1.0, 1.0, 0.25))


## Podium : bannière VICTOIRE, classement à pastilles de rang, REJOUER doré.
func _dessiner_podium(c: Control) -> void:
	var largeur := minf(c.size.x - 80.0, 560.0)
	var rect := Rect2((c.size.x - largeur) / 2.0, c.size.y * 0.12, largeur, 296.0)
	UI.panneau(c, rect)
	var classement: Array = arene.chasseurs.duplicate()
	classement.sort_custom(func(a, b): return a.score > b.score)
	UI.banniere(c, Vector2(c.size.x / 2.0, rect.position.y), 320.0, "VICTOIRE !", 26)
	UI.etoile(c, Vector2(c.size.x / 2.0 - 190.0, rect.position.y), 16.0, Identite.OR)
	UI.etoile(c, Vector2(c.size.x / 2.0 + 190.0, rect.position.y), 16.0, Identite.OR)
	var couleurs_rang: Array = [Identite.OR, Color(0.75, 0.78, 0.85), Color(0.8, 0.55, 0.35), Identite.PANNEAU_CLAIR]
	for i in classement.size():
		var ch: Chasseur = classement[i]
		var y := rect.position.y + 62.0 + i * 46.0
		var ligne := Rect2(rect.position.x + 22.0, y - 20.0, largeur - 44.0, 40.0)
		c.draw_style_box(UI.style("podium_%d" % i,
			Color(0.29, 0.24, 0.1) if i == 0 else Identite.PANNEAU_CLAIR.darkened(0.2),
			Identite.CONTOUR, Identite.RAYON_SM, Identite.BORD, 2), ligne)
		UI.pastille(c, Vector2(rect.position.x + 52.0, y), 14.0, couleurs_rang[i], str(i + 1), 15)
		c.draw_circle(Vector2(rect.position.x + 92.0, y), 12.0, Identite.CONTOUR)
		c.draw_circle(Vector2(rect.position.x + 92.0, y), 9.0, ch.teinte)
		UI.texte(c, Vector2(rect.position.x + 116.0, y + 7.0), ch.nom, 21,
			Identite.OR if i == 0 else Identite.TEXTE)
		UI.texte(c, Vector2(rect.end.x - 116.0, y + 7.0), "%d pts" % ch.score, 21, Identite.TEXTE_ATTENUE)
	# Gains : trophées, pièces, œuf, XP du héros — la moisson du match.
	var gains: Dictionary = arene.recompense_podium
	if not gains.is_empty():
		var l1 := "%+d trophées (%s)    +%d pièces" % [int(gains.trophees), str(Profil.ligue().nom), int(gains.pieces)]
		if bool(gains.oeuf):
			l1 += "    ŒUF DE DRAGON !"
		UI.texte(c, Vector2(c.size.x / 2.0, rect.end.y - 36.0), l1, 17, Identite.OR, true)
		var l2 := "+%d XP pour %s" % [int(gains.xp), str(gains.heros)]
		if int(gains.niveaux_heros) > 0:
			l2 += " — NIVEAU %d !" % Profil.niveau_heros(str(gains.heros))
		UI.texte(c, Vector2(c.size.x / 2.0, rect.end.y - 12.0), l2, 15, Identite.TEXTE_ATTENUE, true)
	var pulse := 1.0 + 0.04 * sin(Time.get_ticks_msec() / 220.0)
	var bl := 260.0 * pulse
	var bh := 62.0 * pulse
	var bouton := Rect2(Vector2(c.size.x / 2.0 - bl / 2.0, rect.end.y + 16.0 - (bh - 62.0) / 2.0), Vector2(bl, bh))
	UI.bouton(c, bouton, Identite.OR, "rejouer", false, Identite.RAYON_LG)
	UI.texte(c, Vector2(c.size.x / 2.0, bouton.position.y + bouton.size.y / 2.0 + 9.0), "REJOUER !", 26, Identite.TEXTE, true, 7)


## Canvas plein écran : délègue tout le dessin au HUD parent.
class Surface extends Control:
	var hud: HUD = null

	func _draw() -> void:
		if hud != null:
			hud._dessiner(self)

class_name UI
extends RefCounted
## Kit d'interface « Fantasy Pop » : les composants de la planche
## style-guide-fantasypop.png, dessinés en code sur un Control.
## Tous les écrans (hud.gd, menu.gd) passent par ces aides — pour changer
## le style d'un composant, on ne le change qu'ici (voir identite.gd).

static var _styles := {}


## StyleBoxFlat en cache : fond arrondi, gros bord marine, ombre portée.
static func style(cle: String, fond: Color, bord: Color, rayon := Identite.RAYON_MD,
		epaisseur := Identite.BORD, ombre := 5) -> StyleBoxFlat:
	if _styles.has(cle):
		return _styles[cle]
	var sb := StyleBoxFlat.new()
	sb.bg_color = fond
	sb.border_color = bord
	sb.set_border_width_all(epaisseur)
	sb.set_corner_radius_all(rayon)
	if ombre > 0:
		sb.shadow_color = Color(0.0, 0.0, 0.0, 0.4)
		sb.shadow_size = ombre
		sb.shadow_offset = Vector2(0.0, 3.0)
	_styles[cle] = sb
	return sb


## Panneau standard marine.
static func panneau(c: Control, rect: Rect2) -> void:
	c.draw_style_box(style("panneau", Identite.PANNEAU, Identite.CONTOUR), rect)


## Texte à contour marine épais (lisibilité BD).
static func texte(c: Control, pos: Vector2, txt: String, taille: int, teinte: Color,
		centre := false, epaisseur_contour := 6) -> void:
	var police := ThemeDB.fallback_font
	var p := pos
	if centre:
		p.x -= police.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, taille).x / 2.0
	c.draw_string_outline(police, p, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, taille, epaisseur_contour,
		Color(Identite.CONTOUR.r, Identite.CONTOUR.g, Identite.CONTOUR.b, teinte.a))
	c.draw_string(police, p, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, taille, teinte)


## Bouton de la planche : BISEAU 3D — face colorée, tranche sombre en
## dessous (volume cartoon), highlight supérieur. Pressé = la face descend
## sur la tranche.
static func bouton(c: Control, rect: Rect2, fond: Color, cle: String,
		enfonce := false, rayon := Identite.RAYON_MD) -> void:
	var epaisseur := minf(6.0, rect.size.y * 0.12)
	var face := Rect2(rect.position, rect.size - Vector2(0.0, epaisseur))
	if enfonce:
		face.position.y += epaisseur - 1.0
	# Tranche du bas (le « volume » de la planche).
	c.draw_style_box(style("%s_tranche" % cle, fond.darkened(0.45), Identite.CONTOUR,
		rayon, Identite.BORD_FORT, 4),
		Rect2(rect.position + Vector2(0.0, rect.size.y - epaisseur - rayon), Vector2(rect.size.x, epaisseur + rayon)))
	c.draw_style_box(style(cle, fond, Identite.CONTOUR, rayon, Identite.BORD_FORT, 0), face)
	# Highlight supérieur.
	c.draw_style_box(style("gloss_%d" % rayon, Color(1.0, 1.0, 1.0, 0.20), Color(0, 0, 0, 0),
		maxi(rayon - 6, 4), 0, 0),
		Rect2(face.position + Vector2(6.0, 4.0), Vector2(face.size.x - 12.0, face.size.y * 0.42)))


## Barre glossy (énergie, décompte) : fond navy + remplissage + reflet.
static func barre(c: Control, rect: Rect2, ratio: float, teinte: Color) -> void:
	c.draw_style_box(style("barre_fond", Identite.NUIT, Identite.CONTOUR, Identite.RAYON_SM, Identite.BORD, 3), rect)
	var r := clampf(ratio, 0.0, 1.0)
	if r > 0.02:
		var interieur := Rect2(rect.position + Vector2(3.0, 3.0),
			Vector2((rect.size.x - 6.0) * r, rect.size.y - 6.0))
		var cle := "barre_%s_%d" % [teinte.to_html(false), int(r * 24.0)]
		c.draw_style_box(style(cle, teinte, teinte.darkened(0.35), Identite.RAYON_SM - 3, 2, 0), interieur)
		c.draw_rect(Rect2(interieur.position + Vector2(2.0, 1.0),
			Vector2(interieur.size.x - 4.0, interieur.size.y * 0.4)), Color(1.0, 1.0, 1.0, 0.22))


## Pastille ronde à lettre (A/B/C/D, rangs du podium).
static func pastille(c: Control, centre: Vector2, rayon: float, fond: Color, txt: String, taille := 15) -> void:
	c.draw_circle(centre, rayon + 3.0, Identite.CONTOUR)
	c.draw_circle(centre, rayon, fond)
	c.draw_circle(centre + Vector2(0.0, -rayon * 0.35), rayon * 0.55, Color(1.0, 1.0, 1.0, 0.22))
	texte(c, centre + Vector2(0.0, taille * 0.36), txt, taille, Identite.TEXTE, true, 4)


## Bannière dorée à rubans (VICTOIRE, titres de fenêtres).
static func banniere(c: Control, centre: Vector2, largeur: float, txt: String, taille := 26) -> void:
	var h := taille * 1.9
	var rect := Rect2(centre - Vector2(largeur / 2.0, h / 2.0), Vector2(largeur, h))
	# Rubans latéraux (triangles sombres derrière).
	for cote: float in [-1.0, 1.0]:
		var x := centre.x + cote * (largeur / 2.0 - 4.0)
		c.draw_colored_polygon(PackedVector2Array([
			Vector2(x, rect.position.y + 6.0),
			Vector2(x + cote * 22.0, centre.y),
			Vector2(x, rect.end.y - 6.0),
		]), Identite.OR_SOMBRE.darkened(0.25))
	bouton(c, rect, Identite.OR, "banniere", false, Identite.RAYON_SM)
	texte(c, centre + Vector2(0.0, taille * 0.36), txt, taille, Identite.TEXTE, true, 7)


## Hexagone d'icône (le « ? » violet du panneau de question de la planche).
static func hexagone(c: Control, centre: Vector2, rayon: float, fond: Color, txt: String, taille := 22) -> void:
	var pts := PackedVector2Array()
	var pts_bord := PackedVector2Array()
	for i in 6:
		var dir := Vector2.from_angle(-PI / 2.0 + TAU * i / 6.0)
		pts.append(centre + dir * rayon)
		pts_bord.append(centre + dir * (rayon + 3.0))
	c.draw_colored_polygon(pts_bord, Identite.CONTOUR)
	c.draw_colored_polygon(pts, fond)
	texte(c, centre + Vector2(0.0, taille * 0.36), txt, taille, Identite.TEXTE, true, 4)


## Éclair (icône énergie de la planche), pointe vers le bas.
static func eclair(c: Control, centre: Vector2, taille: float, teinte: Color) -> void:
	var e := taille
	var pts := PackedVector2Array([
		centre + Vector2(0.1 * e, -0.5 * e), centre + Vector2(-0.35 * e, 0.1 * e),
		centre + Vector2(-0.05 * e, 0.1 * e), centre + Vector2(-0.1 * e, 0.5 * e),
		centre + Vector2(0.35 * e, -0.1 * e), centre + Vector2(0.05 * e, -0.1 * e),
	])
	var pts_bord := PackedVector2Array()
	for p in pts:
		pts_bord.append(centre + (p - centre) * 1.25)
	c.draw_colored_polygon(pts_bord, Identite.CONTOUR)
	c.draw_colored_polygon(pts, teinte)


## Fenêtre standard de la planche : panneau + bandeau de titre + X rouge.
## Retourne le rect du bouton de fermeture (pour la gestion du toucher).
static func fenetre(c: Control, rect: Rect2, titre: String) -> Rect2:
	panneau(c, rect)
	c.draw_style_box(style("fenetre_titre", Identite.PANNEAU_CLAIR, Identite.CONTOUR, Identite.RAYON_SM, Identite.BORD, 0),
		Rect2(rect.position + Vector2(14.0, -16.0), Vector2(rect.size.x - 74.0, 44.0)))
	texte(c, Vector2(rect.position.x + 14.0 + (rect.size.x - 74.0) / 2.0, rect.position.y + 14.0),
		titre, 20, Identite.TEXTE, true)
	var croix := Rect2(rect.end.x - 50.0, rect.position.y - 16.0, 44.0, 44.0)
	bouton(c, croix, Identite.ROUGE, "fermer", false, Identite.RAYON_SM)
	texte(c, croix.get_center() + Vector2(0.0, 8.0), "✕", 22, Identite.TEXTE, true)
	return croix


## Coffre de récompense de la planche (fenêtre cadeau) : rayons + coffre or.
static func coffre(c: Control, centre: Vector2, taille: float, ouvert := false) -> void:
	# Rayons lumineux derrière le coffre.
	for i in 8:
		var dir := Vector2.from_angle(TAU * i / 8.0 + Time.get_ticks_msec() / 3000.0)
		c.draw_colored_polygon(PackedVector2Array([
			centre, centre + dir.rotated(0.12) * taille * 1.6, centre + dir.rotated(-0.12) * taille * 1.6,
		]), Color(Identite.OR.r, Identite.OR.g, Identite.OR.b, 0.10))
	var l := taille
	var corps := Rect2(centre + Vector2(-l / 2.0, -l * 0.15), Vector2(l, l * 0.55))
	var couvercle := Rect2(centre + Vector2(-l / 2.0, -l * (0.62 if ouvert else 0.45)), Vector2(l, l * 0.34))
	c.draw_style_box(style("coffre", Identite.OR_SOMBRE, Identite.CONTOUR, Identite.RAYON_SM, Identite.BORD_FORT, 4), corps)
	c.draw_style_box(style("coffre_couvercle", Identite.OR, Identite.CONTOUR, Identite.RAYON_SM, Identite.BORD_FORT, 3), couvercle)
	c.draw_circle(centre + Vector2(0.0, l * 0.08), l * 0.1 + 3.0, Identite.CONTOUR)
	c.draw_circle(centre + Vector2(0.0, l * 0.08), l * 0.1, Identite.CYAN)


## Icônes des trois pouvoirs (partagées HUD / écran Pouvoirs).
static func icone_pouvoir(c: Control, p: Vector2, r: float, action: String) -> void:
	match action:
		"onde":
			for i in 3:
				c.draw_arc(p + Vector2(-r * 0.3, 0.0), r * (0.25 + 0.18 * i), -0.7, 0.7, 10, Identite.CONTOUR, 4.0)
		"dash":
			for i in 2:
				var px := p + Vector2(-r * 0.35 + i * r * 0.4, 0.0)
				c.draw_line(px + Vector2(-r * 0.2, -r * 0.35), px + Vector2(r * 0.15, 0.0), Identite.CONTOUR, 5.0)
				c.draw_line(px + Vector2(-r * 0.2, r * 0.35), px + Vector2(r * 0.15, 0.0), Identite.CONTOUR, 5.0)
		"bouclier":
			c.draw_colored_polygon(PackedVector2Array([
				p + Vector2(-r * 0.4, -r * 0.35), p + Vector2(r * 0.4, -r * 0.35),
				p + Vector2(r * 0.4, r * 0.1), p + Vector2(0.0, r * 0.45), p + Vector2(-r * 0.4, r * 0.1),
			]), Identite.CONTOUR)


## Pastille-indicateur du haut de la planche (trophées, pièces, œufs…).
## `icone` : "etoile" (trophées) ou "piece" (pièce d'or).
static func indicateur(c: Control, rect: Rect2, teinte: Color, valeur: String, icone := "etoile") -> void:
	c.draw_style_box(style("indicateur", Identite.NUIT, Identite.CONTOUR, 18, Identite.BORD, 3), rect)
	var centre_icone := rect.position + Vector2(20.0, rect.size.y / 2.0)
	if icone == "piece":
		c.draw_circle(centre_icone, 13.0, Identite.CONTOUR)
		c.draw_circle(centre_icone, 10.0, teinte)
		c.draw_circle(centre_icone, 6.0, teinte.darkened(0.25))
	else:
		etoile(c, centre_icone, 11.0, teinte)
	texte(c, Vector2(rect.position.x + 40.0, rect.size.y / 2.0 + rect.position.y + 6.0), valeur, 16, Identite.TEXTE)


## CAPSULE DE RESSOURCE de la planche : gélule sombre, icône ronde à
## gauche, valeur, bouton « + » vert à droite (l'action est posée par
## l'appelant sur tout le rect).
static func capsule(c: Control, rect: Rect2, teinte: Color, valeur: String,
		icone := "piece", avec_plus := true) -> void:
	c.draw_style_box(style("capsule", Identite.NUIT, Identite.CONTOUR, 20, Identite.BORD, 3), rect)
	var centre_icone := rect.position + Vector2(rect.size.y / 2.0, rect.size.y / 2.0)
	match icone:
		"piece":
			c.draw_circle(centre_icone, 13.0, Identite.CONTOUR)
			c.draw_circle(centre_icone, 10.0, teinte)
			c.draw_circle(centre_icone, 6.0, teinte.darkened(0.25))
		"gemme":
			var pts := PackedVector2Array()
			for i in 6:
				pts.append(centre_icone + Vector2.from_angle(-PI / 2.0 + TAU * i / 6.0) * 12.0)
			c.draw_colored_polygon(pts, teinte)
		_:
			etoile(c, centre_icone, 11.0, teinte)
	texte(c, Vector2(rect.position.x + rect.size.y - 4.0, rect.get_center().y + 6.0), valeur, 17, Identite.TEXTE)
	if avec_plus:
		var centre_plus := Vector2(rect.end.x - rect.size.y / 2.0, rect.get_center().y)
		c.draw_circle(centre_plus, 12.0, Identite.CONTOUR)
		c.draw_circle(centre_plus, 9.5, Identite.VERT)
		texte(c, centre_plus + Vector2(0.0, 6.0), "+", 18, Identite.TEXTE, true, 3)


## Badge de notification rouge (pastille à compteur de la planche).
static func badge_notif(c: Control, centre: Vector2, txt: String) -> void:
	c.draw_circle(centre, 15.0, Identite.CONTOUR)
	c.draw_circle(centre, 12.0, Identite.ROUGE)
	c.draw_circle(centre + Vector2(0.0, -4.0), 6.0, Color(1.0, 1.0, 1.0, 0.25))
	texte(c, centre + Vector2(0.0, 5.5), txt, 14, Identite.TEXTE, true, 3)


## Badge de rareté de la planche : étiquette arrondie, étoile + nom.
static func badge_rarete(c: Control, centre: Vector2, rarete: String, taille := 12) -> void:
	var teinte: Color = Identite.RARETES.get(rarete, Identite.VERT)
	var l := taille * 0.62 * (rarete.length() + 3.4)
	var rect := Rect2(centre - Vector2(l / 2.0, taille * 0.95), Vector2(l, taille * 1.9))
	c.draw_style_box(style("rarete_%s" % rarete, teinte.darkened(0.25), Identite.CONTOUR, 9, 2, 2), rect)
	etoile(c, Vector2(rect.position.x + taille * 0.95, centre.y), taille * 0.52, Identite.OR, false)
	texte(c, Vector2(rect.position.x + taille * 1.75, centre.y + taille * 0.42),
		rarete.to_upper(), taille, Identite.TEXTE, false, 3)


## BARRE DE STATS SEGMENTÉE de la planche : 10 crans + valeur à droite.
static func barre_stat(c: Control, rect: Rect2, ratio: float, teinte: Color) -> void:
	c.draw_style_box(style("stat_fond", Identite.NUIT, Identite.CONTOUR, 6, 2, 0), rect)
	var n := 10
	var pas := (rect.size.x - 8.0) / float(n)
	var pleins := int(round(clampf(ratio, 0.0, 1.0) * n))
	for i in n:
		if i >= pleins:
			break
		var seg := Rect2(rect.position + Vector2(4.0 + i * pas, 3.0), Vector2(pas - 2.0, rect.size.y - 6.0))
		c.draw_rect(seg, teinte if i < pleins else Color(0.2, 0.24, 0.38))
		c.draw_rect(Rect2(seg.position, Vector2(seg.size.x, seg.size.y * 0.42)), Color(1.0, 1.0, 1.0, 0.2))


## CAPSULE DE NIVEAU de la planche : « ★ Niveau X » + barre d'XP.
static func capsule_niveau(c: Control, rect: Rect2, niveau: int, progres: float) -> void:
	etoile(c, rect.position + Vector2(10.0, rect.size.y * 0.3), 9.0, Identite.OR)
	texte(c, rect.position + Vector2(24.0, rect.size.y * 0.3 + 6.0), "Niveau %d" % niveau, 15, Identite.OR)
	barre(c, Rect2(rect.position + Vector2(0.0, rect.size.y * 0.55), Vector2(rect.size.x, rect.size.y * 0.45)),
		progres, Identite.BLEU)


## Triangle « lecture » du bouton JOUER de la planche.
static func triangle_jouer(c: Control, centre: Vector2, taille: float, teinte: Color) -> void:
	var pts := PackedVector2Array([
		centre + Vector2(-taille * 0.42, -taille * 0.55),
		centre + Vector2(taille * 0.62, 0.0),
		centre + Vector2(-taille * 0.42, taille * 0.55),
	])
	var bord := PackedVector2Array()
	for p in pts:
		bord.append(centre + (p - centre) * 1.2)
	c.draw_colored_polygon(bord, Identite.CONTOUR)
	c.draw_colored_polygon(pts, teinte)


## Petites icônes de navigation du lobby (planche : icône + libellé).
static func icone_menu(c: Control, p: Vector2, r: float, type: String) -> void:
	match type:
		"personnages": # tête ronde + épaules
			c.draw_circle(p + Vector2(0.0, -r * 0.25), r * 0.42, Identite.CREME)
			c.draw_circle(p + Vector2(0.0, r * 0.55), r * 0.62, Identite.CREME)
			c.draw_rect(Rect2(p + Vector2(-r * 0.7, r * 0.55), Vector2(r * 1.4, r * 0.5)), Identite.CONTOUR)
		"sanctuaire": # œuf
			c.draw_circle(p + Vector2(0.0, r * 0.15), r * 0.52, Identite.CREME)
			c.draw_circle(p + Vector2(0.0, -r * 0.15), r * 0.42, Identite.CREME)
			c.draw_circle(p + Vector2(-r * 0.15, -r * 0.2), r * 0.14, Color(1.0, 1.0, 1.0, 0.6))
		"boutique": # mini coffre
			c.draw_rect(Rect2(p + Vector2(-r * 0.55, -r * 0.1), Vector2(r * 1.1, r * 0.65)), Identite.OR_SOMBRE)
			c.draw_rect(Rect2(p + Vector2(-r * 0.55, -r * 0.45), Vector2(r * 1.1, r * 0.32)), Identite.OR)
			c.draw_circle(p + Vector2(0.0, 0.05 * r), r * 0.14, Identite.CYAN)
		"route": # trophée-étoile
			etoile(c, p, r * 0.55, Identite.OR, false)
		"quetes": # livre ouvert
			c.draw_rect(Rect2(p + Vector2(-r * 0.6, -r * 0.4), Vector2(r * 0.55, r * 0.85)), Identite.CREME)
			c.draw_rect(Rect2(p + Vector2(0.05 * r, -r * 0.4), Vector2(r * 0.55, r * 0.85)), Identite.CREME.darkened(0.12))


## Étoile à cinq branches (logo, podium).
static func etoile(c: Control, centre: Vector2, rayon: float, teinte: Color, contour := true) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var r := rayon if i % 2 == 0 else rayon * 0.45
		pts.append(centre + Vector2.from_angle(-PI / 2.0 + TAU * i / 10.0) * r)
	if contour:
		var pts_bord := PackedVector2Array()
		for p in pts:
			pts_bord.append(centre + (p - centre) * 1.22)
		c.draw_colored_polygon(pts_bord, Identite.CONTOUR)
	c.draw_colored_polygon(pts, teinte)

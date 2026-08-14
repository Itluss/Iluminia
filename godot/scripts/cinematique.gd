class_name Cinematique
extends RefCounted
## LE CINEMATIC LEARNING ENGINE — moteur générique de cinématiques
## pédagogiques d'Illuminia.
##
## « Ne code pas une vidéo sur les fractions. Code un langage visuel
## capable d'enseigner. » Ce fichier est le MOTEUR : il ne connaît
## AUCUNE leçon. Une leçon (lecons.gd) est un pur scénario de données :
##   { id, competence_id, theme, objectif, scenes: [
##       { id, duree (s), attente?, camera?, narration: [{a, texte}],
##         acteurs: [{id, type, pos {x,y} 0..100, taille, props}],
##         actions: [{a, acteur, type, valeur?, duree?}], bouton_fin? } ] }
##
## ACTEURS v1  : plateforme, cercle (FractionCircle génératif — jamais
##               d'images figées), fraction (FractionDisplay), droite
##               (NumberLine), repere, etiquette, symbole, bulle, hibou.
## ACTIONS v1  : apparaitre, disparaitre, deplacer, echelle, decouper,
##               colorier, detacher, surligner, eteindre, tracer,
##               impulsion.
## Les positions vivent dans un espace logique 0..100 indépendant de la
## résolution ; le rendu les convertit (caméra légère : zoom + centre).
## Les acteurs PERSISTENT entre les scènes (continuité cinématique : les
## gâteaux de la scène 1 deviennent ceux de la scène 2) — une scène
## AJOUTE des acteurs, la timeline les masque (« disparaitre »).

## Thèmes : l'accent change, la structure Illuminia reste.
const THEMES := {
	"fractions": {"primaire": Color("8a55f5"), "secondaire": Color("20cff3"),
		"important": Color("ffc928"), "reussite": Color("53cc55")},
	"nombres": {"primaire": Color("258cff"), "secondaire": Color("20cff3"),
		"important": Color("ffc928"), "reussite": Color("53cc55")},
	"geometrie": {"primaire": Color("20cff3"), "secondaire": Color("8a55f5"),
		"important": Color("ffc928"), "reussite": Color("53cc55")},
}


## LE PLAYER : charge la leçon, instancie les acteurs, exécute la
## timeline, gère narration, pause, replay, saut de leçon et la fin.
class Player extends RefCounted:
	var lecon := {}
	var theme := {}
	var indice_scene := 0
	var t := 0.0                 ## temps local à la scène (s)
	var pause := false
	var finie := false           ## dernière scène atteinte (bouton_fin visible)
	var zoom := 1.0
	var acteurs := {}            ## id → état d'exécution
	var _ordre: Array = []       ## ordre d'affichage (insertion)
	var _anims: Array = []       ## interpolations actives
	var _faites := {}            ## indices d'actions déjà lancées (par scène)

	func _init(definition: Dictionary) -> void:
		lecon = definition
		theme = Cinematique.THEMES.get(str(lecon.get("theme", "fractions")),
			Cinematique.THEMES.fractions)
		_entrer_scene(0)

	func scene() -> Dictionary:
		var scenes: Array = lecon.scenes
		return scenes[clampi(indice_scene, 0, scenes.size() - 1)]

	func derniere_scene() -> bool:
		return indice_scene >= (lecon.scenes as Array).size() - 1

	## Le temps avance, les actions programmées se lancent, les
	## interpolations progressent, la scène suivante s'enchaîne (sans
	## écran noir : les acteurs persistent).
	func maj(delta: float) -> void:
		if pause or (finie and derniere_scene() and t >= float(scene().duree)):
			return
		t += delta
		var s := scene()
		var actions: Array = s.get("actions", [])
		for i in actions.size():
			var a: Dictionary = actions[i]
			if float(a.get("a", 0.0)) <= t and not _faites.has(i):
				_faites[i] = true
				_lancer(a)
		for anim in _anims.duplicate():
			var etat: Dictionary = acteurs.get(str(anim.acteur), {})
			if etat.is_empty():
				_anims.erase(anim)
				continue
			var k := clampf((t - float(anim.t0)) / maxf(float(anim.duree), 0.001), 0.0, 1.0)
			var doux := k * k * (3.0 - 2.0 * k)
			etat[anim.prop] = lerpf(float(anim.de), float(anim.vers), doux)
			if k >= 1.0:
				_anims.erase(anim)
		var cible_zoom := float(s.get("camera", {}).get("zoom", 1.0))
		zoom = move_toward(zoom, cible_zoom, delta * 0.5)
		if t >= float(s.duree):
			if derniere_scene():
				finie = true
			elif not bool(s.get("attente", false)):
				_entrer_scene(indice_scene + 1)

	## Avance rapide (reprise, crochets de capture).
	func aller_a(temps_global: float) -> void:
		var restant := temps_global
		while restant > 0.0 and not (finie and derniere_scene()):
			maj(0.05)
			restant -= 0.05

	func rejouer() -> void:
		acteurs = {}
		_ordre = []
		_anims = []
		finie = false
		zoom = 1.0
		_entrer_scene(0)

	func _entrer_scene(indice: int) -> void:
		indice_scene = indice
		t = 0.0
		_faites = {}
		_anims = []
		for a in scene().get("acteurs", []):
			var id := str(a.id)
			if not acteurs.has(id):
				# Copie profonde : les leçons sont des const (lecture seule),
				# l'état d'exécution doit pouvoir muter (decouper…).
				acteurs[id] = {"def": (a as Dictionary).duplicate(true), "alpha": 0.0,
					"x": float(a.pos.x), "y": float(a.pos.y), "echelle": 1.0,
					"decoupe": 0.0, "remplies": 0.0, "detache": 0.0,
					"brillance": 0.0, "trace": 0.0, "pulse": -10.0}
				_ordre.append(id)

	## Interprète UNE action de la timeline — le vocabulaire du moteur.
	func _lancer(a: Dictionary) -> void:
		var id := str(a.get("acteur", ""))
		var etat: Dictionary = acteurs.get(id, {})
		if etat.is_empty():
			return
		var duree := float(a.get("duree", 0.45))
		match str(a.type):
			"apparaitre":
				_animer(id, "alpha", float(etat.alpha), 1.0, duree)
				_animer(id, "echelle", 0.88, 1.0, duree)
			"disparaitre":
				_animer(id, "alpha", float(etat.alpha), 0.0, duree)
			"deplacer":
				_animer(id, "x", float(etat.x), float(a.valeur.x), maxf(duree, 0.6))
				_animer(id, "y", float(etat.y), float(a.valeur.y), maxf(duree, 0.6))
			"echelle":
				_animer(id, "echelle", float(etat.echelle), float(a.valeur), duree)
			"decouper":
				# TOUT → DÉCOUPE → PARTS ÉGALES : la transformation se VOIT.
				etat.def.props.parts = int(a.valeur)
				_animer(id, "decoupe", 0.0, 1.0, maxf(duree, 1.2))
			"colorier":
				_animer(id, "remplies", float(etat.remplies), float(a.valeur), maxf(duree, 1.2))
			"detacher":
				_animer(id, "detache", float(etat.detache), float(a.get("valeur", 1.0)), maxf(duree, 0.8))
			"surligner":
				_animer(id, "brillance", float(etat.brillance), 1.0, duree)
			"eteindre":
				_animer(id, "brillance", float(etat.brillance), 0.0, duree)
			"tracer":
				_animer(id, "trace", 0.0, 1.0, maxf(duree, 1.0))
			"impulsion":
				etat.pulse = t

	func _animer(id: String, prop: String, de: float, vers: float, duree: float) -> void:
		_anims.append({"acteur": id, "prop": prop, "de": de, "vers": vers,
			"t0": t, "duree": duree})

	## Sous-titre courant : la narration est une liste {a, texte}.
	func narration() -> String:
		var texte := ""
		for n in scene().get("narration", []):
			if float(n.get("a", 0.0)) <= t:
				texte = str(n.texte)
		return texte

	# ------------------------------------------------------------ rendu

	## Dessine la scène complète dans `zone` (le SceneRenderer).
	## `c` est la surface Illuminia (les helpers UI/pictos existent).
	func dessiner(c: Control, zone: Rect2, temps: float) -> void:
		_decor(c, zone, temps)
		for id in _ordre:
			var etat: Dictionary = acteurs[id]
			if float(etat.alpha) <= 0.01:
				continue
			_dessiner_acteur(c, zone, etat, temps)

	## Conversion espace logique 0..100 → écran, avec la caméra légère.
	func _pos(zone: Rect2, x: float, y: float) -> Vector2:
		var s := scene()
		var centre: Vector2 = Vector2(s.get("camera", {}).get("centre", {}).get("x", 50.0),
			s.get("camera", {}).get("centre", {}).get("y", 50.0)) / 100.0
		var p := Vector2(x, y) / 100.0
		p = centre + (p - centre) * zoom
		return zone.position + p * zone.size

	func _dim(zone: Rect2, taille: float) -> float:
		return taille / 100.0 * zone.size.y * zoom

	## LA PETITE SALLE MAGIQUE : profondeur, halo du thème, colonnes très
	## discrètes, particules — le décor n'est jamais l'objet principal.
	func _decor(c: Control, zone: Rect2, temps: float) -> void:
		var prim: Color = theme.primaire
		UI.rect_degrade(c, zone, 14.0, Color("0a1030"), Color("160e3c"))
		UI.contour_arrondi(c, zone, 14.0, Color("2a2360"), 2.0)
		c.draw_circle(zone.get_center(), zone.size.y * 0.55,
			Color(prim.r, prim.g, prim.b, 0.06))
		# Colonnes en silhouette aux bords.
		for cote: float in [0.045, 0.955]:
			var x := zone.position.x + zone.size.x * cote
			c.draw_rect(Rect2(x - 7.0, zone.position.y + zone.size.y * 0.16, 14.0,
				zone.size.y * 0.7), Color(0.16, 0.12, 0.34, 0.5))
			c.draw_rect(Rect2(x - 11.0, zone.position.y + zone.size.y * 0.14, 22.0, 7.0),
				Color(0.2, 0.15, 0.4, 0.5))
			c.draw_rect(Rect2(x - 11.0, zone.position.y + zone.size.y * 0.84, 22.0, 7.0),
				Color(0.2, 0.15, 0.4, 0.5))
		# Lueur du sol + particules lentes.
		c.draw_circle(zone.get_center() + Vector2(0.0, zone.size.y * 0.42),
			zone.size.x * 0.3, Color(prim.r, prim.g, prim.b, 0.05))
		for i in 14:
			var gx := fposmod(sin(i * 83.7) * 511.0, 1.0)
			var gy := fposmod(cos(i * 47.3) * 733.0 - temps * 0.014 * (1.0 + i * 0.2), 1.0)
			var a := 0.1 + 0.08 * sin(temps * 1.5 + i)
			c.draw_circle(zone.position + Vector2(gx, gy) * zone.size, 1.5,
				Color(prim.r, prim.g, prim.b, a))

	func _dessiner_acteur(c: Control, zone: Rect2, etat: Dictionary, temps: float) -> void:
		var def: Dictionary = etat.def
		var props: Dictionary = def.get("props", {})
		var alpha := float(etat.alpha)
		var p := _pos(zone, float(etat.x), float(etat.y))
		var pulse := 1.0 + 0.1 * maxf(0.0, 1.0 - (t - float(etat.pulse)) * 2.5) \
			* sin((t - float(etat.pulse)) * 18.0)
		var r := _dim(zone, float(def.get("taille", 10.0))) * float(etat.echelle) * pulse
		match str(def.type):
			"plateforme":
				_plateforme(c, p, r, alpha)
			"cercle":
				_cercle_fraction(c, p, r, etat, props, alpha, temps)
			"fraction":
				_fraction(c, p, int(props.get("num", 1)), int(props.get("den", 1)), r,
					_teinte(props), alpha, float(etat.brillance))
			"droite":
				_droite(c, zone, p, etat, props, alpha)
			"repere":
				_repere(c, p, _dim(zone, float(props.get("hauteur", 30.0))), alpha)
			"etiquette":
				_etiquette(c, p, str(props.get("texte", "")), r, str(props.get("style", "")), alpha)
			"symbole":
				_symbole(c, p, str(props.get("texte", "?")), r, _teinte(props), alpha)
			"bulle":
				_bulle(c, p, props.get("lignes", []), r, alpha)
			"hibou":
				if alpha > 0.5 and c.has_method("_hibou"):
					c._hibou(p, r)

	func _teinte(props: Dictionary) -> Color:
		var cle := str(props.get("teinte", "primaire"))
		return theme.get(cle, theme.primaire)

	## MagicPlatform : petite plateforme de pierre violette.
	func _plateforme(c: Control, p: Vector2, r: float, alpha: float) -> void:
		c.draw_set_transform(p + Vector2(0.0, 4.0), 0.0, Vector2(1.0, 0.42))
		c.draw_circle(Vector2.ZERO, r, Color(0.1, 0.07, 0.22, 0.75 * alpha))
		c.draw_set_transform(p, 0.0, Vector2(1.0, 0.42))
		c.draw_circle(Vector2.ZERO, r, Color(0.28, 0.2, 0.5, alpha))
		c.draw_circle(Vector2.ZERO, r * 0.82, Color(0.36, 0.26, 0.62, alpha))
		c.draw_arc(Vector2.ZERO, r * 0.94, 0.0, TAU, 40, Color(0.55, 0.4, 0.9, 0.5 * alpha), 2.0)
		c.draw_set_transform_matrix(Transform2D())

	## FractionCircle GÉNÉRATIF (jamais cake_3_4.png) : le « gâteau »
	## est dessiné — parts, découpe animée, part détachée, remplissage.
	func _cercle_fraction(c: Control, p: Vector2, r: float, etat: Dictionary,
			props: Dictionary, alpha: float, temps: float) -> void:
		var parts := maxi(int(props.get("parts", 1)), 1)
		var decoupe := float(etat.decoupe)
		var remplies := float(etat.remplies)
		var detache := float(etat.detache)
		var teinte := _teinte(props)
		var aplati := 0.66
		if float(etat.brillance) > 0.0:
			c.draw_set_transform(p, 0.0, Vector2(1.0, aplati))
			c.draw_circle(Vector2.ZERO, r * 1.3,
				Color(teinte.r, teinte.g, teinte.b, 0.16 * float(etat.brillance) * alpha))
			c.draw_set_transform_matrix(Transform2D())
		for i in parts:
			var a0 := -PI / 2.0 + TAU * i / parts
			var a1 := a0 + TAU / parts
			var bissectrice := Vector2.from_angle((a0 + a1) / 2.0)
			var dec := bissectrice * r * 0.09 * decoupe if parts > 1 else Vector2.ZERO
			if i == 0 and detache > 0.0:
				dec += Vector2(bissectrice.x, absf(bissectrice.y)) * r * 0.85 * detache
			var pts := PackedVector2Array([dec])
			for e in 13:
				pts.append(dec + Vector2.from_angle(a0 + (a1 - a0) * e / 12.0) * r)
			# Croûte (épaisseur) puis surface — l'objet a du volume.
			c.draw_set_transform(p + Vector2(0.0, r * 0.16), 0.0, Vector2(1.0, aplati))
			c.draw_colored_polygon(pts, Color(0.62, 0.42, 0.2, alpha))
			c.draw_set_transform(p, 0.0, Vector2(1.0, aplati))
			c.draw_colored_polygon(pts, Color(0.91, 0.76, 0.47, alpha))
			var interieur := pts.duplicate()
			for e in interieur.size():
				interieur[e] = dec + (interieur[e] - dec) * 0.86
			c.draw_colored_polygon(interieur, Color(0.95, 0.83, 0.55, alpha))
			# Remplissage lumineux : la FRACTION prend vie (3 sur 4…).
			var visible_rempli := clampf(remplies - i, 0.0, 1.0)
			if visible_rempli > 0.0:
				c.draw_colored_polygon(pts,
					Color(teinte.r, teinte.g, teinte.b, 0.78 * visible_rempli * alpha))
				c.draw_polyline(pts + PackedVector2Array([pts[0]]),
					Color(teinte.lightened(0.3).r, teinte.lightened(0.3).g,
					teinte.lightened(0.3).b, visible_rempli * alpha), 2.5)
			elif parts > 1 and decoupe > 0.0:
				c.draw_polyline(pts + PackedVector2Array([pts[0]]),
					Color(0.42, 0.27, 0.12, 0.85 * decoupe * alpha), 2.0)
			c.draw_set_transform_matrix(Transform2D())
		if parts == 1:
			c.draw_set_transform(p, 0.0, Vector2(1.0, aplati))
			c.draw_arc(Vector2.ZERO, r * 0.95, 0.0, TAU, 40, Color(0.62, 0.42, 0.2, 0.9 * alpha), 2.0)
			# Motif « fleur » discret de la planche.
			for e in 6:
				c.draw_line(Vector2.ZERO, Vector2.from_angle(TAU * e / 6.0) * r * 0.5,
					Color(0.8, 0.62, 0.34, 0.5 * alpha), 1.5)
			c.draw_set_transform_matrix(Transform2D())

	## FractionDisplay : numérateur / barre / dénominateur — toujours la
	## vraie écriture mathématique, contraste maximal (contour sombre).
	func _fraction(c: Control, p: Vector2, num: int, den: int, r: float,
			teinte: Color, alpha: float, brillance: float) -> void:
		var fond := Rect2(p - Vector2(r * 0.85, r * 1.15), Vector2(r * 1.7, r * 2.3))
		UI.rect_degrade(c, fond, 8.0, Color(0.06, 0.09, 0.25, 0.85 * alpha),
			Color(0.04, 0.06, 0.18, 0.85 * alpha))
		UI.contour_arrondi(c, fond, 8.0, Color(teinte.r, teinte.g, teinte.b, 0.9 * alpha), 2.0)
		if brillance > 0.0:
			# Correction de misconception : l'anneau désigne le DÉNOMINATEUR.
			c.draw_arc(p + Vector2(0.0, r * 0.62), r * 0.55, 0.0, TAU, 24,
				Color(1.0, 0.79, 0.16, brillance * alpha), 3.0)
		var encre := Color(teinte.lightened(0.25).r, teinte.lightened(0.25).g,
			teinte.lightened(0.25).b, alpha)
		UI.texte(c, p + Vector2(0.0, -r * 0.28), str(num), int(r * 0.78), encre, true)
		c.draw_rect(Rect2(p + Vector2(-r * 0.5, -r * 0.05), Vector2(r, maxf(r * 0.09, 2.0))), encre)
		UI.texte(c, p + Vector2(0.0, r * 0.92), str(den), int(r * 0.78), encre, true)

	## NumberLine : 0 → 1, remplissage animé jusqu'à la valeur.
	func _droite(c: Control, zone: Rect2, p: Vector2, etat: Dictionary,
			props: Dictionary, alpha: float) -> void:
		var largeur := float(props.get("largeur", 60.0)) / 100.0 * zone.size.x * zoom
		var valeur := float(props.get("valeur", 0.5))
		var trace := float(etat.trace)
		var teinte := _teinte(props)
		var a := p - Vector2(largeur / 2.0, 0.0)
		var b := p + Vector2(largeur / 2.0, 0.0)
		c.draw_line(a, b, Color(0.35, 0.37, 0.6, alpha), 4.0)
		for g in 5:
			var xg := a.lerp(b, g / 4.0)
			c.draw_line(xg + Vector2(0, -5), xg + Vector2(0, 5), Color(0.45, 0.47, 0.7, alpha), 2.0)
		var bout := a.lerp(b, valeur * trace)
		if trace > 0.0:
			c.draw_line(a, bout, Color(teinte.r, teinte.g, teinte.b, alpha), 5.0)
			c.draw_line(a, bout, Color(teinte.r, teinte.g, teinte.b, 0.3 * alpha), 10.0)
			c.draw_circle(bout, 7.0, Color(teinte.lightened(0.2).r, teinte.lightened(0.2).g,
				teinte.lightened(0.2).b, alpha))
			c.draw_circle(bout, 3.0, Color(1, 1, 1, alpha))
		UI.texte(c, a + Vector2(-4.0, 22.0), "0", 11, Color(0.8, 0.83, 1.0, alpha), true)
		UI.texte(c, b + Vector2(4.0, 22.0), "1", 11, Color(0.8, 0.83, 1.0, alpha), true)

	## Le trait vertical qui montre « 3/4 va plus loin que 2/3 ».
	func _repere(c: Control, p: Vector2, hauteur: float, alpha: float) -> void:
		var seg := 6.0
		var y := p.y - hauteur / 2.0
		while y < p.y + hauteur / 2.0:
			c.draw_line(Vector2(p.x, y), Vector2(p.x, minf(y + seg, p.y + hauteur / 2.0)),
				Color(1.0, 0.79, 0.16, 0.85 * alpha), 2.0)
			y += seg * 2.0
		UI.etoile(c, p + Vector2(0.0, -hauteur / 2.0 - 8.0), 6.0,
			Color(1.0, 0.79, 0.16, alpha), false)

	## Étiquette-pill (« en 4 parts égales ») ou bandeau or (conclusion).
	func _etiquette(c: Control, p: Vector2, texte: String, r: float, style: String,
			alpha: float) -> void:
		var largeur := texte.length() * r * 0.62 + r * 2.4
		var rect := Rect2(p - Vector2(largeur / 2.0, r * 1.05), Vector2(largeur, r * 2.1))
		if style == "or":
			UI.rect_degrade(c, rect.grow(3.0), 14.0, Color(1.0, 0.79, 0.16, 0.3 * alpha),
				Color(1.0, 0.79, 0.16, 0.1 * alpha))
			UI.rect_degrade(c, rect, 12.0, Color(0.24, 0.18, 0.05, 0.95 * alpha),
				Color(0.16, 0.12, 0.03, 0.95 * alpha))
			UI.contour_arrondi(c, rect, 12.0, Color(1.0, 0.79, 0.16, alpha), 2.0)
			UI.texte(c, p + Vector2(0.0, r * 0.42), texte, int(r * 1.15),
				Color(1.0, 0.85, 0.3, alpha), true, 2)
		else:
			UI.rect_degrade(c, rect, 10.0, Color(0.35, 0.24, 0.62, 0.92 * alpha),
				Color(0.22, 0.15, 0.42, 0.92 * alpha))
			UI.contour_arrondi(c, rect, 10.0, Color(0.62, 0.45, 0.95, 0.8 * alpha), 1.5)
			UI.texte(c, p + Vector2(0.0, r * 0.4), texte, int(r * 1.05),
				Color(1, 1, 1, alpha), true, 1)

	## Symbole de comparaison (>, ≠, ?) — or, relief, glow subtil.
	func _symbole(c: Control, p: Vector2, texte: String, r: float, teinte: Color,
			alpha: float) -> void:
		c.draw_circle(p, r * 1.5, Color(teinte.r, teinte.g, teinte.b, 0.12 * alpha))
		for dec in [Vector2(-2, 0), Vector2(2, 0), Vector2(0, -2), Vector2(0, 2)]:
			UI.texte(c, p + Vector2(0.0, r * 0.72) + dec, texte, int(r * 2.0),
				Color(0.25, 0.16, 0.0, alpha), true)
		UI.texte(c, p + Vector2(0.0, r * 0.72), texte, int(r * 2.0),
			Color(teinte.r, teinte.g, teinte.b, alpha), true)

	## Bulle de dialogue du compagnon (scène finale).
	func _bulle(c: Control, p: Vector2, lignes: Array, r: float, alpha: float) -> void:
		var max_car := 0
		for l in lignes:
			max_car = maxi(max_car, str(l).length())
		var largeur := max_car * r * 0.62 + r * 3.0
		var rect := Rect2(p - Vector2(largeur / 2.0, r * lignes.size() * 0.85 + r * 0.9),
			Vector2(largeur, r * lignes.size() * 1.7 + r * 1.8))
		UI.rect_degrade(c, rect, 12.0, Color(1.0, 0.96, 0.86, 0.96 * alpha),
			Color(0.94, 0.88, 0.74, 0.96 * alpha))
		c.draw_colored_polygon(PackedVector2Array([
			rect.position + Vector2(24.0, rect.size.y - 2.0),
			rect.position + Vector2(44.0, rect.size.y - 2.0),
			rect.position + Vector2(18.0, rect.size.y + 14.0)]),
			Color(0.96, 0.9, 0.78, 0.96 * alpha))
		for i in lignes.size():
			UI.texte(c, Vector2(rect.get_center().x,
				rect.position.y + r * 2.1 + i * r * 1.7), str(lignes[i]),
				int(r * 1.3), Color(0.16, 0.14, 0.3, alpha), true)

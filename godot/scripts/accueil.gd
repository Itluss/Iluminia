class_name Accueil
extends Node3D
## L'ARBRE DES CONNAISSANCES — la Home d'Illuminia, refondue sur la
## maquette « Arbre des connaissances » fournie par Camille.
##
## « L'arbre des connaissances est l'équivalent du skill tree d'un grand
## jeu RPG, mais chaque compétence est une vraie compétence scolaire. »
##
## Structure de l'écran (mobile paysage, aucun défilement) :
##   PROFIL | MON NIVEAU DE CONNAISSANCE (+ prochain déblocage) | RESSOURCES
##   MATIÈRES | CARTE MAGIQUE DES CONNAISSANCES | COMPÉTENCE SÉLECTIONNÉE
##   PALIERS / CONSEILLÉ POUR TOI | MA VILLE / COLLECTION / PROGRESSION
##
## Le LAYOUT visuel (positions des nœuds en % de la zone) est séparé de
## la donnée pédagogique (savoir.gd) : DISPOSITION ci-dessous.

enum Ecran { ARBRE, COLLECTION, PROGRESSION, PARENT }

## Couleur d'énergie de chaque branche (teinte connexions, bandeaux,
## halos et anneaux — dans le design system Illuminia).
const COULEURS_BRANCHES := {
	"nombres_calculs": Color("258cff"), "fractions": Color("8a55f5"),
	"geometrie": Color("20cff3"),
}

## LAYOUT de l'arbre : position de chaque nœud en % de la zone centrale.
## Configuration d'AFFICHAGE — jamais dans le modèle métier (savoir.gd).
const DISPOSITION := {
	"nombres_calculs": {"bandeau": Vector2(0.46, 0.0), "noeuds": {
		"nb_lire": Vector2(0.06, 0.135), "nb_comparer": Vector2(0.27, 0.155),
		"nb_addsous": Vector2(0.47, 0.125), "nb_multiplications": Vector2(0.69, 0.15),
		"nb_divisions": Vector2(0.90, 0.125)}},
	"fractions": {"bandeau": Vector2(0.46, 0.37), "noeuds": {
		"fr_decouvrir": Vector2(0.06, 0.505), "fr_representer": Vector2(0.27, 0.525),
		"fr_comparer": Vector2(0.47, 0.495), "fr_equivalentes": Vector2(0.69, 0.52),
		"fr_additionner": Vector2(0.90, 0.495)}},
	"geometrie": {"bandeau": Vector2(0.46, 0.72), "noeuds": {
		"geo_figures": Vector2(0.06, 0.855), "geo_perimetres": Vector2(0.27, 0.875),
		"geo_aires": Vector2(0.47, 0.845), "geo_angles": Vector2(0.69, 0.87),
		"geo_symetrie": Vector2(0.90, 0.845)}},
}

var ecran := Ecran.ARBRE
var competence_ouverte := ""     ## compétence affichée dans le panneau droit
var surface: SurfaceAccueil


func _ready() -> void:
	var couche := CanvasLayer.new()
	add_child(couche)
	surface = SurfaceAccueil.new()
	surface.accueil = self
	surface.set_anchors_preset(Control.PRESET_FULL_RECT)
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	couche.add_child(surface)
	# Sélection initiale : la compétence en cours de la branche Fractions
	# (celle de la maquette), sinon la recommandation.
	competence_ouverte = "fr_comparer"
	if Savoir.competence(competence_ouverte).is_empty():
		competence_ouverte = Savoir.recommandation()
	# Crochets de dev (captures) : ILUMINIA_CLASSE saute la bienvenue ;
	# ILUMINIA_ECRAN=collection|progression|parent.
	if OS.get_environment("ILUMINIA_CLASSE") != "":
		Profil.classe = OS.get_environment("ILUMINIA_CLASSE")
	match OS.get_environment("ILUMINIA_ECRAN"):
		"collection":
			ecran = Ecran.COLLECTION
		"progression":
			ecran = Ecran.PROGRESSION
		"parent":
			ecran = Ecran.PARENT


func _process(_delta: float) -> void:
	surface.queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		var action := surface.action_sous(event.position)
		if action != "":
			_executer(action)


func _executer(action: String) -> void:
	var morceaux := action.split(":")
	match morceaux[0]:
		"retour":
			Audio.jouer("clic")
			ecran = Ecran.ARBRE
		"collection":
			Audio.jouer("clic")
			ecran = Ecran.COLLECTION
		"progression":
			Audio.jouer("clic")
			ecran = Ecran.PROGRESSION
		"parent":
			Audio.jouer("clic")
			ecran = Ecran.PARENT
		"ville":
			Audio.jouer("clic")
			get_tree().change_scene_to_file.call_deferred("res://scenes/ville.tscn")
		"son":
			Profil.basculer_son()
			Audio.jouer("clic")
		"classe":
			# Classe choisie → LA VILLE, la Home de l'enfant.
			Audio.jouer("victoire")
			Profil.classe = morceaux[1]
			Profil.sauver()
			get_tree().change_scene_to_file.call_deferred("res://scenes/ville.tscn")
		"competence":
			Audio.jouer("clic")
			competence_ouverte = morceaux[1]
		"session":
			# CONTINUER → la session d'apprentissage de la compétence
			# sélectionnée, DIRECTEMENT (aucune page intermédiaire).
			if Savoir.etat(competence_ouverte) == "verrouillee":
				Audio.jouer("denied")
				surface.toast("Débloque d'abord les prérequis de cette compétence !")
			else:
				Audio.jouer("depart")
				_lancer_session()


## Transition courte vers la session : le nœud sélectionné pulse déjà
## (halo doré) ; on ajoute un simple fondu de quelques centaines de ms.
func _lancer_session() -> void:
	OS.set_environment("ILUMINIA_COMPETENCE", competence_ouverte)
	var couche := CanvasLayer.new()
	couche.layer = 10
	add_child(couche)
	var voile := ColorRect.new()
	voile.color = Color(0.02, 0.05, 0.15, 0.0)
	voile.set_anchors_preset(Control.PRESET_FULL_RECT)
	couche.add_child(voile)
	var fondu := create_tween()
	fondu.tween_property(voile, "color:a", 1.0, 0.3)
	fondu.tween_callback(_ouvrir_session)


func _ouvrir_session() -> void:
	get_tree().change_scene_to_file("res://scenes/session.tscn")


## Toute l'interface ; chaque _draw() reconstruit `_actions`.
class SurfaceAccueil extends Control:
	var accueil: Accueil = null
	var _actions: Array = []
	var _toast := ""
	var _toast_temps := 0.0

	## Représentation VISUELLE des états (le métier vit dans savoir.gd).
	const COULEURS_ETATS := {
		"verrouillee": Color("3a3358"), "decouverte": Color("20cff3"),
		"apprentissage": Color("ff9418"), "acquise": Color("53cc55"),
		"maitrisee": Color("ffc928"), "a_consolider": Color("ff9418"),
	}
	const NOMS_ETATS := {
		"verrouillee": "Verrouillée", "decouverte": "À découvrir",
		"apprentissage": "EN APPRENTISSAGE", "acquise": "Acquise",
		"maitrisee": "MAÎTRISÉE", "a_consolider": "À consolider",
	}

	func action_sous(pos: Vector2) -> String:
		for a in _actions:
			var rect: Rect2 = a.rect
			if rect.has_point(pos):
				return str(a.action)
		return ""

	func toast(texte: String) -> void:
		_toast = texte
		_toast_temps = 3.0

	func _t() -> float:
		return Time.get_ticks_msec() / 1000.0

	func _draw() -> void:
		_actions = []
		_toast_temps = maxf(_toast_temps - get_process_delta_time(), 0.0)
		_fond_fantasy()
		match accueil.ecran:
			Accueil.Ecran.ARBRE:
				_dessiner_entete()
				_dessiner_matieres()
				_dessiner_arbre()
				_dessiner_panneau_droit()
				_dessiner_pied()
			Accueil.Ecran.COLLECTION:
				_dessiner_entete()
				_sous_ecran("COLLECTION")
				_dessiner_collection()
			Accueil.Ecran.PROGRESSION:
				_dessiner_entete()
				_sous_ecran("PROGRESSION & PALIERS")
				_dessiner_progression()
			Accueil.Ecran.PARENT:
				_dessiner_parent()
		if Profil.classe == "":
			_dessiner_choix_classe()
		if _toast_temps > 0.0:
			UI.banniere(self, Vector2(size.x / 2.0, size.y - 96.0), 460.0, _toast, 15)

	# ------------------------------------------------------- fond fantasy

	## Atmosphère profonde : dégradé marine → violet, brume, étoiles qui
	## scintillent, halos — subtil, l'arbre reste roi.
	func _fond_fantasy() -> void:
		UI.rect_degrade(self, Rect2(Vector2.ZERO, size), 0.0, Color("071633"), Color("140f38"))
		# Halos colorés très doux derrière les trois branches.
		for infos in [[Vector2(0.42, 0.32), Color("258cff")], [Vector2(0.45, 0.6), Color("8a55f5")],
				[Vector2(0.42, 0.85), Color("20cff3")]]:
			var p: Vector2 = infos[0] * size
			draw_circle(p, 150.0, Color(infos[1].r, infos[1].g, infos[1].b, 0.045))
		# Étoiles scintillantes (positions déterministes).
		for i in 46:
			var gx := fposmod(sin(i * 127.3) * 4096.0, 1.0)
			var gy := fposmod(sin(i * 311.7) * 2048.0, 1.0)
			var alpha := 0.14 + 0.14 * sin(_t() * (1.0 + gx * 2.0) + i)
			draw_circle(Vector2(gx * size.x, gy * size.y), 1.4 + gx, Color(0.9, 0.94, 1.0, alpha))
		# Brume basse.
		UI.rect_degrade(self, Rect2(0.0, size.y * 0.72, size.x, size.y * 0.28), 0.0,
			Color(0.1, 0.09, 0.25, 0.0), Color(0.13, 0.1, 0.3, 0.35))

	# ------------------------------------------------------- pictogrammes

	## Icônes dessinées (jamais d'emojis dans la version finale).
	func _picto(p: Vector2, r: float, type: String, teinte: Color) -> void:
		match type:
			"parent": # deux silhouettes
				draw_circle(p + Vector2(-r * 0.3, -r * 0.25), r * 0.3, teinte)
				draw_circle(p + Vector2(-r * 0.3, r * 0.35), r * 0.42, teinte)
				draw_circle(p + Vector2(r * 0.34, -r * 0.05), r * 0.24, teinte)
				draw_circle(p + Vector2(r * 0.34, r * 0.42), r * 0.32, teinte)
			"son": # haut-parleur
				draw_colored_polygon(PackedVector2Array([
					p + Vector2(-r * 0.5, -r * 0.2), p + Vector2(-r * 0.1, -r * 0.2),
					p + Vector2(r * 0.25, -r * 0.55), p + Vector2(r * 0.25, r * 0.55),
					p + Vector2(-r * 0.1, r * 0.2), p + Vector2(-r * 0.5, r * 0.2)]), teinte)
				draw_arc(p + Vector2(r * 0.32, 0.0), r * 0.45, -0.9, 0.9, 10, teinte, 2.0)
			"muet":
				_picto(p, r, "son", teinte)
				draw_line(p + Vector2(-r * 0.6, r * 0.6), p + Vector2(r * 0.7, -r * 0.6), Identite.ROUGE, 3.0)
			"cristal": # symbole mathématiques fantasy
				var pts := PackedVector2Array()
				for i in 6:
					pts.append(p + Vector2.from_angle(-PI / 2.0 + TAU * i / 6.0) * r * 0.62)
				draw_colored_polygon(pts, teinte)
				draw_circle(p + Vector2(-r * 0.14, -r * 0.2), r * 0.16, Color(1, 1, 1, 0.45))
			"plume":
				draw_colored_polygon(PackedVector2Array([
					p + Vector2(r * 0.5, -r * 0.55), p + Vector2(-r * 0.1, r * 0.05),
					p + Vector2(-r * 0.42, r * 0.55), p + Vector2(0.0, r * 0.2),
					p + Vector2(r * 0.25, -r * 0.1)]), teinte)
			"fiole":
				draw_rect(Rect2(p + Vector2(-r * 0.12, -r * 0.55), Vector2(r * 0.24, r * 0.3)), teinte)
				draw_circle(p + Vector2(0.0, r * 0.15), r * 0.42, teinte)
			"colonne":
				draw_rect(Rect2(p + Vector2(-r * 0.4, -r * 0.5), Vector2(r * 0.8, r * 0.16)), teinte)
				for c in 3:
					draw_rect(Rect2(p + Vector2(-r * 0.34 + c * r * 0.28, -r * 0.3), Vector2(r * 0.14, r * 0.7)), teinte)
				draw_rect(Rect2(p + Vector2(-r * 0.4, r * 0.4), Vector2(r * 0.8, r * 0.16)), teinte)
			"globe":
				draw_arc(p, r * 0.5, 0.0, TAU, 20, teinte, 2.5)
				draw_arc(p, r * 0.5, 0.0, TAU, 20, Color(teinte.r, teinte.g, teinte.b, 0.4), 1.0)
				draw_line(p + Vector2(-r * 0.5, 0.0), p + Vector2(r * 0.5, 0.0), teinte, 2.0)
				draw_arc(p + Vector2(0.0, 0.0), r * 0.5, -PI / 2.0, PI / 2.0, 12, teinte, 2.0)
			"barres":
				for b in 3:
					var h := r * (0.5 + b * 0.35)
					draw_rect(Rect2(p + Vector2(-r * 0.55 + b * r * 0.42, r * 0.6 - h), Vector2(r * 0.3, h)), teinte)
			"gemme_v": # cristal violet
				draw_colored_polygon(PackedVector2Array([
					p + Vector2(0.0, -r * 0.6), p + Vector2(r * 0.5, -r * 0.1),
					p + Vector2(0.0, r * 0.6), p + Vector2(-r * 0.5, -r * 0.1)]), Color("b34aff"))
				draw_circle(p + Vector2(-r * 0.12, -r * 0.2), r * 0.13, Color(1, 1, 1, 0.5))
			"gemme_b": # cristal bleu (XP de connaissance)
				draw_colored_polygon(PackedVector2Array([
					p + Vector2(0.0, -r * 0.62), p + Vector2(r * 0.44, 0.0), p + Vector2(0.0, r * 0.62),
					p + Vector2(-r * 0.44, 0.0)]), Color("20cff3"))
				draw_circle(p + Vector2(-r * 0.1, -r * 0.2), r * 0.12, Color(1, 1, 1, 0.5))
			"coche":
				draw_line(p + Vector2(-r * 0.42, 0.05 * r), p + Vector2(-r * 0.1, r * 0.38), Color.WHITE, r * 0.28)
				draw_line(p + Vector2(-r * 0.1, r * 0.38), p + Vector2(r * 0.48, -r * 0.34), Color.WHITE, r * 0.28)
			"revision":
				draw_arc(p, r * 0.45, 0.6, TAU - 0.4, 16, teinte, r * 0.16)
				draw_colored_polygon(PackedVector2Array([
					p + Vector2(r * 0.62, -r * 0.24), p + Vector2(r * 0.2, -r * 0.3),
					p + Vector2(r * 0.44, -r * 0.62)]), teinte)

	## Miniature de bâtiment (aperçus de récompense) — dessin cartoon.
	func _mini_batiment(p: Vector2, r: float) -> void:
		draw_rect(Rect2(p + Vector2(-r * 0.55, -r * 0.05), Vector2(r * 1.1, r * 0.65)), Color("fff3d5"))
		draw_colored_polygon(PackedVector2Array([
			p + Vector2(-r * 0.7, -r * 0.05), p + Vector2(0.0, -r * 0.6), p + Vector2(r * 0.7, -r * 0.05)]),
			Color("c05548"))
		draw_rect(Rect2(p + Vector2(-r * 0.12, r * 0.24), Vector2(r * 0.24, r * 0.36)), Color("6a4630"))
		draw_rect(Rect2(p + Vector2(r * 0.24, -r * 0.5), Vector2(r * 0.14, r * 0.3)), Color("8a8a94"))

	func _mini_chateau(p: Vector2, r: float) -> void:
		for c in [-1.0, 1.0]:
			draw_rect(Rect2(p + Vector2(c * r * 0.55 - r * 0.12, -r * 0.45), Vector2(r * 0.24, r * 1.0)), Color("d8d2e8"))
			draw_colored_polygon(PackedVector2Array([
				p + Vector2(c * r * 0.55 - r * 0.2, -r * 0.45), p + Vector2(c * r * 0.55, -r * 0.85),
				p + Vector2(c * r * 0.55 + r * 0.2, -r * 0.45)]), Color("8a55f5"))
		draw_rect(Rect2(p + Vector2(-r * 0.4, -r * 0.2), Vector2(r * 0.8, r * 0.75)), Color("efe9f8"))
		draw_colored_polygon(PackedVector2Array([
			p + Vector2(-r * 0.5, -r * 0.2), p + Vector2(0.0, -r * 0.7), p + Vector2(r * 0.5, -r * 0.2)]),
			Color("b34aff"))
		draw_rect(Rect2(p + Vector2(-r * 0.1, r * 0.15), Vector2(r * 0.2, r * 0.4)), Color("6a4630"))

	## Le hibou-guide (« Conseillé pour toi »).
	func _hibou(p: Vector2, r: float) -> void:
		draw_circle(p + Vector2(0.0, r * 0.15), r * 0.62, Color("8a55f5"))
		draw_circle(p + Vector2(0.0, -r * 0.3), r * 0.5, Color("9d6ff8"))
		for c in [-1.0, 1.0]:
			draw_circle(p + Vector2(c * r * 0.2, -r * 0.32), r * 0.2, Color("fff3d5"))
			draw_circle(p + Vector2(c * r * 0.2, -r * 0.32), r * 0.1, Color("071633"))
			draw_colored_polygon(PackedVector2Array([
				p + Vector2(c * r * 0.5, -r * 0.62), p + Vector2(c * r * 0.16, -r * 0.55),
				p + Vector2(c * r * 0.42, -r * 0.9)]), Color("8a55f5"))
		draw_colored_polygon(PackedVector2Array([
			p + Vector2(0.0, -r * 0.18), p + Vector2(-r * 0.1, -r * 0.05), p + Vector2(r * 0.1, -r * 0.05)]),
			Color("ffc928"))
		draw_circle(p + Vector2(0.0, r * 0.28), r * 0.34, Color("c4a5ff"))

	# ------------------------------------------------------- entête

	func _dessiner_entete() -> void:
		# PROFIL : portrait peint, nom, classe, niveau de COMPTE + XP.
		var profil := Rect2(8.0, 8.0, 238.0, 66.0)
		UI.panneau(self, profil)
		draw_circle(profil.position + Vector2(33.0, 33.0), 28.0, Identite.CONTOUR)
		draw_circle(profil.position + Vector2(33.0, 33.0), 25.0, Identite.VIOLET)
		UI.image(self, "avatar-%s" % Profil.personnage.to_lower(),
			Rect2(profil.position + Vector2(10.0, 10.0), Vector2(46.0, 46.0)))
		UI.texte(self, profil.position + Vector2(66.0, 24.0), Profil.personnage, 16, Identite.TEXTE)
		UI.texte(self, profil.position + Vector2(66.0, 42.0),
			Profil.classe if Profil.classe != "" else "…", 12, Identite.CYAN)
		UI.pastille(self, profil.position + Vector2(76.0, 54.0), 9.0, Identite.VIOLET, str(Profil.niveau), 10)
		UI.barre(self, Rect2(profil.position + Vector2(90.0, 48.0), Vector2(138.0, 13.0)),
			Profil.progres_niveau(), Identite.BLEU)
		_actions.append({"rect": profil, "action": "parent"})
		# CONNAISSANCE (progression non dépensable) + PROCHAIN DÉBLOCAGE :
		# l'espace des anciennes gemmes sert à respirer et à rendre le
		# prochain déblocage plus visible.
		var centre := Rect2(254.0, 8.0, 384.0, 66.0)
		UI.panneau(self, centre)
		var palier := Cite.palier(Profil.connaissance_xp)
		UI.texte(self, Vector2(centre.get_center().x - 20.0, centre.position.y + 18.0),
			"CONNAISSANCE — PALIER %d" % (palier + 1), 11, Identite.TEXTE_ATTENUE, true, 4)
		var prochain := Cite.prochain_palier(Profil.connaissance_xp)
		UI.etoile(self, centre.position + Vector2(24.0, 42.0), 13.0, Identite.VIOLET)
		if prochain.is_empty():
			UI.texte(self, centre.position + Vector2(46.0, 48.0), "SOMMET ATTEINT !", 14, Identite.OR)
		else:
			var xp_palier := int(Cite.PALIERS[int(prochain.indice)].xp)
			var xp_avant := int(Cite.PALIERS[palier].xp)
			var frac := float(Profil.connaissance_xp - xp_avant) / maxf(float(xp_palier - xp_avant), 1.0)
			UI.barre(self, Rect2(centre.position + Vector2(42.0, 30.0), Vector2(136.0, 22.0)),
				frac, Identite.VIOLET)
			UI.texte(self, centre.position + Vector2(110.0, 46.0), "%d %%" % int(frac * 100.0),
				13, Identite.TEXTE, true, 4)
			# NextUnlockPreview : miniature + nom + XP restant.
			UI.texte(self, centre.position + Vector2(192.0, 36.0),
				"Encore %d XP" % int(prochain.xp_manquant), 13, Identite.TEXTE)
			UI.texte(self, centre.position + Vector2(192.0, 52.0), "pour débloquer", 10, Identite.TEXTE_ATTENUE)
			var nom_rec := ""
			for d in prochain.debloque:
				var m := str(d).split(":")
				nom_rec = str(Cite.BATIMENTS.get(m[0], {}).get("titre", m[m.size() - 1]))
				break
			_mini_batiment(centre.position + Vector2(326.0, 34.0), 23.0)
			UI.texte(self, Vector2(centre.position.x + 326.0, centre.position.y + 62.0),
				nom_rec.to_upper(), 10, Identite.OR, true, 4)
		# PIÈCES : l'unique monnaie (les gemmes n'existent plus).
		var res := Rect2(646.0, 8.0, 92.0, 66.0)
		UI.panneau(self, res)
		if not UI.image(self, "res-coin", Rect2(res.position + Vector2(10.0, 12.0), Vector2(24.0, 24.0))):
			draw_circle(res.position + Vector2(22.0, 24.0), 11.0, Identite.OR)
		UI.texte(self, res.position + Vector2(42.0, 30.0), str(Profil.pieces), 15, Identite.TEXTE)
		UI.texte(self, Vector2(res.get_center().x, res.position.y + 54.0), "PIÈCES", 9,
			Identite.TEXTE_ATTENUE, true, 3)
		# Boutons : espace parent, son.
		var b1 := Rect2(746.0, 8.0, 52.0, 50.0)
		UI.bouton(self, b1, Identite.PANNEAU_CLAIR, "btn_parent", false, Identite.RAYON_SM)
		_picto(b1.get_center() + Vector2(0.0, -2.0), 14.0, "parent", Identite.CREME)
		_actions.append({"rect": b1, "action": "parent"})
		var b2 := Rect2(804.0, 8.0, 52.0, 50.0)
		UI.bouton(self, b2, Identite.PANNEAU_CLAIR, "btn_son", false, Identite.RAYON_SM)
		_picto(b2.get_center() + Vector2(0.0, -2.0), 13.0, "son" if Profil.son_actif else "muet", Identite.CREME)
		_actions.append({"rect": b2, "action": "son"})

	# ------------------------------------------------------- matières

	func _dessiner_matieres() -> void:
		UI.texte(self, Vector2(12.0, 98.0), "ARBRE DES CONNAISSANCES", 17, Identite.TEXTE)
		UI.texte(self, Vector2(12.0, 114.0), "Explore, apprends et deviens plus puissant !", 10, Identite.TEXTE_ATTENUE)
		var matieres: Array = [["mathematiques", "MATHÉMATIQUES", "cristal"], ["francais", "FRANÇAIS", "plume"],
			["sciences", "SCIENCES", "fiole"], ["histoire", "HISTOIRE", "colonne"],
			["geographie", "GÉOGRAPHIE", "globe"]]
		for i in matieres.size():
			var m: Array = matieres[i]
			var actif: bool = i == 0
			var rect := Rect2(8.0, 126.0 + i * 58.0, 112.0, 50.0)
			if actif:
				# Matière active : violet lumineux + halo.
				UI.rect_degrade(self, rect.grow(4.0), Identite.RAYON_MD + 4,
					Color(Identite.VIOLET.r, Identite.VIOLET.g, Identite.VIOLET.b, 0.35),
					Color(Identite.VIOLET.r, Identite.VIOLET.g, Identite.VIOLET.b, 0.15))
				UI.bouton(self, rect, Identite.VIOLET, "mat_actif", false, Identite.RAYON_MD)
			else:
				# Verrouillée mais désirable : sombre, riche, cadenas discret.
				UI.rect_degrade(self, rect.grow(2.0), Identite.RAYON_MD + 2, Identite.CONTOUR, Identite.CONTOUR)
				UI.rect_degrade(self, rect, Identite.RAYON_MD, Color("1a2c55"), Color("101c3d"))
				UI.image(self, "icon-lock", Rect2(rect.end - Vector2(22.0, 24.0), Vector2(14.0, 14.0)))
			_picto(rect.position + Vector2(16.0, 25.0), 11.0,
				str(m[2]), Identite.CREME if actif else Color(0.6, 0.62, 0.78))
			UI.texte(self, rect.position + Vector2(30.0, 29.0), str(m[1]), 9,
				Identite.TEXTE if actif else Identite.TEXTE_ATTENUE, false, 3)

	# ------------------------------------------------------- arbre

	func _zone_arbre() -> Rect2:
		return Rect2(132.0, 122.0, size.x - 132.0 - 246.0, size.y - 122.0 - 64.0)

	## LA CARTE MAGIQUE : bandeaux de branches, connexions-énergie en
	## éventail, médaillons de compétences. Tout est généré depuis les
	## données (savoir.gd) + la DISPOSITION (layout).
	func _dessiner_arbre() -> void:
		var zone := _zone_arbre()
		var domaines: Dictionary = Savoir.SUJETS.mathematiques.domaines
		# Trois passes de PROFONDEUR : connexions, puis bandeaux, puis
		# médaillons + labels — rien ne se recouvre mal.
		for cle in domaines:
			var teinte: Color = Accueil.COULEURS_BRANCHES.get(cle, Identite.CYAN)
			var config: Dictionary = Accueil.DISPOSITION.get(cle, {})
			var pos_bandeau: Vector2 = zone.position + Vector2(config.bandeau) * zone.size
			var precedent := Vector2.INF
			for comp in domaines[cle].competences:
				var pos: Vector2 = zone.position + Vector2(config.noeuds.get(str(comp.id), Vector2(0.5, 0.5))) * zone.size
				var verrou := Savoir.etat(str(comp.id)) == "verrouillee"
				_connexion(pos_bandeau + Vector2(0.0, 10.0), pos, teinte, verrou)
				if precedent != Vector2.INF:
					_connexion(precedent, pos, teinte, verrou, true)
				precedent = pos
		for cle in domaines:
			var teinte: Color = Accueil.COULEURS_BRANCHES.get(cle, Identite.CYAN)
			var config: Dictionary = Accueil.DISPOSITION.get(cle, {})
			var pos_bandeau: Vector2 = zone.position + Vector2(config.bandeau) * zone.size
			var largeur := 168.0
			var rect := Rect2(pos_bandeau - Vector2(largeur / 2.0, 13.0), Vector2(largeur, 26.0))
			UI.rect_degrade(self, rect.grow(3.0), 16.0, Identite.CONTOUR, Identite.CONTOUR)
			UI.rect_degrade(self, rect, 14.0, teinte.darkened(0.25), teinte.darkened(0.55))
			UI.contour_arrondi(self, rect, 14.0, Color(teinte.r, teinte.g, teinte.b, 0.7), 1.5)
			UI.texte(self, pos_bandeau + Vector2(0.0, 4.0), str(domaines[cle].titre).to_upper(), 12,
				Identite.TEXTE, true, 4)
		for cle in domaines:
			var teinte: Color = Accueil.COULEURS_BRANCHES.get(cle, Identite.CYAN)
			var config: Dictionary = Accueil.DISPOSITION.get(cle, {})
			var liste: Array = domaines[cle].competences
			for i in liste.size():
				var comp: Dictionary = liste[i]
				var pos: Vector2 = zone.position + Vector2(config.noeuds.get(str(comp.id), Vector2(0.5, 0.5))) * zone.size
				_medaillon(pos, comp, teinte)

	## Connexion-énergie : double passe (halo large + cœur) avec dégradé
	## le long d'une courbe douce. Sombre si la cible est verrouillée.
	func _connexion(depart: Vector2, arrivee: Vector2, teinte: Color, verrou: bool, fine := false) -> void:
		var couleur := Color("2a2748") if verrou else teinte
		var pts := PackedVector2Array()
		var couleurs := PackedColorArray()
		var controle := (depart + arrivee) / 2.0 + Vector2(0.0, -14.0)
		for i in 15:
			var t := i / 14.0
			var p := depart.lerp(controle, t).lerp(controle.lerp(arrivee, t), t)
			pts.append(p)
			var a := (0.5 if verrou else 0.85) - t * 0.25
			couleurs.append(Color(couleur.r, couleur.g, couleur.b, a * (0.5 if fine else 1.0)))
		# Halo doux puis cœur lumineux.
		if not fine and not verrou:
			draw_polyline(pts, Color(couleur.r, couleur.g, couleur.b, 0.16), 9.0, true)
		draw_polyline_colors(pts, couleurs, 2.0 if fine else 3.5, true)

	## Le MÉDAILLON de compétence : grand, tactile, état très différencié.
	func _medaillon(pos: Vector2, comp: Dictionary, teinte_branche: Color, label_dessus := false) -> void:
		var id := str(comp.id)
		var etat := Savoir.etat(id)
		var score := Profil.score_competence(id)
		var teinte: Color = COULEURS_ETATS.get(etat, Identite.CYAN)
		var selection: bool = id == accueil.competence_ouverte
		var r := 22.0
		# Halo de sélection pulsant.
		if selection:
			var halo := r + 9.0 + sin(_t() * 4.0) * 3.0
			draw_circle(pos, halo, Color(Identite.OR.r, Identite.OR.g, Identite.OR.b, 0.3))
		# Socle : contour épais + fond profond.
		draw_circle(pos, r + 4.0, Color("06102a"))
		draw_circle(pos, r, Color("0c1f45") if etat != "verrouillee" else Color("171233"))
		match etat:
			"maitrisee":
				draw_circle(pos, r, Color(0.32, 0.25, 0.08))
				draw_arc(pos, r - 2.0, 0.0, TAU, 40, teinte, 4.5)
				UI.etoile(self, pos, 13.0, teinte)
				draw_circle(pos, r + 6.0, Color(teinte.r, teinte.g, teinte.b, 0.10 + 0.05 * sin(_t() * 2.0)))
			"acquise":
				draw_circle(pos, r, Color(0.1, 0.3, 0.14))
				draw_arc(pos, r - 2.0, 0.0, TAU, 40, teinte, 4.5)
				_picto(pos, 13.0, "coche", Color.WHITE)
				draw_circle(pos, r + 5.0, Color(teinte.r, teinte.g, teinte.b, 0.08))
			"apprentissage":
				# Anneau de progression + % central — attire l'œil.
				var t_anneau: Color = Color("ffb028") if score >= 55.0 else teinte_branche
				draw_arc(pos, r - 2.0, 0.0, TAU, 40, Color(1, 1, 1, 0.12), 4.5)
				draw_arc(pos, r - 2.0, -PI / 2.0, -PI / 2.0 + TAU * score / 100.0, 40, t_anneau, 4.5)
				draw_arc(pos, r - 2.0, -PI / 2.0, -PI / 2.0 + TAU * score / 100.0, 40,
					Color(t_anneau.r, t_anneau.g, t_anneau.b, 0.25), 8.0)
				UI.texte(self, pos + Vector2(0.0, 5.0), "%d%%" % int(score), 13, Identite.TEXTE, true, 4)
			"decouverte":
				draw_arc(pos, r - 2.0, 0.0, TAU, 40, teinte_branche, 2.5)
				UI.etoile(self, pos, 9.0, Color(teinte_branche.r, teinte_branche.g, teinte_branche.b, 0.7), false)
			"verrouillee":
				draw_arc(pos, r - 2.0, 0.0, TAU, 40, Color("3a3358"), 3.0)
				UI.image(self, "icon-lock", Rect2(pos - Vector2(10.0, 10.0), Vector2(20.0, 20.0)))
			"a_consolider":
				draw_arc(pos, r - 2.0, 0.0, TAU, 40, teinte, 4.0)
				_picto(pos, 12.0, "revision", teinte)
		# Étoiles de maîtrise SUR le bord bas du médaillon (compacité
		# mobile), label compact dessous.
		if etat != "verrouillee":
			var etoiles := 3 if score >= 90.0 else (2 if score >= 70.0 else (1 if score >= 50.0 else 0))
			for e in 3:
				var pe := pos + Vector2(-12.0 + e * 12.0, r - 1.0)
				draw_circle(pe, 6.5, Color("06102a"))
				UI.etoile(self, pe, 4.6, Identite.OR if e < etoiles else Color(0.32, 0.34, 0.5), false)
		var lignes := _couper(str(comp.titre), 15)
		var teinte_label := Identite.TEXTE if etat != "verrouillee" else Color(0.55, 0.55, 0.7)
		for li in lignes.size():
			UI.texte(self, pos + Vector2(0.0, r + 17.0 + li * 11.0), lignes[li], 9,
				teinte_label, true, 4)
		_actions.append({"rect": Rect2(pos - Vector2(28.0, 28.0), Vector2(56.0, 56.0)),
			"action": "competence:%s" % id})

	func _couper(txt: String, max_car: int) -> Array:
		if txt.length() <= max_car:
			return [txt]
		var coupe := txt.rfind(" ", max_car)
		if coupe <= 0:
			return [txt]
		return [txt.substr(0, coupe), txt.substr(coupe + 1)]

	# ------------------------------------------------------- panneau droit

	## COMPÉTENCE SÉLECTIONNÉE : statut, prochaine étape, récompenses à
	## venir (apprentissage et récompense TOUJOURS liés), CTA CONTINUER.
	func _dessiner_panneau_droit() -> void:
		var comp := Savoir.competence(accueil.competence_ouverte)
		if comp.is_empty():
			return
		var id := str(comp.id)
		var etat := Savoir.etat(id)
		var score := Profil.score_competence(id)
		var teinte: Color = COULEURS_ETATS.get(etat, Identite.CYAN)
		var rect := Rect2(size.x - 240.0, 88.0, 232.0, size.y - 152.0)
		UI.panneau(self, rect)
		var x := rect.position.x + 14.0
		UI.texte(self, Vector2(x, rect.position.y + 24.0), str(comp.titre).to_upper(), 13, Identite.OR)
		# STATUT ACTUEL : grand anneau + état.
		UI.texte(self, Vector2(x, rect.position.y + 46.0), "STATUT ACTUEL", 10, Identite.TEXTE_ATTENUE)
		var centre_anneau := rect.position + Vector2(44.0, 86.0)
		draw_circle(centre_anneau, 30.0, Color("06102a"))
		draw_arc(centre_anneau, 26.0, 0.0, TAU, 40, Color(1, 1, 1, 0.1), 6.0)
		draw_arc(centre_anneau, 26.0, -PI / 2.0, -PI / 2.0 + TAU * score / 100.0, 40, Color("ffb028"), 6.0)
		draw_arc(centre_anneau, 26.0, -PI / 2.0, -PI / 2.0 + TAU * score / 100.0, 40,
			Color(1.0, 0.69, 0.16, 0.25), 11.0)
		UI.texte(self, centre_anneau + Vector2(0.0, 5.0), "%d%%" % int(score), 14, Identite.TEXTE, true, 4)
		UI.texte(self, Vector2(x + 74.0, rect.position.y + 78.0), str(NOMS_ETATS.get(etat, etat)), 12, teinte)
		UI.texte(self, Vector2(x + 74.0, rect.position.y + 96.0),
			"Tu progresses bien !" if etat == "apprentissage" else "Explore et progresse !", 10, Identite.TEXTE_ATTENUE)
		# PROCHAINE ÉTAPE : le seuil qui débloque la suite.
		UI.texte(self, Vector2(x, rect.position.y + 136.0), "PROCHAINE ÉTAPE", 10, Identite.TEXTE_ATTENUE)
		var suivant := _suivante_debloquee_par(id)
		if suivant != "":
			UI.texte(self, Vector2(x, rect.position.y + 152.0), "Maîtrise à 80 % pour débloquer", 10, Identite.TEXTE)
			UI.texte(self, Vector2(x, rect.position.y + 166.0), str(Savoir.competence(suivant).titre), 11, Identite.CYAN)
		else:
			UI.texte(self, Vector2(x, rect.position.y + 158.0), "Monte à 3 étoiles de maîtrise !", 10, Identite.TEXTE)
		UI.barre(self, Rect2(x, rect.position.y + 176.0, rect.size.x - 28.0, 14.0),
			score / 80.0, Identite.VIOLET)
		UI.texte(self, Vector2(rect.get_center().x, rect.position.y + 187.0), "%d %% / 80 %%" % int(score),
			9, Identite.TEXTE, true, 3)
		# RÉCOMPENSES À VENIR.
		UI.texte(self, Vector2(x, rect.position.y + 212.0), "RÉCOMPENSES À VENIR", 10, Identite.TEXTE_ATTENUE)
		var y_rec := rect.position.y + 244.0
		var carte1 := Rect2(x, y_rec - 20.0, 60.0, 46.0)
		UI.rect_degrade(self, carte1, 8.0, Color("14264d"), Color("0c1a3a"))
		UI.etoile(self, carte1.get_center() + Vector2(0.0, -6.0), 10.0, Identite.VIOLET)
		UI.texte(self, carte1.get_center() + Vector2(0.0, 18.0), "+%d XP" % int(comp.xp), 9, Identite.TEXTE, true, 3)
		var carte2 := carte1
		carte2.position.x += 68.0
		UI.rect_degrade(self, carte2, 8.0, Color("14264d"), Color("0c1a3a"))
		if not UI.image(self, "res-coin", Rect2(carte2.get_center() - Vector2(9.0, 15.0), Vector2(18.0, 18.0))):
			draw_circle(carte2.get_center() + Vector2(0.0, -6.0), 8.0, Identite.OR)
		UI.texte(self, carte2.get_center() + Vector2(0.0, 18.0), "+%d or" % (int(comp.xp) / 2), 9, Identite.TEXTE, true, 3)
		var carte3 := carte2
		carte3.position.x += 68.0
		UI.rect_degrade(self, carte3, 8.0, Color("14264d"), Color("0c1a3a"))
		_mini_batiment(carte3.get_center() + Vector2(0.0, -4.0), 13.0)
		UI.texte(self, carte3.get_center() + Vector2(0.0, 18.0), "Bâtiment", 8, Identite.TEXTE_ATTENUE, true, 3)
		# CTA CONTINUER — épais, tactile, mobile game premium.
		var cta := Rect2(x, rect.end.y - 66.0, rect.size.x - 28.0, 54.0)
		UI.bouton(self, cta, Identite.VERT, "cta_session", false, Identite.RAYON_MD)
		UI.texte(self, cta.get_center() + Vector2(0.0, -2.0), "CONTINUER", 17, Identite.TEXTE, true, 6)
		UI.texte(self, cta.get_center() + Vector2(0.0, 16.0), "Travailler cette compétence", 10, Identite.CREME, true, 3)
		_actions.append({"rect": cta, "action": "session"})

	## Quelle compétence a `id` pour prérequis (la « prochaine étape »).
	func _suivante_debloquee_par(id: String) -> String:
		for comp in Savoir.competences("mathematiques"):
			if comp.prerequis.has(id):
				return str(comp.id)
		return ""

	# ------------------------------------------------------- pied de page

	func _dessiner_pied() -> void:
		var y := size.y - 56.0
		# Coffre PALIERS.
		var paliers := Rect2(8.0, y, 176.0, 48.0)
		UI.rect_degrade(self, paliers.grow(2.0), Identite.RAYON_MD, Identite.CONTOUR, Identite.CONTOUR)
		UI.rect_degrade(self, paliers, Identite.RAYON_MD, Color("3a2a68"), Color("221844"))
		UI.coffre(self, paliers.position + Vector2(26.0, 26.0), 26.0)
		UI.texte(self, paliers.position + Vector2(52.0, 20.0), "PALIERS", 12, Identite.OR)
		UI.texte(self, paliers.position + Vector2(52.0, 36.0), "Débloque des récompenses !", 9, Identite.TEXTE_ATTENUE)
		_actions.append({"rect": paliers, "action": "progression"})
		# CONSEILLÉ POUR TOI (le hibou-guide) — secondaire, jamais imposé.
		var conseil := Rect2(192.0, y, 330.0, 48.0)
		UI.rect_degrade(self, conseil.grow(2.0), Identite.RAYON_MD, Identite.CONTOUR, Identite.CONTOUR)
		UI.rect_degrade(self, conseil, Identite.RAYON_MD, Color("221d45"), Color("161231"))
		_hibou(conseil.position + Vector2(26.0, 24.0), 16.0)
		UI.texte(self, conseil.position + Vector2(50.0, 19.0), "Conseillé pour toi", 11, Identite.OR)
		var reco := Savoir.recommandation()
		UI.texte(self, conseil.position + Vector2(50.0, 36.0),
			"Tu pourrais travailler : %s" % (str(Savoir.competence(reco).titre) if reco != "" else "…"),
			10, Identite.TEXTE)
		if reco != "":
			_actions.append({"rect": conseil, "action": "competence:%s" % reco})
		# Navigation basse : MA VILLE (très attractive), COLLECTION, PROGRESSION.
		var nav: Array = [["ville", "MA VILLE", "chateau"], ["collection", "COLLECTION", "coffre"],
			["progression", "PROGRESSION", "barres"]]
		for i in nav.size():
			var n: Array = nav[i]
			var rect := Rect2(size.x - 336.0 + i * 112.0, y, 106.0, 48.0)
			UI.bouton(self, rect, Identite.BLEU if i == 0 else Identite.PANNEAU_CLAIR,
				"nav_%s" % str(n[0]), false, Identite.RAYON_MD)
			match str(n[2]):
				"chateau":
					_mini_chateau(rect.position + Vector2(22.0, 24.0), 15.0)
				"coffre":
					UI.coffre(self, rect.position + Vector2(22.0, 24.0), 20.0)
				"barres":
					_picto(rect.position + Vector2(22.0, 22.0), 13.0, "barres", Identite.CYAN)
			UI.texte(self, rect.position + Vector2(42.0, 29.0), str(n[1]), 10, Identite.TEXTE)
			_actions.append({"rect": rect, "action": str(n[0])})

	# ------------------------------------------------------- sous-écrans

	func _sous_ecran(titre: String) -> void:
		_bouton_action(Rect2(10.0, 84.0, 62.0, 46.0), "retour", Identite.BLEU, "←", 20, Identite.RAYON_SM)
		UI.banniere(self, Vector2(size.x / 2.0, 100.0), 360.0, titre, 18)

	func _bouton_action(rect: Rect2, action: String, fond: Color, txt: String, taille := 18, rayon := Identite.RAYON_MD) -> void:
		UI.bouton(self, rect, fond, "acc_%s" % action, false, rayon)
		UI.texte(self, rect.get_center() + Vector2(0.0, taille * 0.36), txt, taille, Identite.TEXTE, true)
		_actions.append({"rect": rect, "action": action})

	func _dessiner_collection() -> void:
		UI.texte(self, Vector2(size.x / 2.0, 152.0), "HÉROS — habitants et personnages de leçons", 14, Identite.CYAN, true, 4)
		var palier := Cite.palier(Profil.connaissance_xp)
		var noms: Array = Personnage3D.FICHES.keys()
		for i in noms.size():
			var nom: String = noms[i]
			var debloque := nom == "Max" or _heros_debloque(nom, palier)
			var rect := Rect2(size.x / 2.0 - 340.0 + i * 175.0, 166.0, 160.0, 108.0)
			UI.panneau(self, rect)
			if debloque and UI.image(self, "carte-%s" % nom.to_lower(), Rect2(rect.position + Vector2(8.0, 8.0), Vector2(54.0, 70.0))):
				pass
			else:
				draw_circle(rect.position + Vector2(34.0, 44.0), 22.0, Identite.CONTOUR)
				draw_circle(rect.position + Vector2(34.0, 44.0), 18.0,
					Profil.couleur_de(nom) if debloque else Color(0.32, 0.34, 0.45))
				if not debloque:
					UI.image(self, "icon-lock", Rect2(rect.position + Vector2(22.0, 32.0), Vector2(24.0, 24.0)))
			UI.texte(self, rect.position + Vector2(70.0, 34.0), nom, 15,
				Identite.TEXTE if debloque else Identite.TEXTE_ATTENUE)
			UI.badge_rarete(self, rect.position + Vector2(104.0, 58.0), str(Personnage3D.FICHES[nom].rarete), 9)
			if not debloque:
				UI.texte(self, rect.position + Vector2(70.0, 92.0), "Palier %d" % _palier_du_heros(nom), 11, Identite.ORANGE)
		UI.texte(self, Vector2(size.x / 2.0, 306.0), "ANIMAUX & COMPAGNONS", 14, Identite.CYAN, true, 4)
		var especes: Array = Personnage3D.ESPECES.keys()
		for i in especes.size():
			var espece: String = especes[i]
			var possede: bool = Profil.dragons.has(espece)
			var p := Vector2(size.x / 2.0 - 300.0 + i * 120.0, 350.0)
			draw_circle(p, 26.0, Identite.CONTOUR)
			draw_circle(p, 22.0, Personnage3D.ESPECES[espece].couleur if possede else Color(0.3, 0.33, 0.45))
			UI.texte(self, p + Vector2(0.0, 46.0), espece if possede else "???", 12,
				Identite.TEXTE if possede else Identite.TEXTE_ATTENUE, true, 4)

	func _heros_debloque(nom: String, palier_atteint: int) -> bool:
		for i in mini(palier_atteint + 1, Cite.PALIERS.size()):
			if Cite.PALIERS[i].debloque.has("heros:%s" % nom):
				return true
		return Profil.heros_debloques.has(nom)

	func _palier_du_heros(nom: String) -> int:
		for i in Cite.PALIERS.size():
			if Cite.PALIERS[i].debloque.has("heros:%s" % nom):
				return i
		return 0

	func _dessiner_progression() -> void:
		var palier := Cite.palier(Profil.connaissance_xp)
		var largeur := minf(size.x - 160.0, 680.0)
		var x0 := (size.x - largeur) / 2.0
		for i in Cite.PALIERS.size():
			var p: Dictionary = Cite.PALIERS[i]
			var atteint := i <= palier
			var courant := i == palier + 1
			var rect := Rect2(x0, 138.0 + i * 41.0, largeur, 35.0)
			self.draw_style_box(UI.style("palier_%s_%s" % [str(atteint), str(courant)],
				Identite.PANNEAU_CLAIR if courant else Identite.PANNEAU,
				Identite.OR if courant else (Identite.VERT_SOMBRE if atteint else Identite.CONTOUR),
				Identite.RAYON_SM, 2, 1), rect)
			if atteint:
				_picto(rect.position + Vector2(20.0, 17.0), 8.0, "coche", Identite.VERT)
			UI.texte(self, rect.position + Vector2(36.0, 24.0), "%d — %s" % [i, str(p.nom)], 14,
				Identite.VERT if atteint else (Identite.OR if courant else Identite.TEXTE))
			UI.texte(self, rect.position + Vector2(230.0, 24.0), "%d XP" % int(p.xp), 12, Identite.TEXTE_ATTENUE)
			var contenus: Array = []
			for d in p.debloque:
				var m := str(d).split(":")
				contenus.append(str(Cite.BATIMENTS.get(m[0], {}).get("titre", m[m.size() - 1])))
			UI.texte(self, rect.position + Vector2(320.0, 24.0), ", ".join(contenus), 12,
				Identite.TEXTE if courant else Identite.TEXTE_ATTENUE)

	func _dessiner_parent() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.05, 0.14, 0.9))
		_bouton_action(Rect2(10.0, 12.0, 62.0, 46.0), "retour", Identite.BLEU, "←", 20, Identite.RAYON_SM)
		UI.banniere(self, Vector2(size.x / 2.0, 30.0), 340.0, "ESPACE PARENT", 18)
		UI.texte(self, Vector2(size.x / 2.0, 66.0),
			"%s — classe : %s" % [Profil.personnage, Profil.classe if Profil.classe != "" else "non choisie"],
			13, Identite.TEXTE_ATTENUE, true, 4)
		var domaines: Dictionary = Savoir.SUJETS.mathematiques.domaines
		var y := 92.0
		UI.texte(self, Vector2(70.0, y), "MATHÉMATIQUES", 15, Identite.CYAN)
		y += 14.0
		for cle in domaines:
			var m := Profil.maitrise_domaine("mathematiques", str(cle))
			UI.texte(self, Vector2(70.0, y + 16.0), str(domaines[cle].titre), 13, Identite.TEXTE)
			UI.barre(self, Rect2(240.0, y + 2.0, 190.0, 18.0), m / 100.0,
				Identite.VERT if m >= 75.0 else Identite.BLEU)
			UI.texte(self, Vector2(440.0, y + 16.0), "%d %% maîtrisé" % int(m), 12, Identite.TEXTE_ATTENUE)
			y += 30.0
		var s: Dictionary = Profil.stats_semaine
		var resume := Rect2(70.0, y + 8.0, 420.0, 108.0)
		UI.panneau(self, resume)
		UI.texte(self, resume.position + Vector2(16.0, 24.0), "CETTE SEMAINE", 13, Identite.OR)
		UI.texte(self, resume.position + Vector2(16.0, 46.0), "+ %d compétences acquises" % int(s.acquises), 12, Identite.TEXTE)
		UI.texte(self, resume.position + Vector2(16.0, 66.0), "+ %d compétences maîtrisées" % int(s.maitrisees), 12, Identite.TEXTE)
		UI.texte(self, resume.position + Vector2(16.0, 86.0),
			"%d difficulté(s) détectée(s), %d corrigée(s)" % [int(s.difficultes), int(s.corrigees)], 12, Identite.TEXTE)
		UI.texte(self, resume.position + Vector2(240.0, 46.0),
			"%d min d'apprentissage" % int(s.minutes_apprentissage), 12, Identite.TEXTE_ATTENUE)
		var xd := size.x - 330.0
		UI.texte(self, Vector2(xd, 92.0), "DÉTAIL DES COMPÉTENCES", 13, Identite.CYAN)
		var yd := 106.0
		for comp in Savoir.competences("mathematiques"):
			var etat := Savoir.etat(str(comp.id))
			if etat == "verrouillee":
				continue
			var teinte: Color = COULEURS_ETATS.get(etat, Identite.CYAN)
			UI.texte(self, Vector2(xd, yd + 16.0), "%s — %s" % [str(comp.titre), str(NOMS_ETATS.get(etat, etat)).to_lower()],
				11, teinte)
			yd += 22.0
			if yd > size.y - 60.0:
				break

	func _dessiner_choix_classe() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.04, 0.12, 0.85))
		var fen := Rect2(size.x / 2.0 - 280.0, size.y / 2.0 - 130.0, 560.0, 250.0)
		UI.panneau(self, fen)
		UI.banniere(self, Vector2(size.x / 2.0, fen.position.y), 380.0, "BIENVENUE À ILLUMINIA !", 17)
		UI.texte(self, Vector2(size.x / 2.0, fen.position.y + 56.0), "En quelle classe es-tu ?", 18, Identite.TEXTE, true)
		UI.texte(self, Vector2(size.x / 2.0, fen.position.y + 80.0),
			"Illuminia s'adaptera ensuite tout seul à ton niveau.", 12, Identite.TEXTE_ATTENUE, true, 4)
		for i in Savoir.CLASSES.size():
			var rect := Rect2(fen.position.x + 34.0 + (i % 3) * 172.0,
				fen.position.y + 100.0 + (i / 3) * 62.0, 156.0, 52.0)
			_bouton_action(rect, "classe:%s" % Savoir.CLASSES[i],
				Identite.BLEU if i < 3 else Identite.VIOLET, str(Savoir.CLASSES[i]), 18)

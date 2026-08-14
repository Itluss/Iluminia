class_name Session
extends Node3D
## LA SESSION D'APPRENTISSAGE — l'intérieur d'un nœud de l'Arbre.
##
## « L'arbre est la carte. La question est l'aventure à l'intérieur du
## nœud. » On arrive ici DIRECTEMENT depuis CONTINUER (aucune page
## intermédiaire) ; le décor et l'interface restent, seul le CONTENU
## central changera (question → diagnostic → leçon → résultat).
##
## Le design system est CELUI DE L'ARBRE : la surface hérite de
## Accueil.SurfaceAccueil (entête, matières, pictos, hibou, styles) —
## rien n'est recréé, l'enfant doit sentir « je suis toujours dans
## Illuminia », jamais « je fais un exercice scolaire ».
##
## Pédagogie v1 : QUESTION_ACTIVE → ANSWER_CORRECT / ANSWER_INCORRECT.
## Une erreur ne révèle JAMAIS la bonne réponse : elle enregistre la
## misconception probable et déclenchera (prochain jalon) le diagnostic
## et la micro-leçon. Pas de jackpot par question : la récompense est la
## PROGRESSION DE MAÎTRISE (panneau droit, dynamique).

## Étapes d'une session continue. v1 implémente les trois premières ;
## les autres sont réservées (le centre de l'écran se remplacera sans
## reconstruire l'écran).
enum Etape { QUESTION_ACTIVE, ANSWER_CORRECT, ANSWER_INCORRECT,
	DIAGNOSTIC, LESSON, PRACTICE, SESSION_RESULT }

var competence := {}             ## fiche Savoir de la compétence travaillée
var domaine_cle := ""            ## branche (couleur d'identité conservée)
var domaine_titre := ""
var teinte_branche := Identite.VIOLET
var etape: Etape = Etape.QUESTION_ACTIVE
var choix := ""                  ## réponse choisie (pendant le feedback)
var cine = null                  ## Cinematique.Player pendant LESSON
var surface: SurfaceSession

## État de session (modèle conceptuel LearningSession) + MESURES
## pédagogiques (l'adaptation dynamique s'appuiera dessus). Regarder une
## leçon n'augmente JAMAIS la maîtrise : elle se démontre en exerçant.
var session := {
	"competence_id": "", "questions": [], "courante": 0,
	"reponses": [], "justes": 0, "misconceptions": [],
	"maitrise_avant": 0.0, "maitrise_courante": 0.0,
	"lecon_declenchee": false,
	"mesures": {"lecon_vue": false, "lecon_terminee": false,
		"lecon_passee": false, "exercice_apres_lecon_juste": false},
}

var _chrono := 0.0               ## temps passé dans l'étape courante
var _fige := false               ## crochet de capture : gèle l'avancement
var _debut := 0.0                ## fondu d'entrée (transition courte)
var _garde_action := ""          ## navigation : confirmation en 2 touches
var _garde_temps := 0.0


func _ready() -> void:
	var id := OS.get_environment("ILUMINIA_COMPETENCE")
	if id == "" or Savoir.competence(id).is_empty():
		id = "fr_comparer"
	competence = Savoir.competence(id)
	_trouver_domaine(id)
	session.competence_id = id
	session.maitrise_avant = Profil.score_competence(id)
	session.maitrise_courante = session.maitrise_avant
	session.questions = generer_questions(competence, domaine_cle, 5)

	var couche := CanvasLayer.new()
	add_child(couche)
	surface = SurfaceSession.new()
	surface.session_noeud = self
	surface.set_anchors_preset(Control.PRESET_FULL_RECT)
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	couche.add_child(surface)
	_debut = Time.get_ticks_msec() / 1000.0

	if OS.get_environment("ILUMINIA_CLASSE") != "":
		Profil.classe = OS.get_environment("ILUMINIA_CLASSE")
	# Crochets de dev : capturer les états de feedback / la cinématique.
	match OS.get_environment("ILUMINIA_SESSION"):
		"juste":
			_repondre(str(question_courante().correcte))
			_fige = true
		"erreur", "flux":
			for r in question_courante().reponses:
				if str(r) != str(question_courante().correcte):
					_repondre(str(r))
					break
			_fige = OS.get_environment("ILUMINIA_SESSION") == "erreur"
		"lecon":
			_demarrer_lecon()
			var saut := OS.get_environment("ILUMINIA_CINE_T")
			if saut != "" and cine != null:
				cine.aller_a(float(saut))
				_fige = true
		"verif":
			_demarrer_lecon()
			_fin_lecon(true)
			_fige = true


func _trouver_domaine(id: String) -> void:
	for sujet in Savoir.SUJETS:
		var domaines: Dictionary = Savoir.SUJETS[sujet].get("domaines", {})
		for cle in domaines:
			for c in domaines[cle].competences:
				if str(c.id) == id:
					domaine_cle = cle
					domaine_titre = str(domaines[cle].titre)
					teinte_branche = Accueil.COULEURS_BRANCHES.get(cle, Identite.VIOLET)
					return


func question_courante() -> Dictionary:
	var qs: Array = session.questions
	return qs[clampi(int(session.courante), 0, qs.size() - 1)]


func _process(delta: float) -> void:
	surface.queue_redraw()
	_garde_temps = maxf(_garde_temps - delta, 0.0)
	if _fige:
		return
	_chrono += delta
	if etape == Etape.LESSON and cine != null:
		cine.maj(delta)
		return
	# Feedback court, puis on avance : une bonne réponse est satisfaisante
	# mais RAPIDE ; une erreur laisse le temps de lire — puis, si une
	# leçon existe pour cette compétence, la CINÉMATIQUE PÉDAGOGIQUE
	# explique (une vraie explication, pas une récompense).
	if etape == Etape.ANSWER_CORRECT and _chrono > 1.5:
		_suivante()
	elif etape == Etape.ANSWER_INCORRECT and _chrono > 2.2:
		if not bool(session.mesures.lecon_vue) \
				and not Lecons.pour(str(session.competence_id)).is_empty():
			_demarrer_lecon()
		else:
			_suivante()


## DIAGNOSTIC (v1 : la misconception est déjà enregistrée) → CINÉMATIQUE.
func _demarrer_lecon() -> void:
	cine = Cinematique.Player.new(Lecons.pour(str(session.competence_id)))
	etape = Etape.LESSON
	session.mesures.lecon_vue = true
	session.lecon_declenchee = true
	choix = ""
	_chrono = 0.0


## Fin de cinématique (terminée ou passée) → EXERCICE DE VÉRIFICATION :
## une nouvelle question COMPARE est insérée — passer la leçon ne valide
## jamais la compétence, seule la pratique le fait.
func _fin_lecon(terminee: bool) -> void:
	session.mesures.lecon_terminee = terminee
	session.mesures.lecon_passee = not terminee
	cine = null
	var verif := generer_questions(competence, domaine_cle, 1)
	var q: Dictionary = verif[0]
	q.id = "%s_verification" % str(competence.get("id", "comp"))
	q.verification = true
	var questions: Array = session.questions
	questions.insert(int(session.courante) + 1, q)
	_suivante()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		var action := surface.action_sous(event.position)
		if action != "":
			_executer(action)


func _executer(action: String) -> void:
	var morceaux := action.split(":")
	match morceaux[0]:
		"rep":
			if etape == Etape.QUESTION_ACTIVE:
				_repondre(morceaux[1])
		"quitter":
			# Sortie explicite : la progression de la session est conservée.
			Audio.jouer("clic")
			_terminer("arbre")
		"cine":
			if cine == null:
				return
			match morceaux[1]:
				"pause":
					Audio.jouer("clic")
					cine.pause = not cine.pause
				"replay":
					Audio.jouer("clic")
					cine.rejouer()
				"passer":
					Audio.jouer("clic")
					_fin_lecon(false)
				"exercice":
					Audio.jouer("depart")
					_fin_lecon(true)
		"son":
			Profil.basculer_son()
			Audio.jouer("clic")
		"nav":
			# Pendant une session active : confirmation en deux touches pour
			# éviter toute perte accidentelle de progression.
			if _garde_action == action and _garde_temps > 0.0:
				_terminer(morceaux[1])
			else:
				Audio.jouer("clic")
				_garde_action = action
				_garde_temps = 3.0
				surface.toast("Session en cours — appuie encore pour quitter.")
		"parent":
			_executer("nav:parent")


## LE CHOIX EST LA RÉPONSE (pas de bouton VALIDER séparé).
func _repondre(reponse: String) -> void:
	var q := question_courante()
	choix = reponse
	session.reponses.append(reponse)
	_chrono = 0.0
	if reponse == str(q.correcte):
		etape = Etape.ANSWER_CORRECT
		session.justes += 1
		session.maitrise_courante = minf(float(session.maitrise_courante) + 6.0, 100.0)
		if bool(q.get("verification", false)):
			session.mesures.exercice_apres_lecon_juste = true
		Audio.jouer("cristal")
	else:
		etape = Etape.ANSWER_INCORRECT
		# On n'affiche PAS la bonne réponse : on enregistre la stratégie
		# probable (misconception) pour le futur diagnostic + micro-leçon.
		var mc := str(q.get("misconceptions", {}).get(reponse, "INDETERMINEE"))
		session.misconceptions.append({"question": q.id, "choix": reponse, "misconception": mc})
		session.lecon_declenchee = true
		session.maitrise_courante = maxf(float(session.maitrise_courante) - 4.0, 4.0)
		Audio.jouer("mauvaise")


func _suivante() -> void:
	choix = ""
	_chrono = 0.0
	if int(session.courante) + 1 >= session.questions.size():
		_terminer("arbre")
	else:
		session.courante = int(session.courante) + 1
		etape = Etape.QUESTION_ACTIVE


## Fin (ou sortie) de session : la maîtrise travaillée est appliquée au
## profil — c'est ELLE la vraie récompense, et l'état peut changer
## (l'XP de connaissance n'arrive qu'aux changements d'état réels).
func _terminer(destination: String) -> void:
	var id := str(session.competence_id)
	var score := float(session.maitrise_courante)
	var avant := Profil.etat_competence_brut(id)
	var etat := avant
	if score >= 80.0 and avant != "maitrisee":
		etat = "acquise"
	elif avant == "decouverte" or avant == "a_consolider":
		etat = "apprentissage"
	Profil.fixer_etat_competence(id, etat, score)
	match destination:
		"ville":
			get_tree().change_scene_to_file.call_deferred("res://scenes/ville.tscn")
		"collection", "progression", "parent":
			OS.set_environment("ILUMINIA_ECRAN", destination)
			get_tree().change_scene_to_file.call_deferred("res://scenes/accueil.tscn")
		_:
			OS.set_environment("ILUMINIA_ECRAN", "")
			get_tree().change_scene_to_file.call_deferred("res://scenes/accueil.tscn")


# ---------------------------------------------------------------------
## GÉNÉRATEUR DE QUESTIONS data-driven — type COMPARE uniquement (v1).
## Le modèle est générique : {id, competence_id, type, consigne,
## operandes[{type, ...}], reponses, correcte, misconceptions{}} ; les
## types MULTIPLE_CHOICE / NUMBER_INPUT / DRAG_DROP… s'ajouteront ici
## sans toucher à l'écran.
static func generer_questions(comp: Dictionary, domaine: String, nombre: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var sortie: Array = []
	var vues := {}
	for i in nombre:
		var q := {}
		for essai in 40:
			q = _question_compare(comp, domaine, rng, i == 2)
			var cle := str(q.operandes)
			if not vues.has(cle):
				vues[cle] = true
				break
		q.id = "%s_compare_%03d" % [str(comp.get("id", "comp")), i + 1]
		sortie.append(q)
	return sortie


static func _question_compare(comp: Dictionary, domaine: String,
		rng: RandomNumberGenerator, egalite: bool) -> Dictionary:
	var q := {"competence_id": str(comp.get("id", "")), "type": "compare",
		"reponses": ["<", "=", ">"], "misconceptions": {}}
	if domaine == "fractions":
		q.consigne = "Quelle fraction est la plus grande ?"
		var b := rng.randi_range(2, 9)
		var a := rng.randi_range(1, b - 1)
		var c := rng.randi_range(2, 9)
		var d := rng.randi_range(1, c - 1)
		if egalite:
			# Fractions équivalentes : voir l'égalité EST la compétence.
			var k := rng.randi_range(2, 3)
			c = b * k
			d = a * k
		q.operandes = [{"type": "fraction", "numerateur": a, "denominateur": b},
			{"type": "fraction", "numerateur": d, "denominateur": c}]
		var gauche := a * c
		var droite := d * b
		if gauche > droite:
			q.correcte = ">"
			q.misconceptions = {"<": "COMPARE_DENOMINATEURS_DIRECTEMENT",
				"=": "CONFUSION_GRANDEUR_FRACTION"}
		elif gauche < droite:
			q.correcte = "<"
			q.misconceptions = {">": "COMPARE_NUMERATEURS_SEULS",
				"=": "CONFUSION_GRANDEUR_FRACTION"}
		else:
			q.correcte = "="
			q.misconceptions = {"<": "NE_VOIT_PAS_L_EQUIVALENCE",
				">": "NE_VOIT_PAS_L_EQUIVALENCE"}
	else:
		# Compétence non fractionnaire : comparaison de nombres (générique).
		q.consigne = "Quel nombre est le plus grand ?"
		var n1 := rng.randi_range(11, 999)
		var n2 := rng.randi_range(11, 999)
		if egalite:
			n2 = n1
		q.operandes = [{"type": "entier", "valeur": n1}, {"type": "entier", "valeur": n2}]
		q.correcte = ">" if n1 > n2 else ("<" if n1 < n2 else "=")
		q.misconceptions = {"<": "COMPARE_LES_CHIFFRES_ISOLES", ">": "COMPARE_LES_CHIFFRES_ISOLES",
			"=": "LECTURE_PARTIELLE"}
		q.misconceptions.erase(str(q.correcte))
	return q


static func texte_operande(op: Dictionary) -> String:
	if str(op.get("type", "")) == "fraction":
		return "%d/%d" % [int(op.numerateur), int(op.denominateur)]
	return str(op.get("valeur", "?"))


# =====================================================================
## LA SURFACE — hérite du design system de l'Arbre (SurfaceAccueil) :
## entête, colonne matières, pictos, hibou, toasts sont RÉUTILISÉS.
class SurfaceSession extends Accueil.SurfaceAccueil:
	var session_noeud: Session = null

	func _draw() -> void:
		_actions = []
		_toast_temps = maxf(_toast_temps - get_process_delta_time(), 0.0)
		_fond_session()
		_dessiner_entete()          # ← top bar de l'Arbre, telle quelle
		_dessiner_matieres()        # ← colonne matières de l'Arbre
		_scene_apprentissage()      # LearningStage (le centre, seul à changer)
		_panneau_progression()
		_pied_session()
		if _toast_temps > 0.0:
			UI.banniere(self, Vector2(size.x / 2.0, size.y - 96.0), 460.0, _toast, 15)
		# Fondu d'entrée court (transition depuis l'Arbre).
		var depuis: float = _t() - session_noeud._debut
		if depuis < 0.35:
			draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.05, 0.15, (1.0 - depuis / 0.35)))

	## Zone centrale (entre matières et panneau droit) : le FOCUS.
	func _zone_centre() -> Rect2:
		return Rect2(124.0, 80.0, size.x - 124.0 - 250.0, size.y - 80.0 - 64.0)

	# ----------------------------------------------------- fond immersif

	## L'INTÉRIEUR de la compétence : plus immersif que l'Arbre, mais
	## subtil — la question reste parfaitement lisible.
	func _fond_session() -> void:
		var teinte: Color = session_noeud.teinte_branche
		UI.rect_degrade(self, Rect2(Vector2.ZERO, size), 0.0, Color("060f2b"), Color("140b38"))
		# Grand halo central de la couleur de la branche.
		var centre := _zone_centre().get_center()
		draw_circle(centre, 250.0, Color(teinte.r, teinte.g, teinte.b, 0.07))
		draw_circle(centre, 150.0, Color(teinte.r, teinte.g, teinte.b, 0.06))
		# Symboles fantomatiques : fractions et formes géométriques.
		var zone := _zone_centre()
		var fantome := Color(teinte.r, teinte.g, teinte.b, 0.14)
		_fraction(zone.position + zone.size * Vector2(0.06, 0.30), 1, 2, 13, fantome)
		_fraction(zone.position + zone.size * Vector2(0.94, 0.62), 2, 3, 13, fantome)
		_fraction(zone.position + zone.size * Vector2(0.08, 0.78), 3, 4, 12, fantome)
		draw_arc(zone.position + zone.size * Vector2(0.93, 0.22), 16.0, 0.0, TAU, 6, fantome, 1.5)
		var tri := zone.position + zone.size * Vector2(0.05, 0.55)
		draw_polyline(PackedVector2Array([tri + Vector2(0, -12), tri + Vector2(11, 8),
			tri + Vector2(-11, 8), tri + Vector2(0, -12)]), fantome, 1.5)
		# Étoiles scintillantes + poussières lumineuses lentes.
		for i in 46:
			var gx := fposmod(sin(i * 127.3) * 4096.0, 1.0)
			var gy := fposmod(sin(i * 311.7) * 2048.0, 1.0)
			var alpha := 0.13 + 0.13 * sin(_t() * (1.0 + gx * 2.0) + i)
			draw_circle(Vector2(gx * size.x, gy * size.y), 1.3 + gx, Color(0.9, 0.94, 1.0, alpha))
		for i in 10:
			var px := fposmod(sin(i * 57.7) * 977.0 + _t() * (2.0 + i), 1.0)
			var py := fposmod(cos(i * 39.1) * 733.0 - _t() * 0.012 * (1.0 + i * 0.3), 1.0)
			draw_circle(zone.position + Vector2(px, py) * zone.size, 1.8,
				Color(teinte.r, teinte.g, teinte.b, 0.12))
		UI.rect_degrade(self, Rect2(0.0, size.y * 0.72, size.x, size.y * 0.28), 0.0,
			Color(0.1, 0.09, 0.25, 0.0), Color(0.13, 0.1, 0.3, 0.35))

	# ----------------------------------------------------- LearningStage

	## Le centre : dispatch par étape. QUESTION et FEEDBACK partagent la
	## même scène (le feedback vit dans le panneau de consigne + boutons) ;
	## DIAGNOSTIC / LESSON / RESULT remplaceront ce contenu plus tard.
	func _scene_apprentissage() -> void:
		match session_noeud.etape:
			Session.Etape.QUESTION_ACTIVE, Session.Etape.ANSWER_CORRECT, \
			Session.Etape.ANSWER_INCORRECT:
				_question_compare()
			Session.Etape.LESSON:
				_stage_cinematique()
			_:
				pass

	# --------------------------------------------------- CinematicStage

	## La zone centrale devient la scène cinématique : même écran, même
	## univers — l'enfant n'a jamais l'impression qu'une vidéo s'ouvre.
	func _stage_cinematique() -> void:
		var zone := _zone_centre()
		var cine = session_noeud.cine
		if cine == null:
			return
		var teinte: Color = session_noeud.teinte_branche
		var cx := zone.get_center().x
		# Interface minimale : badge + titre compacts, la scène est reine.
		var badge := Rect2(cx - 70.0, zone.position.y - 2.0, 140.0, 24.0)
		UI.rect_degrade(self, badge.grow(2.0), 14.0, Identite.CONTOUR, Identite.CONTOUR)
		UI.rect_degrade(self, badge, 12.0, teinte.darkened(0.15), teinte.darkened(0.5))
		UI.texte(self, badge.get_center() + Vector2(0.0, 4.0),
			session_noeud.domaine_titre.to_upper(), 10, Identite.TEXTE, true, 4)
		UI.texte(self, Vector2(cx, zone.position.y + 40.0),
			str(session_noeud.competence.titre).to_upper(), 15, Identite.CREME, true, 3)
		# LA GRANDE SCÈNE (SceneRenderer du moteur).
		var scene := Rect2(zone.position.x + 4.0, zone.position.y + 50.0,
			zone.size.x - 8.0, zone.size.y - 88.0)
		cine.dessiner(self, scene, _t())
		# SOUS-TITRES systématiques : panneau bleu nuit + icône son.
		var texte_narration := str(cine.narration())
		if texte_narration != "":
			var lignes := _couper(texte_narration, 62)
			var haut_st := 18.0 + lignes.size() * 15.0
			var st := Rect2(scene.position.x + scene.size.x * 0.08,
				scene.end.y - haut_st - 8.0, scene.size.x * 0.84, haut_st)
			UI.rect_degrade(self, st, 10.0, Color(0.05, 0.08, 0.22, 0.88), Color(0.03, 0.05, 0.16, 0.88))
			UI.contour_arrondi(self, st, 10.0, Color(0.35, 0.3, 0.65, 0.7), 1.5)
			_picto(st.position + Vector2(18.0, st.size.y / 2.0), 8.0, "son", Identite.CREME)
			for li in lignes.size():
				UI.texte(self, Vector2(st.get_center().x + 10.0,
					st.position.y + 20.0 + li * 15.0), lignes[li], 11, Identite.TEXTE, true, 1)
		# CONTRÔLES très discrets (pause / son / recommencer / passer).
		var y_c := scene.position.y + 8.0
		var boutons: Array = [["pause", "lecture" if cine.pause else "pause"],
			["son", "son" if Profil.son_actif else "muet"], ["replay", "revision"]]
		for i in boutons.size():
			var b: Array = boutons[i]
			var cercle := Vector2(scene.end.x - 20.0 - i * 34.0, y_c + 12.0)
			draw_circle(cercle, 14.0, Color(0.08, 0.1, 0.28, 0.85))
			draw_arc(cercle, 14.0, 0.0, TAU, 24, Color(0.4, 0.35, 0.7, 0.6), 1.5)
			if str(b[1]) == "pause":
				for barre_p in [-3.5, 3.5]:
					draw_rect(Rect2(cercle + Vector2(barre_p - 2.0, -6.0), Vector2(4.0, 12.0)),
						Identite.CREME)
			elif str(b[1]) == "lecture":
				UI.triangle_jouer(self, cercle, 8.0, Identite.CREME)
			else:
				_picto(cercle, 8.0, str(b[1]), Identite.CREME)
			var action_c := "son" if str(b[0]) == "son" else "cine:%s" % str(b[0])
			_actions.append({"rect": Rect2(cercle - Vector2(17.0, 17.0), Vector2(34.0, 34.0)),
				"action": action_c})
		if not bool(cine.scene().get("bouton_fin", false)):
			var passer := Rect2(scene.end.x - 78.0, y_c + 32.0, 62.0, 22.0)
			UI.rect_degrade(self, passer, 10.0, Color(0.1, 0.12, 0.3, 0.8), Color(0.07, 0.09, 0.24, 0.8))
			UI.texte(self, passer.get_center() + Vector2(0.0, 4.0), "PASSER", 9,
				Identite.TEXTE_ATTENUE, true, 2)
			_actions.append({"rect": passer, "action": "cine:passer"})
		else:
			# Dernière scène : PASSER À L'EXERCICE (ferme le CinematicStage).
			var cta := Rect2(scene.end.x - 208.0, scene.end.y - 88.0, 196.0, 38.0)
			UI.bouton(self, cta, Identite.VIOLET, "cine_exercice", false, Identite.RAYON_MD)
			UI.texte(self, cta.get_center() + Vector2(-8.0, 5.0), "PASSER À L'EXERCICE", 11,
				Identite.TEXTE, true, 2)
			UI.texte(self, cta.get_center() + Vector2(82.0, 5.0), "»", 14, Identite.CREME, true)
			_actions.append({"rect": cta, "action": "cine:exercice"})

	func _question_compare() -> void:
		var zone := _zone_centre()
		var q: Dictionary = session_noeud.question_courante()
		var teinte: Color = session_noeud.teinte_branche
		var cx := zone.get_center().x
		# BADGE DE DOMAINE : pill violette + glow (langage des bandeaux).
		var badge := Rect2(cx - 88.0, zone.position.y + zone.size.y * 0.005, 176.0, 30.0)
		draw_circle(badge.get_center(), 60.0, Color(teinte.r, teinte.g, teinte.b, 0.10))
		UI.rect_degrade(self, badge.grow(3.0), 18.0, Identite.CONTOUR, Identite.CONTOUR)
		UI.rect_degrade(self, badge, 15.0, teinte.darkened(0.15), teinte.darkened(0.5))
		UI.contour_arrondi(self, badge, 15.0, Color(teinte.r, teinte.g, teinte.b, 0.75), 1.5)
		UI.texte(self, badge.get_center() + Vector2(0.0, 5.0),
			session_noeud.domaine_titre.to_upper(), 13, Identite.TEXTE, true, 5)
		# TITRE DE LA COMPÉTENCE : l'un des éléments principaux.
		UI.texte(self, Vector2(cx, zone.position.y + zone.size.y * 0.16),
			str(session_noeud.competence.titre).to_upper(), 22, Identite.CREME, true, 3)
		# PROGRESSION DE SESSION (SessionProgress — jamais hardcodée).
		var courante := int(session_noeud.session.courante)
		var total: int = session_noeud.session.questions.size()
		if bool(q.get("verification", false)):
			# Après la cinématique : l'exercice de vérification s'annonce.
			var verif := Rect2(cx - 92.0, zone.position.y + zone.size.y * 0.215, 184.0, 20.0)
			UI.rect_degrade(self, verif, 10.0, Color(0.08, 0.3, 0.38, 0.9), Color(0.05, 0.2, 0.28, 0.9))
			UI.contour_arrondi(self, verif, 10.0, Identite.CYAN, 1.5)
			UI.texte(self, verif.get_center() + Vector2(0.0, 4.0), "EXERCICE DE VÉRIFICATION", 9,
				Identite.CYAN, true, 2)
		else:
			UI.texte(self, Vector2(cx, zone.position.y + zone.size.y * 0.235),
				"Question %d / %d" % [courante + 1, total], 11, Identite.TEXTE_ATTENUE, true, 3)
		_progression_session(Vector2(cx, zone.position.y + zone.size.y * 0.30),
			minf(300.0, zone.size.x * 0.62), courante, total)
		# CONSIGNE / FEEDBACK (même panneau : le décor ne bouge pas).
		var panneau := Rect2(cx - 170.0, zone.position.y + zone.size.y * 0.355, 340.0, 34.0)
		UI.rect_degrade(self, panneau.grow(2.0), 12.0, Identite.CONTOUR, Identite.CONTOUR)
		UI.rect_degrade(self, panneau, 10.0, Color("13204a"), Color("0c1533"))
		match session_noeud.etape:
			Session.Etape.ANSWER_CORRECT:
				UI.contour_arrondi(self, panneau, 10.0, Identite.VERT, 1.5)
				_picto(panneau.position + Vector2(24.0, 17.0), 8.0, "coche", Identite.VERT)
				UI.texte(self, panneau.get_center() + Vector2(8.0, -1.0), "EXACT !", 13, Identite.VERT, true, 4)
				UI.texte(self, panneau.get_center() + Vector2(8.0, 12.0), _phrase_exacte(q), 9,
					Identite.TEXTE_ATTENUE, true, 2)
			Session.Etape.ANSWER_INCORRECT:
				UI.contour_arrondi(self, panneau, 10.0, Identite.ORANGE, 1.5)
				_croix(panneau.position + Vector2(24.0, 17.0), 7.0, Identite.ORANGE)
				UI.texte(self, panneau.get_center() + Vector2(8.0, -1.0), "REGARDONS ENSEMBLE", 12,
					Identite.ORANGE, true, 3)
				UI.texte(self, panneau.get_center() + Vector2(8.0, 12.0),
					"On va comprendre pourquoi, ensemble.", 9, Identite.TEXTE_ATTENUE, true, 2)
			_:
				UI.texte(self, panneau.get_center() + Vector2(0.0, 5.0), str(q.consigne), 13,
					Identite.CREME, true, 2)
		# CARTES OPÉRANDES : objets précieux posés dans l'univers.
		var apparition := clampf(session_noeud._chrono / 0.3, 0.0, 1.0) \
			if session_noeud.etape == Session.Etape.QUESTION_ACTIVE else 1.0
		var larg := minf(112.0, zone.size.x * 0.21)
		var haut := minf(larg * 1.18, zone.size.y * 0.33)
		var cy := zone.position.y + zone.size.y * 0.60 + (1.0 - apparition) * 10.0
		var ecart := larg / 2.0 + minf(84.0, zone.size.x * 0.16)
		var ops: Array = q.operandes
		_carte_operande(Vector2(cx - ecart, cy), Vector2(larg, haut), ops[0])
		_carte_operande(Vector2(cx + ecart, cy), Vector2(larg, haut), ops[1])
		# LE POINT D'INTERROGATION : l'opération mentale à effectuer.
		var pulse := 0.2 + 0.06 * sin(_t() * 2.4)
		draw_circle(Vector2(cx, cy), 34.0, Color(1.0, 0.79, 0.16, pulse))
		for dec in [Vector2(-2, 0), Vector2(2, 0), Vector2(0, -2), Vector2(0, 2)]:
			UI.texte(self, Vector2(cx, cy + 15.0) + dec, "?", 42, Color("6a4400"), true)
		UI.texte(self, Vector2(cx, cy + 15.0), "?", 42, Identite.OR, true)
		# LES TROIS RÉPONSES : énormes, tactiles — le choix EST la réponse.
		_boutons_reponses(cx, zone.position.y + zone.size.y * 0.885, zone, q)

	## SessionProgress : ligne violette, étapes passées remplies, étape
	## courante avec glow pulsant, futures sombres. Dynamique.
	func _progression_session(centre: Vector2, largeur: float, courante: int, total: int) -> void:
		var teinte: Color = session_noeud.teinte_branche
		var pas := largeur / maxf(float(total - 1), 1.0)
		var x0 := centre.x - largeur / 2.0
		for i in total - 1:
			var a := Vector2(x0 + i * pas + 9.0, centre.y)
			var b := Vector2(x0 + (i + 1) * pas - 9.0, centre.y)
			var fait: bool = i < courante
			draw_line(a, b, teinte if fait else Color("2a2748"), 3.0)
		for i in total:
			var p := Vector2(x0 + i * pas, centre.y)
			if i < courante:
				draw_circle(p, 7.0, teinte)
				draw_circle(p, 3.0, teinte.lightened(0.4))
			elif i == courante:
				var halo := 11.0 + sin(_t() * 4.0) * 1.5
				draw_circle(p, halo, Color(teinte.r, teinte.g, teinte.b, 0.25))
				draw_circle(p, 8.5, teinte.lightened(0.15))
				draw_circle(p, 4.0, Color.WHITE)
			else:
				draw_circle(p, 6.5, Color("171233"))
				draw_arc(p, 6.5, 0.0, TAU, 20, Color("3a3358"), 2.0)

	## Carte crème épaisse : ombre profonde, tranche, face, bordure dorée,
	## halo chaud léger, reflet — un objet précieux, pas un champ HTML.
	func _carte_operande(centre: Vector2, taille: Vector2, op: Dictionary) -> void:
		var rect := Rect2(centre - taille / 2.0, taille)
		UI.rect_degrade(self, rect.grow(7.0), 20.0, Color(1.0, 0.85, 0.4, 0.10), Color(1.0, 0.85, 0.4, 0.03))
		var ombre := rect
		ombre.position.y += 9.0
		UI.rect_degrade(self, ombre.grow(2.0), 16.0, Color(0.0, 0.02, 0.08, 0.4), Color(0.0, 0.02, 0.08, 0.4))
		var tranche := rect
		tranche.position.y += 5.0
		UI.rect_degrade(self, tranche, 14.0, Color("b89a60"), Color("9a7d48"))
		UI.rect_degrade(self, rect, 14.0, Color("fdf4da"), Color("ecd9ac"))
		UI.contour_arrondi(self, rect, 14.0, Identite.OR_SOMBRE, 2.5)
		UI.rect_degrade(self, Rect2(rect.position + Vector2(8.0, 5.0), Vector2(rect.size.x - 16.0, 9.0)),
			4.0, Color(1, 1, 1, 0.4), Color(1, 1, 1, 0.0))
		var encre := Color("222848")
		if str(op.get("type", "")) == "fraction":
			_fraction(rect.get_center(), int(op.numerateur), int(op.denominateur),
				int(rect.size.y * 0.28), encre)
		else:
			UI.texte(self, rect.get_center() + Vector2(0.0, rect.size.y * 0.13),
				str(op.get("valeur", "?")), int(rect.size.y * 0.32), encre, true)

	## FractionDisplay : numérateur, barre, dénominateur — le composant
	## sera énormément réutilisé (cartes, fantômes du fond, leçons).
	func _fraction(centre: Vector2, num: int, den: int, taille: int, encre: Color) -> void:
		var ecart := taille * 0.72
		UI.texte(self, centre + Vector2(0.0, -ecart + taille * 0.38), str(num), taille, encre, true)
		var demi_barre := taille * 0.62
		draw_rect(Rect2(centre + Vector2(-demi_barre, -taille * 0.075),
			Vector2(demi_barre * 2.0, maxf(taille * 0.11, 2.0))), encre)
		UI.texte(self, centre + Vector2(0.0, ecart + taille * 0.38), str(den), taille, encre, true)

	## Les réponses < = > : violet / bleu / violet, états DEFAULT /
	## SELECTED (pressé) / CORRECT (vert + coche) / INCORRECT (rouge +
	## croix) / DISABLED — jamais un état communiqué par la seule couleur.
	func _boutons_reponses(cx: float, cy: float, zone: Rect2, q: Dictionary) -> void:
		var larg := minf(108.0, zone.size.x * 0.2)
		var haut := minf(56.0, zone.size.y * 0.17)
		var ecart := larg + minf(28.0, zone.size.x * 0.05)
		var reponses: Array = q.reponses
		var actif: bool = session_noeud.etape == Session.Etape.QUESTION_ACTIVE
		for i in reponses.size():
			var r := str(reponses[i])
			var rect := Rect2(cx + (i - 1) * ecart - larg / 2.0, cy - haut / 2.0, larg, haut)
			var fond: Color = Identite.BLEU if r == "=" else Identite.VIOLET
			var presse := false
			var symbole_teinte := Identite.TEXTE
			if not actif:
				if r == session_noeud.choix and r == str(q.correcte):
					fond = Identite.VERT
					presse = true
					draw_circle(rect.get_center(), haut * 0.75, Color(0.33, 0.8, 0.33, 0.22))
				elif r == session_noeud.choix:
					fond = Identite.ROUGE
					presse = true
				else:
					fond = Color("2a3054")   # DISABLED : sombre mais dans la DA
					symbole_teinte = Color(0.62, 0.65, 0.8)
			UI.bouton(self, rect, fond, "rep_%s_%d" % [r, i], presse, Identite.RAYON_MD)
			UI.texte(self, rect.get_center() + Vector2(0.0, 9.0 if not presse else 11.0), r, 27,
				symbole_teinte, true)
			if not actif and r == session_noeud.choix:
				if r == str(q.correcte):
					_picto(rect.position + Vector2(rect.size.x - 16.0, 14.0), 7.0, "coche", Color.WHITE)
				else:
					_croix(rect.position + Vector2(rect.size.x - 16.0, 14.0), 6.0, Color.WHITE)
			if actif:
				_actions.append({"rect": rect.grow(6.0), "action": "rep:%s" % r})

	func _croix(p: Vector2, r: float, teinte: Color) -> void:
		draw_line(p + Vector2(-r * 0.6, -r * 0.6), p + Vector2(r * 0.6, r * 0.6), teinte, r * 0.4)
		draw_line(p + Vector2(-r * 0.6, r * 0.6), p + Vector2(r * 0.6, -r * 0.6), teinte, r * 0.4)

	func _phrase_exacte(q: Dictionary) -> String:
		var ops: Array = q.operandes
		var a := Session.texte_operande(ops[0])
		var b := Session.texte_operande(ops[1])
		match str(q.correcte):
			">":
				return "%s est plus grand que %s." % [a, b]
			"<":
				return "%s est plus petit que %s." % [a, b]
			_:
				return "%s est égal à %s." % [a, b]

	# ------------------------------------------------- panneau progression

	## PROGRESSION DE CETTE COMPÉTENCE : la maîtrise DYNAMIQUE de la
	## session (elle bouge à chaque réponse) — c'est la vraie récompense.
	func _panneau_progression() -> void:
		var comp: Dictionary = session_noeud.competence
		var id := str(comp.id)
		var etat := Savoir.etat(id)
		var score := float(session_noeud.session.maitrise_courante)
		if ["decouverte", "a_consolider"].has(etat):
			etat = "apprentissage"   # en session, on apprend — affichage vivant
		var teinte: Color = COULEURS_ETATS.get(etat, Identite.CYAN)
		var rect := Rect2(size.x - 240.0, 88.0, 232.0, size.y - 152.0)
		UI.panneau(self, rect)
		var x := rect.position.x + 14.0
		UI.texte(self, Vector2(x, rect.position.y + 22.0), "PROGRESSION DE", 12, Identite.OR)
		UI.texte(self, Vector2(x, rect.position.y + 38.0), "CETTE COMPÉTENCE", 12, Identite.OR)
		var centre_anneau := rect.position + Vector2(44.0, 86.0)
		draw_circle(centre_anneau, 30.0, Color("06102a"))
		draw_arc(centre_anneau, 26.0, 0.0, TAU, 40, Color(1, 1, 1, 0.1), 6.0)
		draw_arc(centre_anneau, 26.0, -PI / 2.0, -PI / 2.0 + TAU * score / 100.0, 40, Color("ffb028"), 6.0)
		draw_arc(centre_anneau, 26.0, -PI / 2.0, -PI / 2.0 + TAU * score / 100.0, 40,
			Color(1.0, 0.69, 0.16, 0.25), 11.0)
		UI.texte(self, centre_anneau + Vector2(0.0, 5.0), "%d%%" % int(score), 14, Identite.TEXTE, true, 4)
		UI.texte(self, Vector2(x + 74.0, rect.position.y + 78.0), str(NOMS_ETATS.get(etat, etat)), 11, teinte)
		UI.texte(self, Vector2(x + 74.0, rect.position.y + 96.0), "Tu progresses bien !", 10, Identite.TEXTE_ATTENUE)
		UI.etoile(self, rect.position + Vector2(rect.size.x - 24.0, 100.0), 10.0, Identite.VIOLET)
		# PROCHAINE ÉTAPE : le travail ouvre RÉELLEMENT la suite de l'arbre.
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
		# RÉCOMPENSES À VENIR (à la maîtrise — pas à chaque question).
		UI.texte(self, Vector2(x, rect.position.y + 208.0), "RÉCOMPENSES À VENIR", 10, Identite.TEXTE_ATTENUE)
		var y_rec := rect.position.y + 236.0
		var carte1 := Rect2(x, y_rec - 20.0, 60.0, 46.0)
		UI.rect_degrade(self, carte1, 8.0, Color("14264d"), Color("0c1a3a"))
		_picto(carte1.get_center() + Vector2(0.0, -6.0), 11.0, "gemme_b", Identite.CYAN)
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
		# CONTINUER : PRÉSENT (composition de la maquette) mais jamais un
		# moyen de sauter une question — désactivé tant qu'une réponse est
		# attendue ; il s'activera aux étapes qui l'exigent (leçon, bilan).
		var cta := Rect2(x, rect.end.y - 66.0, rect.size.x - 28.0, 54.0)
		UI.bouton(self, cta, Color("2a3054"), "cta_session_off", false, Identite.RAYON_MD)
		UI.texte(self, cta.get_center() + Vector2(0.0, -2.0), "CONTINUER", 17, Color(0.62, 0.65, 0.8), true, 6)
		UI.texte(self, cta.get_center() + Vector2(0.0, 16.0), "Réponds à la question", 10,
			Color(0.55, 0.58, 0.72), true, 3)

	# ------------------------------------------------------------- pied

	func _pied_session() -> void:
		var y := size.y - 56.0
		# CONSEILLÉ POUR TOI — très secondaire pendant une session.
		var conseil := Rect2(8.0, y, 252.0, 48.0)
		UI.rect_degrade(self, conseil.grow(2.0), Identite.RAYON_MD, Identite.CONTOUR, Identite.CONTOUR)
		UI.rect_degrade(self, conseil, Identite.RAYON_MD, Color("221d45"), Color("161231"))
		_hibou(conseil.position + Vector2(26.0, 24.0), 16.0)
		UI.texte(self, conseil.position + Vector2(50.0, 19.0), "Conseillé pour toi", 10, Identite.OR)
		var reco := Savoir.recommandation()
		UI.texte(self, conseil.position + Vector2(50.0, 35.0),
			"Tu pourrais travailler : %s" % (str(Savoir.competence(reco).titre) if reco != "" else "…"),
			9, Identite.TEXTE)
		# QUITTER LA SESSION — discret, jamais aussi attractif que répondre.
		var quitter := Rect2(276.0, y + 6.0, 176.0, 38.0)
		UI.rect_degrade(self, quitter.grow(2.0), Identite.RAYON_MD, Identite.CONTOUR, Identite.CONTOUR)
		UI.rect_degrade(self, quitter, Identite.RAYON_MD, Color("1a2c55"), Color("101c3d"))
		UI.texte(self, quitter.get_center() + Vector2(-58.0, 6.0), "←", 15, Identite.TEXTE_ATTENUE, true)
		UI.texte(self, quitter.get_center() + Vector2(10.0, 4.0), "QUITTER LA SESSION", 9,
			Identite.TEXTE_ATTENUE, true, 3)
		_actions.append({"rect": quitter, "action": "quitter"})
		# Navigation basse : visible (repères du jeu) mais gardée — une
		# session ne se quitte jamais par accident.
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
			_actions.append({"rect": rect, "action": "nav:%s" % str(n[0])})

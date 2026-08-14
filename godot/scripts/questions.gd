class_name Questions
extends RefCounted
## LE MOTEUR PÉDAGOGIQUE d'Iluminia — programme de MATHS 5ème (cycle 4).
##
## Ici on ENSEIGNE, on ne fait pas que tester :
## - chaque NOTION du programme a sa LEÇON (règle + exemples travaillés) ;
## - chaque question porte son EXPLICATION : à l'erreur, la règle
##   s'affiche appliquée à CE calcul — c'est là que l'élève apprend ;
## - chaque notion se décline en 3 NIVEAUX de difficulté, pilotés par la
##   maîtrise de l'élève (profil.gd) : on progresse vers le niveau 3.
##
## Format de sortie de generer() :
##   {"enonce": String, "reponses": [4 × String], "bonne": int,
##    "explication": [1-2 lignes], "notion": String, "niveau": int}

## Les chapitres travaillés (programme officiel de 5ème).
const NOTIONS := {
	"relatifs": {
		"titre": "Nombres relatifs",
		"lecon": [
			"MÊME SIGNE : on ajoute les distances à zéro, on garde le signe.",
			"Ex : (-3) + (-5) = -8    |    SIGNES CONTRAIRES : on soustrait",
			"les distances, on garde le signe du plus éloigné de zéro.",
			"Ex : (-3) + 7 = +4    |    SOUSTRAIRE = AJOUTER L'OPPOSÉ :",
			"4 - (-2) = 4 + 2 = 6",
		],
	},
	"fractions": {
		"titre": "Fractions",
		"lecon": [
			"FRACTIONS ÉGALES : multiplier ou diviser le numérateur ET le",
			"dénominateur par un même nombre. Ex : 6/8 = 3/4 (÷2).",
			"ADDITION : il faut le MÊME dénominateur, puis on additionne",
			"les numérateurs. Ex : 1/4 + 1/2 = 1/4 + 2/4 = 3/4",
		],
	},
	"litteral": {
		"titre": "Calcul littéral",
		"lecon": [
			"RÉDUIRE : on regroupe les x ensemble, les nombres ensemble.",
			"Ex : 3x + 2x = 5x    |    4x + 3 + 2x - 1 = 6x + 2",
			"SUBSTITUER : remplacer x par sa valeur puis calculer.",
			"Ex : 3x + 2 pour x = 4 → 3 × 4 + 2 = 14",
		],
	},
	"proportionnalite": {
		"titre": "Proportionnalité",
		"lecon": [
			"TABLEAU PROPORTIONNEL : on passe d'une ligne à l'autre en",
			"multipliant par le MÊME coefficient. Ex : 3 stylos → 6 €,",
			"donc 1 stylo → 2 € et 5 stylos → 10 €.",
			"POURCENTAGE : p % d'un nombre = nombre × p ÷ 100.",
			"Ex : 25 % de 80 = 80 × 25 ÷ 100 = 20",
		],
	},
	"priorites": {
		"titre": "Priorités opératoires",
		"lecon": [
			"1) PARENTHÈSES d'abord  2) × et ÷  3) + et - en dernier.",
			"Ex : 5 + 3 × 4 = 5 + 12 = 17 (PAS 32 !)",
			"Ex : (5 + 3) × 4 = 8 × 4 = 32",
		],
	},
	"geometrie": {
		"titre": "Angles & aires",
		"lecon": [
			"TRIANGLE : la somme des trois angles fait TOUJOURS 180°.",
			"Ex : angles de 60° et 80° → le troisième fait 180-60-80 = 40°.",
			"AIRE du rectangle : L × l.  AIRE du triangle : base × hauteur ÷ 2.",
			"PÉRIMÈTRE du rectangle : 2 × (L + l).",
		],
	},
}


## Une question de la notion demandée ("" = notion au hasard), au niveau
## demandé (1 à 3).
static func generer(notion := "", niveau := 1) -> Dictionary:
	if not NOTIONS.has(notion):
		var cles: Array = NOTIONS.keys()
		notion = cles[randi() % cles.size()]
	niveau = clampi(niveau, 1, 3)
	var q: Dictionary
	match notion:
		"relatifs":
			q = _relatifs(niveau)
		"fractions":
			q = _fractions(niveau)
		"litteral":
			q = _litteral(niveau)
		"proportionnalite":
			q = _proportionnalite(niveau)
		"priorites":
			q = _priorites(niveau)
		_:
			q = _geometrie(niveau)
	q.notion = notion
	q.niveau = niveau
	return q


static func titre(notion: String) -> String:
	return str(NOTIONS.get(notion, {}).get("titre", "Révision"))


## Mélange la bonne réponse et trois distracteurs, en GARANTISSANT quatre
## réponses uniques : un distracteur en double est décalé (son premier
## nombre est incrémenté) jusqu'à devenir distinct.
static func _emballer(enonce: String, bonne: String, distracteurs: Array,
		explication: Array) -> Dictionary:
	var re := RegEx.new()
	re.compile("-?\\d+")
	var vus := {bonne: true}
	var reponses: Array = [bonne]
	for d in distracteurs:
		var s := str(d)
		while vus.has(s):
			var m := re.search(s)
			if m == null:
				s += " "
			else:
				s = s.substr(0, m.get_start()) + str(int(m.get_string()) + 1) + s.substr(m.get_end())
		vus[s] = true
		reponses.append(s)
	reponses.shuffle()
	return {"enonce": enonce, "reponses": reponses, "bonne": reponses.find(bonne),
		"explication": explication}


## Trois distracteurs entiers uniques autour de la bonne réponse.
static func _autour(bonne: int, ecarts: Array) -> Array:
	var vus: Array = [bonne]
	var sortie: Array = []
	for e in ecarts:
		var v: int = bonne + e
		while vus.has(v):
			v += 1
		vus.append(v)
		sortie.append(v)
	return sortie


# ---------------------------------------------------------------- relatifs

static func _relatifs(niveau: int) -> Dictionary:
	match niveau:
		1:
			if randf() < 0.5:
				# Comparaison de relatifs.
				var nombres: Array = []
				while nombres.size() < 4:
					var n := randi_range(-12, 12)
					if not nombres.has(n):
						nombres.append(n)
				var plus_grand: int = nombres.max()
				var distracteurs: Array = []
				for n in nombres:
					if n != plus_grand:
						distracteurs.append(_rel(n))
				return _emballer("Quel est le plus grand nombre ?", _rel(plus_grand), distracteurs,
					["Sur la droite graduée, le plus grand est le plus À DROITE :",
					"%s. Tout positif est plus grand que tout négatif." % _rel(plus_grand)])
			# Addition de même signe.
			var a := -randi_range(2, 9)
			var b := -randi_range(2, 9)
			return _emballer("Combien font (%s) + (%s) ?" % [_rel(a), _rel(b)], _rel(a + b),
				[_rel(-(a + b)), _rel(a + b - 1), _rel(a - b)],
				["Même signe : on ajoute les distances (%d + %d = %d)" % [-a, -b, -(a + b)],
				"et on garde le signe - : réponse %s." % _rel(a + b)])
		2:
			if randf() < 0.5:
				# Addition de signes contraires.
				var a := -randi_range(3, 12)
				var b := randi_range(2, 12)
				while b == -a:
					b = randi_range(2, 12)
				var s := a + b
				return _emballer("Combien font (%s) + (%s) ?" % [_rel(a), _rel(b)], _rel(s),
					[_rel(-s), _rel(a - b), _rel(s + 2)],
					["Signes contraires : on soustrait les distances (%d et %d)" % [-a, b],
					"et on garde le signe du plus fort : %s." % _rel(s)])
			# Soustraction = addition de l'opposé.
			var a := randi_range(-6, 9)
			var b := -randi_range(2, 9)
			var s := a - b
			return _emballer("Combien font %s - (%s) ?" % [_rel(a), _rel(b)], _rel(s),
				[_rel(a + b), _rel(-s), _rel(s - 2)],
				["Soustraire, c'est AJOUTER L'OPPOSÉ :",
				"%s - (%s) = %s + %s = %s." % [_rel(a), _rel(b), _rel(a), _rel(-b), _rel(s)]])
		_:
			# Somme en chaîne de trois relatifs.
			var a := randi_range(-9, 9)
			var b := randi_range(-9, 9)
			var c := randi_range(-9, 9)
			var s := a + b + c
			var enonce := "Combien font (%s) + (%s) + (%s) ?" % [_rel(a), _rel(b), _rel(c)]
			var dis: Array = []
			for v in _autour(s, [2, -3, 5]):
				dis.append(_rel(int(v)))
			return _emballer(enonce, _rel(s), dis,
				["On regroupe : positifs (%s) et négatifs (%s)," % [
					_rel(maxi(a, 0) + maxi(b, 0) + maxi(c, 0)), _rel(mini(a, 0) + mini(b, 0) + mini(c, 0))],
				"puis signes contraires : total %s." % _rel(s)])
	return {}


static func _rel(n: int) -> String:
	return "+%d" % n if n > 0 else str(n)


# ---------------------------------------------------------------- fractions

static func _fractions(niveau: int) -> Dictionary:
	match niveau:
		1:
			# Simplification / fractions égales.
			var num := randi_range(1, 5)
			var den := randi_range(num + 1, 9)
			var k := randi_range(2, 4)
			return _emballer("Quelle fraction est ÉGALE à %d/%d ?" % [num * k, den * k],
				"%d/%d" % [num, den],
				["%d/%d" % [num + 1, den], "%d/%d" % [num, den + k], "%d/%d" % [num * k, den]],
				["On divise le haut ET le bas par %d :" % k,
				"%d/%d = %d/%d." % [num * k, den * k, num, den]])
		2:
			# Addition avec mise au même dénominateur simple (b et 2b).
			var b: int = [2, 3, 4, 5][randi() % 4]
			var a := randi_range(1, b - 1) if b > 1 else 1
			var c := randi_range(1, 2 * b - 1)
			var num := a * 2 + c
			return _emballer("Combien font %d/%d + %d/%d ?" % [a, b, c, 2 * b],
				"%d/%d" % [num, 2 * b],
				["%d/%d" % [a + c, 2 * b], "%d/%d" % [a + c, 3 * b], "%d/%d" % [num + 1, 2 * b]],
				["Même dénominateur d'abord : %d/%d = %d/%d," % [a, b, a * 2, 2 * b],
				"puis %d/%d + %d/%d = %d/%d." % [a * 2, 2 * b, c, 2 * b, num, 2 * b]])
		_:
			# Comparaison avec dénominateurs différents (b et d multiples).
			var b: int = [3, 4][randi() % 2]
			var d: int = b * 2
			var a := randi_range(1, b - 1)
			var c := randi_range(1, d - 1)
			while c * b == a * d: # jamais égales
				c = randi_range(1, d - 1)
			var gauche_plus_grande: bool = a * d > c * b
			var bonne := "%d/%d" % [a, b] if gauche_plus_grande else "%d/%d" % [c, d]
			var autre := "%d/%d" % [c, d] if gauche_plus_grande else "%d/%d" % [a, b]
			return _emballer("Quelle est la PLUS GRANDE : %d/%d ou %d/%d ?" % [a, b, c, d],
				bonne, [autre, "Elles sont égales", "Impossible à comparer"],
				["Même dénominateur : %d/%d = %d/%d." % [a, b, a * 2, d],
				"On compare %d/%d et %d/%d → %s gagne." % [a * 2, d, c, d, bonne]])
	return {}


# ---------------------------------------------------------------- littéral

static func _litteral(niveau: int) -> Dictionary:
	match niveau:
		1:
			var a := randi_range(2, 8)
			var b := randi_range(2, 8)
			return _emballer("Réduis : %dx + %dx" % [a, b], "%dx" % (a + b),
				["%dx" % (a * b), "%dx²" % (a + b), "%d" % (a + b)],
				["On regroupe les x : %d + %d = %d, donc %dx." % [a, b, a + b, a + b],
				"(3 pommes + 2 pommes = 5 pommes… pareil avec les x !)"])
		2:
			var a := randi_range(2, 6)
			var b := randi_range(1, 8)
			var c := randi_range(1, 5)
			var d := randi_range(1, b) if b > 1 else 1
			var x := a + c
			var n := b - d
			var bonne := "%dx + %d" % [x, n] if n > 0 else ("%dx" % x if n == 0 else "%dx - %d" % [x, -n])
			return _emballer("Réduis : %dx + %d + %dx - %d" % [a, b, c, d], bonne,
				["%dx + %d" % [x, b + d], "%dx" % (x + n), "%dx + %d" % [a + b, c - d if c > d else d - c]],
				["Les x ensemble : %dx + %dx = %dx." % [a, c, x],
				"Les nombres ensemble : %d - %d = %d." % [b, d, n]])
		_:
			var a := randi_range(2, 6)
			var b := randi_range(1, 9)
			var v := randi_range(2, 6)
			var r := a * v + b
			return _emballer("Calcule %dx + %d pour x = %d" % [a, b, v], str(r),
				_autour(r, [-a, a, b]),
				["On REMPLACE x par %d : %d × %d + %d," % [v, a, v, b],
				"priorité au × : %d + %d = %d." % [a * v, b, r]])
	return {}


# ---------------------------------------------------------------- proportionnalité

static func _proportionnalite(niveau: int) -> Dictionary:
	match niveau:
		1:
			var unite := randi_range(2, 5)
			var n1 := randi_range(2, 4)
			var n2 := randi_range(n1 + 1, 8)
			return _emballer("%d stylos coûtent %d €. Combien coûtent %d stylos ?" % [n1, n1 * unite, n2],
				"%d €" % (n2 * unite),
				["%d €" % (n2 * unite + n1), "%d €" % (n1 * unite + n2), "%d €" % (n2 * unite - unite)],
				["1 stylo coûte %d ÷ %d = %d €," % [n1 * unite, n1, unite],
				"donc %d stylos coûtent %d × %d = %d €." % [n2, n2, unite, n2 * unite]])
		2:
			var p: int = [10, 20, 25, 50][randi() % 4]
			var n: int = [40, 60, 80, 120, 200][randi() % 5]
			var r := n * p / 100
			return _emballer("Combien font %d %% de %d ?" % [p, n], str(r),
				_autour(r, [p, -p / 2 if p >= 2 else -1, n / 10 if n >= 10 else 2]),
				["%d %% de %d = %d × %d ÷ 100" % [p, n, n, p],
				"= %d ÷ 100 = %d." % [n * p, r]])
		_:
			var vitesse := randi_range(40, 90)
			var h1 := 2
			var h2 := randi_range(3, 5)
			return _emballer("En %d h, un train parcourt %d km. Combien en %d h ?" % [h1, vitesse * h1, h2],
				"%d km" % (vitesse * h2),
				["%d km" % (vitesse * h2 + vitesse / 2), "%d km" % (vitesse * h1 + h2), "%d km" % (vitesse * (h2 + 1))],
				["En 1 h : %d ÷ %d = %d km (le coefficient !)." % [vitesse * h1, h1, vitesse],
				"En %d h : %d × %d = %d km." % [h2, vitesse, h2, vitesse * h2]])
	return {}


# ---------------------------------------------------------------- priorités

static func _priorites(niveau: int) -> Dictionary:
	match niveau:
		1:
			var a := randi_range(2, 9)
			var b := randi_range(2, 6)
			var c := randi_range(2, 6)
			var r := a + b * c
			return _emballer("Combien font %d + %d × %d ?" % [a, b, c], str(r),
				[str((a + b) * c), str(r + b), str(a * b + c)],
				["Le × PASSE AVANT le + : %d × %d = %d d'abord," % [b, c, b * c],
				"puis %d + %d = %d. (Pas %d !)" % [a, b * c, r, (a + b) * c]])
		2:
			var a := randi_range(2, 7)
			var b := randi_range(2, 7)
			var c := randi_range(2, 5)
			var r := (a + b) * c
			return _emballer("Combien font (%d + %d) × %d ?" % [a, b, c], str(r),
				[str(a + b * c), str(r + c), str(a * c + b)],
				["Les PARENTHÈSES d'abord : %d + %d = %d," % [a, b, a + b],
				"puis %d × %d = %d." % [a + b, c, r]])
		_:
			var a := randi_range(10, 30)
			var b := randi_range(2, 5)
			var c := randi_range(2, 4)
			var d := b * randi_range(2, 4)
			var r := a - d / b * c
			return _emballer("Combien font %d - %d ÷ %d × %d ?" % [a, d, b, c], str(r),
				_autour(r, [c + 1, -b - 1, 7]),
				["× et ÷ d'abord, de gauche à droite : %d ÷ %d = %d, × %d = %d," % [d, b, d / b, c, d / b * c],
				"puis %d - %d = %d." % [a, d / b * c, r]])
	return {}


# ---------------------------------------------------------------- géométrie

static func _geometrie(niveau: int) -> Dictionary:
	match niveau:
		1:
			var a := randi_range(30, 90)
			var b := randi_range(30, 150 - a - 20)
			var c := 180 - a - b
			return _emballer("Un triangle a des angles de %d° et %d°. Le troisième ?" % [a, b],
				"%d°" % c, ["%d°" % (c + 10), "%d°" % (90 - mini(a, b)), "%d°" % (c - 10)],
				["La somme des angles d'un triangle fait TOUJOURS 180°.",
				"180 - %d - %d = %d°." % [a, b, c]])
		2:
			var l := randi_range(3, 9)
			var la := randi_range(l + 1, 12)
			if randf() < 0.5:
				return _emballer("Aire d'un rectangle de %d cm sur %d cm ?" % [la, l],
					"%d cm²" % (la * l), ["%d cm²" % (2 * (la + l)), "%d cm²" % (la * l * 2), "%d cm²" % (la + l)],
					["Aire du rectangle = longueur × largeur :",
					"%d × %d = %d cm². (Le périmètre, c'est %d cm.)" % [la, l, la * l, 2 * (la + l)]])
			return _emballer("Périmètre d'un rectangle de %d cm sur %d cm ?" % [la, l],
				"%d cm" % (2 * (la + l)), ["%d cm" % (la * l), "%d cm" % (la + l), "%d cm" % (2 * la + l)],
				["Périmètre = 2 × (L + l) = 2 × (%d + %d)" % [la, l],
				"= 2 × %d = %d cm." % [la + l, 2 * (la + l)]])
		_:
			var base := randi_range(4, 12) * 2 # paire → aire entière
			var h := randi_range(3, 10)
			var aire := base * h / 2
			return _emballer("Aire d'un triangle de base %d cm et hauteur %d cm ?" % [base, h],
				"%d cm²" % aire, ["%d cm²" % (base * h), "%d cm²" % (base + h), "%d cm²" % (aire + h)],
				["Aire du triangle = base × hauteur ÷ 2 :",
				"%d × %d ÷ 2 = %d cm²." % [base, h, aire]])
	return {}

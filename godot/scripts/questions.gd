class_name Questions
extends RefCounted
## Générateur de questions maths CM1 (cf. docs/programme-cm1-quetes.md :
## entiers, opérations posées, fractions, conversions).
##
## C'est LE point de branchement pédagogique d'Eluminia : en v2, ces
## questions générées seront remplacées par les missions issues des photos
## de cours (photos → IA → compétences), voir pedagogie.gd. Le format de
## sortie ne changera pas :
##   {"enonce": String, "reponses": [4 × String], "bonne": int}


static func generer() -> Dictionary:
	match randi() % 8:
		0:
			return _comparaison_entiers()
		1:
			return _addition()
		2:
			return _multiplication()
		3:
			return _division()
		4:
			return _fraction_de_quantite()
		5:
			return _comparaison_fractions()
		6:
			return _addition_fractions()
		_:
			return _conversion()


## Mélange la bonne réponse et trois distracteurs (uniques, garantis par
## l'appelant) puis retrouve l'indice de la bonne réponse.
static func _emballer(enonce: String, bonne: String, distracteurs: Array) -> Dictionary:
	var reponses: Array = [bonne]
	for d in distracteurs:
		reponses.append(str(d))
	reponses.shuffle()
	return {"enonce": enonce, "reponses": reponses, "bonne": reponses.find(bonne)}


static func _comparaison_entiers() -> Dictionary:
	# Nombres entiers jusqu'à 100 000 : comparaison.
	var nombres: Array = []
	while nombres.size() < 4:
		var n := randi_range(1000, 99999)
		if not nombres.has(n):
			nombres.append(n)
	var plus_grand: int = nombres.max()
	var distracteurs: Array = []
	for n in nombres:
		if n != plus_grand:
			distracteurs.append(n)
	return _emballer("Quel est le plus grand nombre ?", str(plus_grand), distracteurs)


static func _addition() -> Dictionary:
	var a := randi_range(120, 980)
	var b := randi_range(120, 980)
	var s := a + b
	return _emballer("Combien font %d + %d ?" % [a, b], str(s), [s + 10, s - 10, s + 100])


static func _multiplication() -> Dictionary:
	var a := randi_range(3, 9)
	var b := randi_range(3, 9)
	var p := a * b
	var distracteurs: Array = [p + a, p - b, p + a + b] if a != b else [p + a, p - a, p + 2 * a]
	return _emballer("Combien font %d × %d ?" % [a, b], str(p), distracteurs)


static func _division() -> Dictionary:
	# Division euclidienne à diviseur d'un chiffre : on demande le quotient.
	var b := randi_range(3, 9)
	var q := randi_range(4, 12)
	var r := randi_range(0, b - 1)
	var n := b * q + r
	return _emballer("Quel est le quotient de %d ÷ %d ?" % [n, b], str(q), [q - 1, q + 1, q + 2])


static func _fraction_de_quantite() -> Dictionary:
	# Moitié / tiers / quart d'une quantité (fractions simples).
	var infos: Array = [[2, "la moitié"], [3, "le tiers"], [4, "le quart"]]
	var choix: Array = infos[randi() % infos.size()]
	var d: int = choix[0]
	var v := randi_range(3, 12)
	var n := v * d
	return _emballer("Quel est %s de %d ?" % [choix[1], n], str(v), [v + 1, v - 1, v + d])


static func _comparaison_fractions() -> Dictionary:
	# Comparaison de fractions de même dénominateur.
	var d := randi_range(5, 9)
	var numerateurs: Array = []
	while numerateurs.size() < 4:
		var n := randi_range(1, d - 1)
		if not numerateurs.has(n):
			numerateurs.append(n)
	var plus_grand: int = numerateurs.max()
	var distracteurs: Array = []
	for n in numerateurs:
		if n != plus_grand:
			distracteurs.append("%d/%d" % [n, d])
	return _emballer("Quelle fraction est la plus grande ?", "%d/%d" % [plus_grand, d], distracteurs)


static func _addition_fractions() -> Dictionary:
	# Addition de fractions de même dénominateur.
	var d := randi_range(4, 9)
	var a := randi_range(1, d - 2)
	var b := randi_range(1, d - a - 1)
	var s := a + b
	return _emballer("Combien font %d/%d + %d/%d ?" % [a, d, b, d], "%d/%d" % [s, d],
		["%d/%d" % [s + 1, d], "%d/%d" % [s, 2 * d], "%d/%d" % [maxi(a, b), d]])


static func _conversion() -> Dictionary:
	match randi() % 3:
		0:
			var m := randi_range(2, 9)
			return _emballer("Combien de centimètres dans %d m ?" % m,
				str(m * 100), [m * 10, m * 1000, m * 100 + 10])
		1:
			var kg := randi_range(2, 9)
			return _emballer("Combien de grammes dans %d kg ?" % kg,
				str(kg * 1000), [kg * 100, kg * 10, kg * 1000 + 100])
		_:
			var h := randi_range(2, 6)
			return _emballer("Combien de minutes dans %d heures ?" % h,
				str(h * 60), [h * 100, h * 30, h * 60 + 10])

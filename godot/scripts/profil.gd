extends Node
## Autoload `Profil` — LE système de jeu d'Iluminia : économie, progression
## et collection, persistés dans user:// (IndexedDB sur le web).
##
## LA BOUCLE DU JOUEUR (pourquoi on rejoue) :
##   jouer → TROPHÉES (monter de LIGUE, l'insigne du lobby)
##         → PIÈCES d'or (boutique : œufs, couleurs de Lumins)
##         → ŒUFS DE DRAGON (1er du match) → éclosion au SANCTUAIRE
##         → COLLECTION des 6 espèces → choisir son COMPAGNON qui vole
##           à côté de soi EN PARTIE, visible par tous.
##   + niveau par héros (paliers de couleurs) et niveau de compte.

const CHEMIN := "user://profil.cfg"

## Ligues de trophées : le rang à défendre (badge affiché au lobby).
const LIGUES := [
	{"nom": "Bronze", "seuil": 0, "couleur": Color(0.72, 0.48, 0.3)},
	{"nom": "Argent", "seuil": 100, "couleur": Color(0.75, 0.78, 0.85)},
	{"nom": "Or", "seuil": 250, "couleur": Color("ffc928")},
	{"nom": "Cristal", "seuil": 450, "couleur": Color("20cff3")},
	{"nom": "Légende", "seuil": 700, "couleur": Color("ef4e9b")},
]

## Trophées par rang de fin de match (jamais en dessous de 0 au total).
const TROPHEES_PAR_RANG := [30, 15, 5, -10]

const PALIERS_VARIANTES := [1, 2, 4, 6]  ## niveau de héros par variante
const PRIX_VARIANTE := 80                ## …ou achat direct en pièces
const PRIX_OEUF := 150
const XP_PAR_NIVEAU_HEROS := 100.0

var personnage := "Max"
var variantes := {}              ## nom → indice de variante choisie
var debloquees := {}             ## nom → indices achetés/offerts
var xp_heros := {}               ## nom → XP gagnée en jouant CE héros
var xp := 0.0
var niveau := 1
var pieces := 0                  ## monnaie principale
var trophees := 0
var oeufs := 0                   ## œufs à faire éclore au Sanctuaire
var dragons := {}                ## espèce → nombre obtenu (collection)
var compagnon := ""              ## espèce qui vole à tes côtés en partie
var dernier_cadeau := 0
var son_actif := true
var tutoriel_fait := false


func _ready() -> void:
	for nom in Personnage3D.FICHES:
		debloquees[nom] = [0]
		variantes[nom] = 0
		xp_heros[nom] = 0.0
	charger()
	Audio.definir_son(son_actif)


# ---------------------------------------------------------------- compte

func xp_requise() -> float:
	return 100.0 * pow(1.3, niveau - 1)


func gagner_xp(quantite: float) -> int:
	xp += quantite
	var niveaux_gagnes := 0
	while xp >= xp_requise():
		xp -= xp_requise()
		niveau += 1
		niveaux_gagnes += 1
	sauver()
	return niveaux_gagnes


func gagner_pieces(quantite: int) -> void:
	pieces += quantite
	sauver()


func depenser(cout: int) -> bool:
	if pieces < cout:
		return false
	pieces -= cout
	sauver()
	return true


## Trophées gagnés/perdus selon le rang (0 = premier). Retourne le delta.
func gagner_trophees(rang: int) -> int:
	var delta: int = TROPHEES_PAR_RANG[clampi(rang, 0, TROPHEES_PAR_RANG.size() - 1)]
	trophees = maxi(trophees + delta, 0)
	sauver()
	return delta


func ligue() -> Dictionary:
	var courante: Dictionary = LIGUES[0]
	for l in LIGUES:
		if trophees >= int(l.seuil):
			courante = l
	return courante


## Prochaine ligue (ou vide si Légende atteinte).
func ligue_suivante() -> Dictionary:
	for l in LIGUES:
		if trophees < int(l.seuil):
			return l
	return {}


# ---------------------------------------------------------------- héros

func niveau_heros(nom: String) -> int:
	return 1 + int(float(xp_heros.get(nom, 0.0)) / XP_PAR_NIVEAU_HEROS)


func progres_heros(nom: String) -> float:
	return fposmod(float(xp_heros.get(nom, 0.0)), XP_PAR_NIVEAU_HEROS) / XP_PAR_NIVEAU_HEROS


func gagner_xp_heros(nom: String, montant: float) -> int:
	var avant := niveau_heros(nom)
	xp_heros[nom] = float(xp_heros.get(nom, 0.0)) + montant
	sauver()
	return niveau_heros(nom) - avant


func choisir_personnage(nom: String) -> void:
	if Personnage3D.FICHES.has(nom):
		personnage = nom
		sauver()


## Variante accessible par palier de niveau du héros OU achetée.
func variante_accessible(nom: String, indice: int) -> bool:
	if indice == 0 or debloquees.get(nom, [0]).has(indice):
		return true
	return niveau_heros(nom) >= PALIERS_VARIANTES[clampi(indice, 0, PALIERS_VARIANTES.size() - 1)]


## Achat direct d'une variante en pièces (boutique de la garde-robe).
func acheter_variante(nom: String, indice: int) -> bool:
	if variante_accessible(nom, indice) or not depenser(PRIX_VARIANTE):
		return false
	debloquees[nom].append(indice)
	sauver()
	return true


func choisir_variante(nom: String, indice: int) -> bool:
	if variante_accessible(nom, indice):
		variantes[nom] = indice
		sauver()
		return true
	return false


func couleur_de(nom: String) -> Color:
	var fiche: Dictionary = Personnage3D.FICHES.get(nom, {})
	if fiche.is_empty():
		return Color.WHITE
	var palette: Array = fiche.variantes
	return palette[clampi(int(variantes.get(nom, 0)), 0, palette.size() - 1)]


# ---------------------------------------------------------------- dragons

func ajouter_oeuf(n := 1) -> void:
	oeufs += n
	sauver()


## Éclot un œuf : tire une espèce (pondérée par rareté). Doublon → pièces.
func eclore() -> Dictionary:
	if oeufs <= 0:
		return {}
	oeufs -= 1
	var total := 0
	for espece in Personnage3D.ESPECES:
		total += int(Personnage3D.ESPECES[espece].poids)
	var tirage := randi() % total
	var choisie := ""
	for espece in Personnage3D.ESPECES:
		tirage -= int(Personnage3D.ESPECES[espece].poids)
		if tirage < 0:
			choisie = espece
			break
	var nouveau: bool = not dragons.has(choisie)
	dragons[choisie] = int(dragons.get(choisie, 0)) + 1
	var bonus := 0
	if not nouveau:
		bonus = 50
		pieces += bonus
	elif compagnon == "":
		compagnon = choisie # premier dragon : il t'accompagne d'office
	sauver()
	return {"espece": choisie, "nouveau": nouveau, "pieces_bonus": bonus}


func choisir_compagnon(espece: String) -> bool:
	if dragons.has(espece):
		compagnon = espece
		sauver()
		return true
	return false


# ---------------------------------------------------------------- cadeau et son

func _jour_courant() -> int:
	return int(Time.get_unix_time_from_system() / 86400.0)


func cadeau_disponible() -> bool:
	return _jour_courant() > dernier_cadeau


## Cadeau du jour : un œuf (1 fois sur 3) ou une bourse de pièces.
func ouvrir_cadeau() -> Dictionary:
	if not cadeau_disponible():
		return {}
	dernier_cadeau = _jour_courant()
	var resultat := {}
	if randi() % 3 == 0:
		oeufs += 1
		resultat = {"type": "oeuf"}
	else:
		pieces += 80
		resultat = {"type": "pieces", "pieces": 80}
	sauver()
	return resultat


func basculer_son() -> void:
	son_actif = not son_actif
	Audio.definir_son(son_actif)
	sauver()


# ---------------------------------------------------------------- persistance

func sauver() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("profil", "personnage", personnage)
	cfg.set_value("profil", "variantes", variantes)
	cfg.set_value("profil", "debloquees", debloquees)
	cfg.set_value("profil", "xp_heros", xp_heros)
	cfg.set_value("profil", "xp", xp)
	cfg.set_value("profil", "niveau", niveau)
	cfg.set_value("profil", "pieces", pieces)
	cfg.set_value("profil", "trophees", trophees)
	cfg.set_value("profil", "oeufs", oeufs)
	cfg.set_value("profil", "dragons", dragons)
	cfg.set_value("profil", "compagnon", compagnon)
	cfg.set_value("profil", "dernier_cadeau", dernier_cadeau)
	cfg.set_value("profil", "son_actif", son_actif)
	cfg.set_value("profil", "tutoriel_fait", tutoriel_fait)
	cfg.save(CHEMIN)


func charger() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CHEMIN) != OK:
		return
	personnage = cfg.get_value("profil", "personnage", personnage)
	var v: Dictionary = cfg.get_value("profil", "variantes", variantes)
	var d: Dictionary = cfg.get_value("profil", "debloquees", debloquees)
	var xh: Dictionary = cfg.get_value("profil", "xp_heros", xp_heros)
	for nom in Personnage3D.FICHES:
		if v.has(nom):
			variantes[nom] = int(v[nom])
		if d.has(nom) and d[nom] is Array:
			debloquees[nom] = d[nom]
		if xh.has(nom):
			xp_heros[nom] = float(xh[nom])
	xp = float(cfg.get_value("profil", "xp", xp))
	niveau = int(cfg.get_value("profil", "niveau", niveau))
	# Migration : les anciennes « étoiles » deviennent des pièces.
	pieces = int(cfg.get_value("profil", "pieces", cfg.get_value("profil", "etoiles", pieces)))
	trophees = int(cfg.get_value("profil", "trophees", trophees))
	oeufs = int(cfg.get_value("profil", "oeufs", oeufs))
	dragons = cfg.get_value("profil", "dragons", dragons)
	compagnon = str(cfg.get_value("profil", "compagnon", compagnon))
	dernier_cadeau = int(cfg.get_value("profil", "dernier_cadeau", dernier_cadeau))
	son_actif = bool(cfg.get_value("profil", "son_actif", son_actif))
	tutoriel_fait = bool(cfg.get_value("profil", "tutoriel_fait", tutoriel_fait))
	if not Personnage3D.FICHES.has(personnage):
		personnage = "Max"

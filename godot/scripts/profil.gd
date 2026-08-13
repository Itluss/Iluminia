extends Node
## Autoload `Profil` — la méta-progression légère du joueur, persistée dans
## user:// (sur le web : IndexedDB, survit aux rechargements de page).
##
## Contenu : niveau/XP de compte (lobby de la planche), étoiles, personnage
## choisi et variantes de couleurs débloquées (garde-robe), cadeau
## quotidien, réglage du son. Tout écran passe par cette API.

const CHEMIN := "user://profil.cfg"

## Niveau de héros exigé pour chaque variante de couleur (évolution VISIBLE :
## la garde-robe affiche « Niv 2 », « Niv 4 »… sur les couleurs verrouillées).
const PALIERS_VARIANTES := [1, 2, 4, 6]
const XP_PAR_NIVEAU_HEROS := 100.0

var personnage := "Max"          ## le Lumin joué
var variantes := {}              ## nom → indice de variante choisie
var debloquees := {}             ## nom → indices offerts par les cadeaux
var xp_heros := {}               ## nom → XP gagnée en jouant CE héros
var xp := 0.0
var niveau := 1
var etoiles := 0
var dernier_cadeau := 0          ## jour unix du dernier coffre ouvert
var son_actif := true
var tutoriel_fait := false


func _ready() -> void:
	for nom in Personnage3D.FICHES:
		debloquees[nom] = [0]
		variantes[nom] = 0
		xp_heros[nom] = 0.0
	charger()
	Audio.definir_son(son_actif)


## XP nécessaire pour passer au niveau suivant.
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


func gagner_etoiles(quantite: int) -> void:
	etoiles += quantite
	sauver()


func choisir_personnage(nom: String) -> void:
	if Personnage3D.FICHES.has(nom):
		personnage = nom
		sauver()


# ---------------------------------------------------------------- héros

func niveau_heros(nom: String) -> int:
	return 1 + int(float(xp_heros.get(nom, 0.0)) / XP_PAR_NIVEAU_HEROS)


## Progression vers le prochain niveau du héros (0..1).
func progres_heros(nom: String) -> float:
	return fposmod(float(xp_heros.get(nom, 0.0)), XP_PAR_NIVEAU_HEROS) / XP_PAR_NIVEAU_HEROS


func gagner_xp_heros(nom: String, montant: float) -> int:
	var avant := niveau_heros(nom)
	xp_heros[nom] = float(xp_heros.get(nom, 0.0)) + montant
	sauver()
	return niveau_heros(nom) - avant


## Une variante est accessible par palier de niveau du héros OU par cadeau.
func variante_accessible(nom: String, indice: int) -> bool:
	if indice == 0 or debloquees.get(nom, [0]).has(indice):
		return true
	return niveau_heros(nom) >= PALIERS_VARIANTES[clampi(indice, 0, PALIERS_VARIANTES.size() - 1)]


func choisir_variante(nom: String, indice: int) -> bool:
	if variante_accessible(nom, indice):
		variantes[nom] = indice
		sauver()
		return true
	return false


## Couleur effective d'un personnage (sa variante choisie).
func couleur_de(nom: String) -> Color:
	var fiche: Dictionary = Personnage3D.FICHES.get(nom, {})
	if fiche.is_empty():
		return Color.WHITE
	var palette: Array = fiche.variantes
	return palette[clampi(int(variantes.get(nom, 0)), 0, palette.size() - 1)]


# ---------------------------------------------------------------- cadeau quotidien

func _jour_courant() -> int:
	return int(Time.get_unix_time_from_system() / 86400.0)


func cadeau_disponible() -> bool:
	return _jour_courant() > dernier_cadeau


## Ouvre le coffre : débloque une variante au hasard, ou des étoiles si la
## garde-robe est complète. Retourne {type, nom, indice, etoiles}.
func ouvrir_cadeau() -> Dictionary:
	if not cadeau_disponible():
		return {}
	dernier_cadeau = _jour_courant()
	var verrouillees: Array = []
	for nom in Personnage3D.FICHES:
		var palette: Array = Personnage3D.FICHES[nom].variantes
		for i in palette.size():
			if not variante_accessible(nom, i):
				verrouillees.append({"nom": nom, "indice": i})
	var resultat := {}
	if verrouillees.is_empty():
		etoiles += 10
		resultat = {"type": "etoiles", "etoiles": 10}
	else:
		var choix: Dictionary = verrouillees[randi() % verrouillees.size()]
		debloquees[choix.nom].append(choix.indice)
		etoiles += 2
		resultat = {"type": "variante", "nom": choix.nom, "indice": choix.indice, "etoiles": 2}
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
	cfg.set_value("profil", "xp", xp)
	cfg.set_value("profil", "niveau", niveau)
	cfg.set_value("profil", "etoiles", etoiles)
	cfg.set_value("profil", "dernier_cadeau", dernier_cadeau)
	cfg.set_value("profil", "son_actif", son_actif)
	cfg.set_value("profil", "xp_heros", xp_heros)
	cfg.set_value("profil", "tutoriel_fait", tutoriel_fait)
	cfg.save(CHEMIN)


func charger() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CHEMIN) != OK:
		return
	personnage = cfg.get_value("profil", "personnage", personnage)
	var v: Dictionary = cfg.get_value("profil", "variantes", variantes)
	var d: Dictionary = cfg.get_value("profil", "debloquees", debloquees)
	for nom in Personnage3D.FICHES:
		if v.has(nom):
			variantes[nom] = int(v[nom])
		if d.has(nom) and d[nom] is Array:
			debloquees[nom] = d[nom]
	xp = float(cfg.get_value("profil", "xp", xp))
	niveau = int(cfg.get_value("profil", "niveau", niveau))
	etoiles = int(cfg.get_value("profil", "etoiles", etoiles))
	dernier_cadeau = int(cfg.get_value("profil", "dernier_cadeau", dernier_cadeau))
	son_actif = bool(cfg.get_value("profil", "son_actif", son_actif))
	var xh: Dictionary = cfg.get_value("profil", "xp_heros", xp_heros)
	for nom in Personnage3D.FICHES:
		if xh.has(nom):
			xp_heros[nom] = float(xh[nom])
	tutoriel_fait = bool(cfg.get_value("profil", "tutoriel_fait", tutoriel_fait))
	if not Personnage3D.FICHES.has(personnage):
		personnage = "Max"

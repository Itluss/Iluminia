extends Node
## Autoload `Profil` — la méta-progression légère du joueur, persistée dans
## user:// (sur le web : IndexedDB, survit aux rechargements de page).
##
## Contenu : niveau/XP de compte (lobby de la planche), étoiles, personnage
## choisi et variantes de couleurs débloquées (garde-robe), cadeau
## quotidien, réglage du son. Tout écran passe par cette API.

const CHEMIN := "user://profil.cfg"

var personnage := "Max"          ## le Lumin joué
var variantes := {}              ## nom → indice de variante choisie
var debloquees := {}             ## nom → tableau d'indices débloqués
var xp := 0.0
var niveau := 1
var etoiles := 0
var dernier_cadeau := 0          ## jour unix du dernier coffre ouvert
var son_actif := true


func _ready() -> void:
	for nom in Personnage3D.FICHES:
		debloquees[nom] = [0]
		variantes[nom] = 0
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


func choisir_variante(nom: String, indice: int) -> bool:
	if debloquees.get(nom, [0]).has(indice):
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
			if not debloquees[nom].has(i):
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
	if not Personnage3D.FICHES.has(personnage):
		personnage = "Max"

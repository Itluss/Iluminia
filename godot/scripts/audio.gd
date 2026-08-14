extends Node
## Autoload `Audio` — tous les sons sont synthétisés au démarrage (aucun
## fichier audio) : petites formes d'ondes 16 bits générées en mémoire,
## esprit « chiptune » assumé, très léger pour l'export web.

const FREQ_ECH := 22050

var _sons := {}
var _lecteurs: Array[AudioStreamPlayer] = []
var _prochain := 0


func _ready() -> void:
	# Petit pool de lecteurs pour superposer plusieurs sons.
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.volume_db = -9.0
		add_child(p)
		_lecteurs.append(p)

	_sons["coup_recu"] = _wav(_ton(130.0, 70.0, 0.18, "carre", 0.6))
	_sons["ramasser"] = _wav(_ton(500.0, 950.0, 0.12, "sinus", 0.6))       # capture du dragon
	_sons["vol"] = _wav(_enchainer([_ton(700.0, 400.0, 0.07, "carre", 0.5), _ton(400.0, 900.0, 0.1, "sinus", 0.55)]))
	_sons["onde"] = _wav(_enchainer([_ton(0.0, 0.0, 0.08, "bruit", 0.5), _ton(180.0, 60.0, 0.18, "sinus", 0.7)]))
	_sons["dash"] = _wav(_ton(0.0, 0.0, 0.1, "bruit", 0.25))
	_sons["bouclier"] = _wav(_ton(300.0, 800.0, 0.18, "sinus", 0.45))
	_sons["cristal"] = _wav(_enchainer([_ton(880.0, 880.0, 0.07, "sinus", 0.5), _ton(1320.0, 1320.0, 0.14, "sinus", 0.45)]))
	_sons["ko"] = _wav(_ton(300.0, 80.0, 0.45, "carre", 0.5))
	_sons["mauvaise"] = _wav(_enchainer([_ton(220.0, 220.0, 0.12, "carre", 0.45), _ton(160.0, 160.0, 0.2, "carre", 0.45)]))
	_sons["clic"] = _wav(_ton(900.0, 700.0, 0.05, "sinus", 0.4))
	_sons["denied"] = _wav(_ton(120.0, 100.0, 0.08, "carre", 0.35))
	_sons["depart"] = _wav(_enchainer([_ton(523.0, 523.0, 0.09, "sinus", 0.6), _ton(784.0, 784.0, 0.14, "sinus", 0.6)]))
	_sons["victoire"] = _wav(_enchainer([
		_ton(523.0, 523.0, 0.12, "sinus", 0.6), _ton(659.0, 659.0, 0.12, "sinus", 0.6),
		_ton(784.0, 784.0, 0.12, "sinus", 0.6), _ton(1047.0, 1047.0, 0.3, "sinus", 0.6),
	]))
	_sons["eveil"] = _wav(_enchainer([
		_ton(440.0, 660.0, 0.1, "sinus", 0.55), _ton(660.0, 990.0, 0.12, "sinus", 0.55),
		_ton(990.0, 1320.0, 0.22, "sinus", 0.5),
	])) # transformation : arpège ascendant
	_sons["super_pret"] = _wav(_enchainer([
		_ton(784.0, 784.0, 0.08, "sinus", 0.5), _ton(1047.0, 1047.0, 0.16, "sinus", 0.55),
	]))
	_sons["super"] = _wav(_enchainer([
		_ton(0.0, 0.0, 0.06, "bruit", 0.5), _ton(200.0, 900.0, 0.16, "scie", 0.45),
		_ton(900.0, 1400.0, 0.2, "sinus", 0.5),
	])) # déflagration héroïque
	_sons["podium"] = _wav(_enchainer([
		_ton(392.0, 392.0, 0.11, "sinus", 0.6), _ton(523.0, 523.0, 0.11, "sinus", 0.6),
		_ton(659.0, 659.0, 0.11, "sinus", 0.6), _ton(784.0, 784.0, 0.11, "sinus", 0.6),
		_ton(1047.0, 1047.0, 0.35, "sinus", 0.65),
	]))


## Coupe ou rétablit tout le son (réglage du lobby, persisté par Profil).
func definir_son(actif: bool) -> void:
	AudioServer.set_bus_mute(0, not actif)


func jouer(nom: String) -> void:
	if not _sons.has(nom):
		return
	var p := _lecteurs[_prochain]
	_prochain = (_prochain + 1) % _lecteurs.size()
	p.stream = _sons[nom]
	p.pitch_scale = randf_range(0.94, 1.06) # petite variation, moins répétitif
	p.play()


## Synthèse d'un ton glissant de freq_debut à freq_fin, volume décroissant.
## Formes : "sinus", "carre", "scie", "bruit".
func _ton(freq_debut: float, freq_fin: float, duree: float, forme: String, volume: float) -> PackedFloat32Array:
	var n := int(duree * FREQ_ECH)
	var sortie := PackedFloat32Array()
	sortie.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / float(n)
		var f := lerpf(freq_debut, freq_fin, t)
		phase += TAU * f / FREQ_ECH
		var v := 0.0
		match forme:
			"sinus":
				v = sin(phase)
			"carre":
				v = signf(sin(phase))
			"scie":
				v = 2.0 * fposmod(phase / TAU, 1.0) - 1.0
			"bruit":
				v = randf_range(-1.0, 1.0)
		sortie[i] = v * volume * (1.0 - t) # enveloppe : décroissance linéaire
	return sortie


func _enchainer(parties: Array) -> PackedFloat32Array:
	var sortie := PackedFloat32Array()
	for p in parties:
		sortie.append_array(p)
	return sortie


## Emballe les échantillons dans un AudioStreamWAV 16 bits mono.
func _wav(echantillons: PackedFloat32Array) -> AudioStreamWAV:
	var flux := AudioStreamWAV.new()
	flux.format = AudioStreamWAV.FORMAT_16_BITS
	flux.mix_rate = FREQ_ECH
	flux.stereo = false
	var octets := PackedByteArray()
	octets.resize(echantillons.size() * 2)
	for i in echantillons.size():
		octets.encode_s16(i * 2, int(clampf(echantillons[i], -1.0, 1.0) * 32000.0))
	flux.data = octets
	return flux

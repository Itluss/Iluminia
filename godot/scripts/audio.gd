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

	_sons["coup"] = _wav(_ton(320.0, 180.0, 0.08, "carre", 0.5))
	_sons["impact"] = _wav(_ton(0.0, 0.0, 0.05, "bruit", 0.5))
	_sons["coup_recu"] = _wav(_ton(130.0, 70.0, 0.18, "carre", 0.6))
	_sons["ramasser"] = _wav(_ton(500.0, 950.0, 0.12, "sinus", 0.6))
	_sons["orbe"] = _wav(_enchainer([_ton(880.0, 880.0, 0.1, "sinus", 0.5), _ton(1320.0, 1320.0, 0.22, "sinus", 0.45)]))
	_sons["niveau"] = _wav(_enchainer([_ton(523.0, 523.0, 0.09, "sinus", 0.6), _ton(659.0, 659.0, 0.09, "sinus", 0.6), _ton(784.0, 784.0, 0.16, "sinus", 0.6)]))
	_sons["tourbillon"] = _wav(_ton(0.0, 0.0, 0.25, "bruit", 0.4))
	_sons["nova"] = _wav(_enchainer([_ton(90.0, 55.0, 0.3, "sinus", 0.8), _ton(0.0, 0.0, 0.12, "bruit", 0.4)]))
	_sons["roulade"] = _wav(_ton(0.0, 0.0, 0.1, "bruit", 0.25))
	_sons["mort"] = _wav(_ton(300.0, 90.0, 0.5, "carre", 0.5))
	_sons["mort_ennemi"] = _wav(_ton(420.0, 140.0, 0.22, "sinus", 0.55))
	_sons["rage"] = _wav(_ton(110.0, 70.0, 0.5, "scie", 0.55))
	_sons["souffle"] = _wav(_ton(0.0, 0.0, 0.2, "bruit", 0.35))
	_sons["victoire"] = _wav(_enchainer([
		_ton(523.0, 523.0, 0.12, "sinus", 0.6), _ton(659.0, 659.0, 0.12, "sinus", 0.6),
		_ton(784.0, 784.0, 0.12, "sinus", 0.6), _ton(1047.0, 1047.0, 0.3, "sinus", 0.6),
	]))


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

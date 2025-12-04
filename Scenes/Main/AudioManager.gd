extends Node

var _sounds = {}

func _ready():
	for child in get_children():
		if child is AudioStreamPlayer:
			_sounds[child.name] = child

func play_song(track_name: String, from_position: float = 0.0):
	if _sounds.has(track_name):
		var player = _sounds[track_name]
		
		player.play(from_position)
	else:
		push_warning("AudioManager: Som '" + track_name + "' não encontrado.")

func get_player(track_name: String) -> AudioStreamPlayer:
	if _sounds.has(track_name):
		return _sounds[track_name]
	else:
		push_error("AudioManager: Tentativa de acessar player inexistente: " + track_name)
		return null

func stop(track_name: String):
	if _sounds.has(track_name):
		_sounds[track_name].stop()

func stop_all():
	for nome in _sounds:
		_sounds[nome].stop()

func is_playing(track_name : String) -> bool:
	if _sounds.has(track_name):
		return (_sounds[track_name] as AudioStreamPlayer).playing
	else:
		push_error("AudioManager: Tentativa de acessar player inexistente: " + track_name)
		return false

extends Control

@export var master_container : VBoxContainer
@export var music_container : VBoxContainer
@export var sfx_container : VBoxContainer

@export var master_bar : TextureProgressBar
@export var music_bar : TextureProgressBar
@export var sfx_bar : TextureProgressBar

@export var back_button : Button


# ======================================================
# ================ CONFIGURAÇÃO DE UI ==================
# ======================================================

func _change_bar_value(bar : TextureProgressBar, added_value : float) -> void:
	bar.value = clamp(bar.value + added_value, bar.min_value, bar.max_value)


func _connect_signal(container : VBoxContainer, button_name: String, bar : TextureProgressBar, value: float) -> void:
	var button = container.find_child(button_name, true)
	if button:
		button.pressed.connect(_change_bar_value.bind(bar, value))


func _connect_focus_neighbors(container : VBoxContainer) -> void:
	var minus_button = container.find_child("MinusButton", true)
	var plus_button = container.find_child("PlusButton", true)
	var mute_button = container.find_child("MuteButton", true)
	var full_button = container.find_child("FullVolumeButton", true)
	
	# Minus ↔ Plus
	if minus_button and plus_button:
		minus_button.focus_neighbor_right = plus_button.get_path()
		plus_button.focus_neighbor_left = minus_button.get_path()
	
	# Mute ↔ FullVolume
	if mute_button and full_button:
		mute_button.focus_neighbor_right = full_button.get_path()
		full_button.focus_neighbor_left = mute_button.get_path()

	if container == master_container and back_button:
		if minus_button:
			minus_button.focus_neighbor_top = back_button.get_path()
		if plus_button:
			plus_button.focus_neighbor_top = back_button.get_path()
		back_button.focus_neighbor_bottom = minus_button.get_path() if minus_button else plus_button.get_path()


func _connect_buttons(container : VBoxContainer) -> void:
	var bar : TextureProgressBar = container.find_child("VolumeSlider", true)
	_connect_signal(container, "MinusButton", bar, -0.05)
	_connect_signal(container, "PlusButton", bar, 0.05)
	_connect_signal(container, "FullVolumeButton", bar, 1.0)
	_connect_signal(container, "MuteButton", bar, -1.0)
	_connect_focus_neighbors(container)

func _on_master_bar_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(value))
	SaveManager.settings_data.master_volume = value


func _on_music_bar_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(1, linear_to_db(value))
	SaveManager.settings_data.music_volume = value


func _on_sfx_bar_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(2, linear_to_db(value))
	SaveManager.settings_data.sfx_volume = value

func _apply_saved_settings():
	var s = SaveManager.settings_data

	if s.master_volume != null:
		master_bar.value = s.master_volume
		_on_master_bar_value_changed(s.master_volume)

	if s.music_volume != null:
		music_bar.value = s.music_volume
		_on_music_bar_value_changed(s.music_volume)

	if s.sfx_volume != null:
		sfx_bar.value = s.sfx_volume
		_on_sfx_bar_value_changed(s.sfx_volume)


func _on_back_button_pressed():
	SaveManager.save_settings()

func _ready() -> void:
	_connect_buttons(master_container)
	_connect_buttons(music_container)
	_connect_buttons(sfx_container)

	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)

	SaveManager.load_settings()
	_apply_saved_settings()

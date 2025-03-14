extends Control

@export var master_container : VBoxContainer
@export var music_container : VBoxContainer
@export var sfx_container : VBoxContainer

@export var master_bar : TextureProgressBar
@export var music_bar : TextureProgressBar
@export var sfx_bar : TextureProgressBar

func _change_bar_value(bar : TextureProgressBar, added_value : float) -> void:
	bar.value += added_value

func _connect_signal(container : VBoxContainer, button_name: String, bar : TextureProgressBar, value: float) -> void:
	var button = container.find_child(button_name, true)
	button.pressed.connect(_change_bar_value.bind(bar, value))

func _connect_buttons(container : VBoxContainer) -> void:
	var bar : TextureProgressBar = container.find_child("VolumeSlider", true)
	_connect_signal(container, "MinusButton", bar, -0.05)
	_connect_signal(container, "PlusButton", bar, 0.05)
	_connect_signal(container, "FullVolumeButton", bar, 1)
	_connect_signal(container, "MuteButton", bar, -1)

func _ready() -> void:
	_connect_buttons(master_container)
	_connect_buttons(music_container)
	_connect_buttons(sfx_container)
	
	master_bar.value = db_to_linear(AudioServer.get_bus_volume_db(0))
	music_bar.value = db_to_linear(AudioServer.get_bus_volume_db(1))
	sfx_bar.value = db_to_linear(AudioServer.get_bus_volume_db(2))

func _on_master_bar_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(value))

func _on_music_bar_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(1, linear_to_db(value))

func _on_sfx_bar_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(2, linear_to_db(value))

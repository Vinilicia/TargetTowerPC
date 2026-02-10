extends Control

@export var brightness_container : MarginContainer
@onready var environment : WorldEnvironment = get_tree().get_first_node_in_group("Environment")

var res1 : Vector2i = Vector2i(1280, 720)
var res2 : Vector2i = Vector2i(1440, 810)
var res3 : Vector2i = Vector2i(1920, 1080)
var resolution : Vector2i = res1

@onready var mode_button: OptionButton = $MarginContainer/VBoxContainer/ModeContainer/OptionButton
@onready var res_button: OptionButton = $MarginContainer/VBoxContainer/ResolutionContainer/OptionButton
@onready var brightness_slider: TextureProgressBar = brightness_container.find_child("BrightnessSlider", true)
@onready var back_button: Button = $MarginContainer/VBoxContainer/BackButton

const BRIGHTNESS_MIN := 0.6
const BRIGHTNESS_MAX := 1.3

func _on_window_mode_item_selected(index: int) -> void:
	match index:
		0:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			_set_window_size()
		2:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			_set_window_size()
		4:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)

	# Salva na estrutura de configurações gerais
	SaveManager.settings_data.display_mode = index


func _on_resolution_item_selected(index: int) -> void:
	match index:
		0:
			resolution = res1
		2:
			resolution = res2
		4:
			resolution = res3

	# Salva na estrutura de configurações gerais
	SaveManager.settings_data.resolution_index = index

	if !(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN):
		_set_window_size()


func _on_brightness_bar_value_changed(value: float) -> void:
	if environment and environment.environment:
		var mapped_value = lerp(BRIGHTNESS_MIN, BRIGHTNESS_MAX, value)
		environment.environment.adjustment_brightness = mapped_value

	# Salva na estrutura de configurações gerais
	SaveManager.settings_data.brightness_value = value

func _apply_saved_settings():
	var s = SaveManager.settings_data

	# Aplica modo de exibição salvo
	if s.display_mode != null:
		mode_button.select(s.display_mode)
		_on_window_mode_item_selected(s.display_mode)

	# Aplica resolução salva
	if s.resolution_index != null:
		res_button.select(s.resolution_index)
		_on_resolution_item_selected(s.resolution_index)

	# Aplica brilho salvo
	if s.brightness_value != null:
		brightness_slider.value = s.brightness_value
		_on_brightness_bar_value_changed(s.brightness_value)

func _set_window_size() -> void:
	get_window().set_size(resolution)
	get_window().move_to_center()


func _connect_signal(container : MarginContainer, button_name: String, bar : TextureProgressBar, value: float) -> void:
	var button = container.find_child(button_name, true)
	if button:
		button.pressed.connect(_change_bar_value.bind(bar, value))


func _change_bar_value(bar : TextureProgressBar, added_value : float) -> void:
	bar.value = clamp(bar.value + added_value, bar.min_value, bar.max_value)


func _connect_focus_neighbors(container : MarginContainer) -> void:
	var minus_button = container.find_child("MinusButton", true)
	var plus_button = container.find_child("PlusButton", true)
	var min_button = container.find_child("DarkestButton", true)
	var full_button = container.find_child("BrightestButton", true)
	
	if minus_button and plus_button:
		minus_button.focus_neighbor_right = plus_button.get_path()
		plus_button.focus_neighbor_left = minus_button.get_path()
	
	if min_button and full_button:
		min_button.focus_neighbor_right = full_button.get_path()
		full_button.focus_neighbor_left = min_button.get_path()


func _connect_brightness_buttons(container : MarginContainer) -> void:
	var bar : TextureProgressBar = container.find_child("BrightnessSlider", true)
	_connect_signal(container, "MinusButton", bar, -0.05)
	_connect_signal(container, "PlusButton", bar, 0.05)
	_connect_signal(container, "BrightestButton", bar, 1.0)
	_connect_signal(container, "DarkestButton", bar, -1.0)
	_connect_focus_neighbors(container)
	if bar:
		bar.value_changed.connect(_on_brightness_bar_value_changed)

func _ready() -> void:
	_connect_brightness_buttons(brightness_container)
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)

	SaveManager.load_settings()
	_apply_saved_settings()

# ======================================================
# =================== SAIR DA TELA =====================
# ======================================================

func _on_back_button_pressed():
	SaveManager.save_settings()

extends Control

@export var brightness_container : MarginContainer
@onready var environment : WorldEnvironment = get_tree().get_first_node_in_group("Environment")

# --- Resoluções ---
var res1 : Vector2i = Vector2i(1280, 720)
var res2 : Vector2i = Vector2i(1440, 810)
var res3 : Vector2i = Vector2i(1920, 1080)
var resolution : Vector2i = res1


# ============================
# ==== FUNÇÕES DE TELA =======
# ============================
func _set_window_size() -> void:
	get_window().set_size(resolution)
	get_window().move_to_center()


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


func _on_resolution_item_selected(index: int) -> void:
	match index:
		0:
			resolution = res1
		2:
			resolution = res2
		4:
			resolution = res3
	if !(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN):
		_set_window_size()



# ============================
# ==== CONTROLE DE BRILHO ====
# ============================

func _change_bar_value(bar : TextureProgressBar, added_value : float) -> void:
	bar.value = clamp(bar.value + added_value, bar.min_value, bar.max_value)


func _connect_signal(container : MarginContainer, button_name: String, bar : TextureProgressBar, value: float) -> void:
	var button = container.find_child(button_name, true)
	if button:
		button.pressed.connect(_change_bar_value.bind(bar, value))


func _connect_focus_neighbors(container : MarginContainer) -> void:
	var minus_button = container.find_child("MinusButton", true)
	var plus_button = container.find_child("PlusButton", true)
	var min_button = container.find_child("DarkestButton", true)
	var full_button = container.find_child("BrightestButton", true)
	
	# Minus ↔ Plus
	if minus_button and plus_button:
		minus_button.focus_neighbor_right = plus_button.get_path()
		plus_button.focus_neighbor_left = minus_button.get_path()
		minus_button.focus_neighbor_left = plus_button.get_path()
		plus_button.focus_neighbor_right = minus_button.get_path()
	
	# Darkest ↔ Brightest
	if min_button and full_button:
		min_button.focus_neighbor_right = full_button.get_path()
		full_button.focus_neighbor_left = min_button.get_path()
		full_button.focus_neighbor_right = min_button.get_path()
		min_button.focus_neighbor_left = full_button.get_path()


func _connect_brightness_buttons(container : MarginContainer) -> void:
	var bar : TextureProgressBar = container.find_child("BrightnessSlider", true)
	_connect_signal(container, "MinusButton", bar, -0.05)
	_connect_signal(container, "PlusButton", bar, 0.05)
	_connect_signal(container, "BrightestButton", bar, 1.0)
	_connect_signal(container, "DarkestButton", bar, -1.0)
	_connect_focus_neighbors(container)
	
	# conecta mudança da barra ao WorldEnvironment
	bar.value_changed.connect(_on_brightness_bar_value_changed)


# Limite de brilho permitido no Environment
const BRIGHTNESS_MIN := 0.6
const BRIGHTNESS_MAX := 1.3


func _on_brightness_bar_value_changed(value: float) -> void:
	if environment and environment.environment:
		# Mapeia [0, 1] → [0.6, 1.3]
		var mapped_value = lerp(BRIGHTNESS_MIN, BRIGHTNESS_MAX, value)
		environment.environment.adjustment_brightness = mapped_value


func _ready() -> void:
	_connect_brightness_buttons(brightness_container)
	
	if environment and environment.environment:
		var current = environment.environment.adjustment_brightness
		var slider : TextureProgressBar = brightness_container.find_child("BrightnessSlider", true)
		if slider:
			# Converte o valor real [0.6, 1.3] para [0, 1] para exibir corretamente na barra
			slider.value = clamp(inverse_lerp(BRIGHTNESS_MIN, BRIGHTNESS_MAX, current), 0.0, 1.0)

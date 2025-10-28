extends Control
class_name Main_Menu

@export var settings_menu : Control = null
@export var buttons_container : MarginContainer
@export var back_to_title_menu : MarginContainer

var title_screen : Control
var open : bool = false
var last_button_pressed : Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	last_button_pressed = buttons_container.get_child(0).get_child(0)

func open_menu() -> void:
	open = true
	get_tree().paused = true
	self.visible = true
	show_buttons()

func open_settings() -> void:
	last_button_pressed = buttons_container.get_child(0).get_child(1)
	buttons_container.visible = false
	settings_menu.visible = true
	settings_menu.setup_buttons()
	settings_menu.give_focus()

func open_back_to_title() -> void:
	buttons_container.visible = false
	last_button_pressed = buttons_container.get_child(0).get_child(2)
	back_to_title_menu.visible = true
	var no_button : Button = back_to_title_menu.find_child("NoButton")
	no_button.grab_focus()

func close_back_to_title() -> void:
	back_to_title_menu.visible = false
	show_buttons()

func go_back_to_title() -> void:
	title_screen.return_menu_from_game()
	queue_free()

func show_buttons() -> void:
	buttons_container.visible = true
	last_button_pressed.grab_focus()

func close_settings() -> void:
	settings_menu.setup_buttons()
	settings_menu.visible = false
	show_buttons()

func close_menu() -> void:
	last_button_pressed = buttons_container.get_child(0).get_child(0)
	open = false
	get_tree().paused = false
	self.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu") and !open:
		open_menu()

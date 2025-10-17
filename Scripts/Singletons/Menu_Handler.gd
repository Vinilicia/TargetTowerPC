extends Node

var menu_open : bool = false
var menu_screen : Control = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func set_menu(menu : Control) -> void:
	menu_screen = menu

func open_menu() -> void:
	menu_open = true
	get_tree().paused = true
	menu_screen.visible = true
	menu_screen.setup_buttons()
	menu_screen.give_focus()

func close_menu() -> void:
	menu_open = false
	get_tree().paused = false
	menu_screen.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if !menu_screen:
		return
	if event.is_action_pressed("menu") and !menu_open:
		open_menu()

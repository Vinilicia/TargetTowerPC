extends Node

var menu_open : bool = false
var menu_screen : Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func set_menu(menu : Control) -> void:
	menu_screen = menu

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu") and !menu_open:
		menu_open = true
		get_tree().paused = true
		menu_screen.visible = true
		menu_screen.give_focus()
	elif event.is_action_pressed("ui_cancel") and menu_open:
		menu_open = false
		get_tree().paused = false
		menu_screen.visible = false

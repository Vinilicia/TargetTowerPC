extends Node

var menu_open : bool = false
var menu_screen : Control

func set_menu(menu : Control) -> void:
	menu_screen = menu

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu") and !menu_open:
		menu_open = true
		Engine.time_scale = 0
		menu_screen.visible = true
		menu_screen.give_focus()
	elif event.is_action_pressed("ui_cancel") and menu_open:
		menu_open = false
		Engine.time_scale = 1
		menu_screen.visible = false

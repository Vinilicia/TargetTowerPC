extends Control

var res1 : Vector2i = Vector2i(960, 540)
var res2 : Vector2i = Vector2i(1440, 810)
var res3 : Vector2i = Vector2i(1920, 1080)
var resolution : Vector2i = res1

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

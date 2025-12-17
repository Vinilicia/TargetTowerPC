extends Control

@export var game : Node2D

@export var main_menu_path : String
@export var title_menu : MarginContainer
@export var file_select_menu : MarginContainer
@export var settings_menu : Control
@export var quit_menu : MarginContainer
@export var edit_buttons : HBoxContainer

@export var save_file_buttons : Array[Button]

var save_selected : int = 1
var on_copy : bool = false

func _ready() -> void:
	for button in save_file_buttons:
		button.initialize()
	find_child("PlayButton").grab_focus()

func return_menu_from_game() -> void:
	_ready()
	(get_parent().find_child("GameViewportContainer") as SubViewportContainer).visible = false
	game.process_mode = Node.PROCESS_MODE_DISABLED
	game.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	visible = true
	title_menu.visible = true
	file_select_menu.visible = false
	AudioManager.stop_all()
	AudioManager.play_song("FemaleTurbulence")

func show_file_select() -> void:
	title_menu.visible = false
	file_select_menu.visible = true
	var focus_button : Button = file_select_menu.find_child("BackButton")
	focus_button.grab_focus()
 
func hide_file_select() -> void:
	file_select_menu.visible = false
	title_menu.visible = true
	var focus_button : Button = title_menu.find_child("PlayButton")
	focus_button.grab_focus()

func show_quit_menu() -> void:
	title_menu.visible = false
	quit_menu.visible = true
	var focus_button : Button = quit_menu.find_child("NoButton")
	focus_button.grab_focus()
 
func hide_quit() -> void:
	quit_menu.visible = false
	title_menu.visible = true
	var focus_button : Button = title_menu.find_child("QuitButton")
	focus_button.grab_focus()

func quit() -> void:
	get_tree().quit()

func save_file_1_button_pressed() -> void:
	button_pressed(1)
	
func save_file_2_button_pressed() -> void:
	button_pressed(2)

func save_file_3_button_pressed() -> void:
	button_pressed(3)

func button_pressed(button_id : int) -> void:
	if on_copy:
		on_copy = false
		SaveManager._save(save_selected)
		_ready()
	change_edit_buttons(true)
	edit_buttons.get_child(0).grab_focus()
	save_selected = button_id
	
func instantiate_main_menu() -> void:
	var main_menu : Control = load(main_menu_path).instantiate()
	main_menu.title_screen = self
	main_menu.visible = false
	get_parent().add_child(main_menu)

func load_game(save_id) -> void:
	SaveManager._load(save_id)
	
	var bench_id := SaveManager.save_file_data.get_last_bench_id()
	var area_id := SaveManager.save_file_data.get_area_of_bench()
	
	var scene_path := "res://Scenes/Levels/Areas/Area%d/Room%d.tscn" % [area_id, bench_id]
	
	if not ResourceLoader.exists(scene_path):
		push_error("❌ Cena não encontrada: %s" % scene_path)
		return

	var room_scene: PackedScene = load(scene_path)
	
	visible = false
	instantiate_main_menu()
	game.save_id = save_id
	game.load_room(room_scene)
	AudioManager.stop_all()
	AudioManager.play_song("LostPaintings")

func load_procedural() -> void:
	var room_scene : PackedScene = load("res://Scenes/Levels/ProceduralMap/Procedural_map.tscn")
	
	visible = false
	instantiate_main_menu()
	game.save_id = 0
	game.load_room(room_scene)
	AudioManager.stop_all()
	AudioManager.play_song("DraculasCastle")

func open_button_pressed() -> void:
	on_copy = false
	load_game(save_selected)
	change_edit_buttons(false)
	
func copy_button_pressed() -> void:
	on_copy = true
	SaveManager._load(save_selected)
	change_edit_buttons(false)
	save_file_buttons[save_selected].grab_focus()

func erase_button_pressed() -> void:
	on_copy = false
	SaveManager.save_file_data = SaveDataResource.new()
	SaveManager._save(save_selected)
	change_edit_buttons(false)
	_ready()

func change_edit_buttons(to_visible : bool) -> void:
	edit_buttons.visible = to_visible
	var file_select_back_button : Button = $FileSelectMenu/VBoxContainer/BackButton
	if to_visible:
		file_select_back_button.focus_neighbor_top = file_select_back_button.get_path_to(edit_buttons.get_child(1))
		for child : Button in edit_buttons.get_children():
			child.focus_neighbor_bottom = child.get_path_to(file_select_back_button)
		for i in range(3):
			var edit_button : Button = edit_buttons.get_child(i)
			var save_button := save_file_buttons[i]
			edit_button.focus_neighbor_bottom = edit_button.get_path_to(file_select_back_button)
			edit_button.focus_neighbor_top = edit_button.get_path_to(save_button)
			save_button.focus_neighbor_bottom = save_button.get_path_to(edit_button)
	else:
		file_select_back_button.focus_neighbor_top = file_select_back_button.get_path_to(save_file_buttons[1])
		for button in save_file_buttons:
			button.focus_neighbor_bottom = button.get_path_to(file_select_back_button)

func show_settings() -> void:
	settings_menu.visible = true
	title_menu.visible = false
	var focus_button : Button = settings_menu.find_child("BackButton")
	focus_button.grab_focus()

func hide_settings() -> void:
	settings_menu.visible = false
	title_menu.visible = true
	_ready()
	var focus_button : Button = title_menu.find_child("SettingsButton")
	focus_button.grab_focus()

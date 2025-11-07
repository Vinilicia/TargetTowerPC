extends Control

@export var game : Node2D

@export var main_menu_path : String
@export var title_menu : MarginContainer
@export var file_select_menu : MarginContainer
@export var quit_menu : MarginContainer
@export var edit_buttons : HBoxContainer

@export var save_file_buttons : Array[Button]

var save_load_manager : SaveLoadManager
var save_selected : int = 1
var on_copy : bool = false

func _ready() -> void:
	save_load_manager = SaveManager
	for button in save_file_buttons:
		button.initialize()
	
	find_child("PlayButton").grab_focus()

func return_menu_from_game() -> void:
	_ready()
	game.visible = false
	game.process_mode = Node.PROCESS_MODE_DISABLED
	game.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	visible = true
	title_menu.visible = true
	file_select_menu.visible = false

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
	edit_buttons.visible = true
	save_file_buttons[button_id-1].grab_focus()
	save_selected = button_id
	if on_copy:
		on_copy = false
		save_load_manager._save(save_selected)
	
func instantiate_main_menu() -> void:
	var main_menu : Control = load(main_menu_path).instantiate()
	main_menu.title_screen = self
	main_menu.visible = false
	get_parent().add_child(main_menu)

func load_save(save_id) -> void:
	save_load_manager._load(save_id)
	
	var bench_id := save_load_manager.save_file_data.get_last_bench_id()
	var area_id := save_load_manager.save_file_data.get_area_of_bench()
	
	var scene_path := "res://Scenes/Levels/Areas/Area%d/Room%d.tscn" % [area_id, bench_id]
	
	if not ResourceLoader.exists(scene_path):
		push_error("❌ Cena não encontrada: %s" % scene_path)
		return

	var room_scene: PackedScene = load(scene_path)
	
	visible = false
	instantiate_main_menu()
	game.save_id = save_id
	game.load_room(room_scene, save_load_manager)

func open_button_pressed() -> void:
	on_copy = false
	load_save(save_selected)
	edit_buttons.visible = false
	
func copy_button_pressed() -> void:
	on_copy = true
	save_load_manager._load(save_selected)
	edit_buttons.visible = false

func erase_button_pressed() -> void:
	on_copy = false
	save_load_manager._save(save_selected)
	edit_buttons.visible = false

extends Control

@export var game : Node2D
@export var game_layer : CanvasLayer

@export var main_menu_path : String
@export var title_menu : MarginContainer
@export var settings_menu : Control
@export var file_select_menu : MarginContainer
@export var quit_menu : MarginContainer

@export var save_file_buttons : Array[Button]

func _ready() -> void:
	var save_load_manager : SaveLoadManager = SaveLoadManager.new()
	for button in save_file_buttons:
		button.initialize(save_load_manager)
	find_child("PlayButton").grab_focus()

func return_menu_from_game() -> void:
	game_layer.visible = false
	visible = true
	title_menu.visible = true
	file_select_menu.visible = false
	
func show_settings_menu() -> void:
	title_menu.visible = false
	settings_menu.visible = true
	settings_menu.give_focus()

func hide_settings_menu() -> void:
	settings_menu.visible = false
	title_menu.visible = true
	var focus_button : Button = title_menu.find_child("SettingsButton")
	focus_button.grab_focus()

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
	load_save(1)
	
func save_file_2_button_pressed() -> void:
	load_save(2)

func save_file_3_button_pressed() -> void:
	load_save(3)

func instantiate_main_menu() -> void:
	var main_menu = load(main_menu_path).instantiate()
	main_menu.title_screen = self
	get_parent().add_child(main_menu)

func load_save(save_id) -> void:
	var save_load_manager : SaveLoadManager = SaveLoadManager.new()
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

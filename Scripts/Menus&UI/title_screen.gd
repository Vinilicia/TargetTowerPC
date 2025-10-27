extends Control

@export var game : Node2D

@export var title_menu : MarginContainer
@export var settings_menu : Control
@export var file_select_menu : MarginContainer
@export var quit_menu : MarginContainer

@export var save_file_buttons : Array[Button]

func _ready() -> void:
	var save_load_manager : SaveLoadManager = SaveLoadManager.new()
	for button in save_file_buttons:
		button.initialize(save_load_manager)

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

func load_save(save_id) -> void:
	var save_load_manager : SaveLoadManager = SaveLoadManager.new()
	save_load_manager._load(save_id)
	save_load_manager.test()
	print("arrow " + str(save_load_manager.save_file_data.get_available_arrows()))
	print("bench " + str(save_load_manager.save_file_data.get_last_bench_id()))
	print()
	var scene_path := "res://Scenes/Levels/Areas/Area1/Room%d.tscn" % save_load_manager.save_file_data.get_last_bench_id()
	var room_scene: PackedScene = load(scene_path)
	visible = false
	game.save_id = save_id
	game.load_room(room_scene)

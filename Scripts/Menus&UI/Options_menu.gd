extends Control

@export var Menus_Container : MarginContainer
@export var Buttons_Container : MarginContainer

@export_group("Menus")
@export var Controls_menu : Control
@export var Audio_menu : Control
@export var Video_menu : Control

@export_group("Buttons")
@export var Controls_button : Button
@export var Audio_button : Button
@export var Video_button : Button

var last_button_pressed : Button

func _ready() -> void:
	last_button_pressed = Controls_button

func give_focus() -> void:
	Controls_button.grab_focus()

func setup_menu() -> void:
	Menus_Container.visible = true
	Buttons_Container.visible = false
	for menu in Menus_Container.get_children():
		if menu is not ColorRect:
			menu.visible = false

func setup_buttons() -> void:
	Menus_Container.visible = false
	Buttons_Container.visible = true
	for menu in Menus_Container.get_children():
		if menu is not ColorRect:
			menu.visible = false
	last_button_pressed.grab_focus()

func _on_controls_button_pressed() -> void:
	last_button_pressed = Controls_button
	setup_menu()
	Controls_menu.visible = true
	var menu_back_button : Button = Controls_menu.find_child("BackButton", true)
	if menu_back_button:
		menu_back_button.grab_focus()

func _on_audio_button_pressed() -> void:
	last_button_pressed = Audio_button
	setup_menu()
	Audio_menu.visible = true
	var menu_back_button : Button = Audio_menu.find_child("BackButton", true)
	if menu_back_button:
		menu_back_button.grab_focus()

func _on_video_button_pressed() -> void:
	last_button_pressed = Video_button
	setup_menu()
	Video_menu.visible = true
	var menu_back_button : Button = Video_menu.find_child("BackButton", true)
	if menu_back_button:
		menu_back_button.grab_focus()

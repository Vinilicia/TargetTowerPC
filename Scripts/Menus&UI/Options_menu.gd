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


func _ready() -> void:
	MenuHandler.set_menu(self)

func give_focus() -> void:
	Controls_button.grab_focus()

func setup_menu() -> void:
	Menus_Container.visible = true
	Buttons_Container.visible = false
	for menu in Menus_Container.get_children():
		if menu is not ColorRect:
			menu.visible = false

func _on_controls_button_pressed() -> void:
	setup_menu()
	Controls_menu.visible = true


func _on_audio_button_pressed() -> void:
	setup_menu()
	Audio_menu.visible = true


func _on_video_button_focus_entered() -> void:
	setup_menu()
	Video_menu.visible = true

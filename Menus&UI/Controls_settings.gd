# Controls_Options.gd
extends Control

@export var buttons_container: Control
@export var reset_button: Button
@export var back_button: Button

var input_button = preload("res://Menus&UI/InputMap_button.tscn")

var mapping: bool = false
var remapping_action = null
var remapping_button = null
var previous_event: InputEvent = null
var previous_button: Button = null

var input_actions = {
	"up": "TEXT_CONTROLS_UP",
	"down": "TEXT_CONTROLS_DOWN",
	"left": "TEXT_CONTROLS_LEFT",
	"right": "TEXT_CONTROLS_RIGHT",
	"angle up": "TEXT_CONTROLS_ANGLE_UP",
	"angle down": "TEXT_CONTROLS_ANGLE_DOWN",
	"shoot": "TEXT_CONTROLS_SHOOT",
	"jump": "TEXT_CONTROLS_JUMP",
	"dodge": "TEXT_CONTROLS_DODGE",
	"lock walk": "TEXT_CONTROLS_MOONWALK",
	"map": "TEXT_CONTROLS_MAP"
}

var forbidden_keys = [
	KEY_ENTER,
	KEY_ESCAPE,
	KEY_ALT
]

func is_forbidden(event: InputEventKey) -> bool:
	for key in forbidden_keys:
		if key == event.keycode:
			return true
	return false


func _ready() -> void:
	_create_action_list()

func _create_action_list() -> void:
	var last_button: Button = null
	var created_buttons: Array[Button] = []
	
	# Remove botões antigos
	for button in buttons_container.get_children():
		if button is Button:
			if button.pressed.is_connected(remap_action):
				button.pressed.disconnect(remap_action)
		button.queue_free()
	
	# Cria lista de ações
	for action in input_actions:
		var button: Button = input_button.instantiate()
		var action_label: Label = button.find_child("ActionLabel")
		var input_label: Label = button.find_child("InputLabel")
		
		action_label.text = tr(str(input_actions[action]))
		
		var events = InputMap.action_get_events(action)
		if events.size() > 0:
			input_label.text = events[0].as_text().trim_suffix(" (Physical)")
		else:
			input_label.text = ""
		
		buttons_container.add_child(button)
		button.pressed.connect(remap_action.bind(button, action))
		
		last_button = button
		created_buttons.append(button)
	
	# Navegação por foco
	if last_button and reset_button:
		reset_button.focus_neighbor_top = last_button.get_path()
		last_button.focus_neighbor_bottom = reset_button.get_path()
	
	for i in range(0, created_buttons.size(), 2):
		if i + 1 < created_buttons.size():
			var left_button = created_buttons[i]
			var right_button = created_buttons[i + 1]
			
			left_button.focus_neighbor_right = right_button.get_path()
			left_button.focus_neighbor_left = right_button.get_path()
			right_button.focus_neighbor_left = left_button.get_path()
			right_button.focus_neighbor_right = left_button.get_path()
	
	if created_buttons.size() > 0 and back_button:
		created_buttons[0].focus_neighbor_top = back_button.get_path()
		back_button.focus_neighbor_bottom = created_buttons[0].get_path()
	
	if created_buttons.size() > 1 and back_button:
		created_buttons[1].focus_neighbor_top = back_button.get_path()


func remap_action(button, action) -> void:
	if not mapping:
		mapping = true
		remapping_action = action
		remapping_button = button
		button.find_child("InputLabel").text = "[Press any key]"


func _input(event: InputEvent) -> void:
	if mapping:
		if event is InputEventKey:
			if not is_forbidden(event):
				var events = InputMap.action_get_events(remapping_action)
				if events.size() > 0:
					previous_event = events[0]
				remap_input(remapping_action, event)
				update_labeling(remapping_button, event)
				
				mapping = false
				remapping_button = null
				
				accept_event()


func remap_input(action, event: InputEvent) -> void:
	var previous_action = find_action_by_event(event)
	if previous_action != "":
		if previous_action != action:
			for button in buttons_container.get_children():
				if button.find_child("ActionLabel").text == input_actions[previous_action]:
					previous_button = button
			InputMap.action_erase_events(previous_action)
			InputMap.action_add_event(previous_action, previous_event)
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)


func find_action_by_event(event: InputEvent) -> String:
	for action in input_actions:
		var events = InputMap.action_get_events(action)
		if events.size() > 0:
			if events[0].is_match(event):
				return action
	return ""


func update_labeling(button: Button, event: InputEvent) -> void:
	var event_string: String = event.as_text().trim_suffix(" (Physical)")
	var previous_event_string: String
	if previous_event != null:
		previous_event_string = previous_event.as_text().trim_suffix(" (Physical)")
	button.find_child("InputLabel").text = event_string
	if previous_button != null:
		previous_button.find_child("InputLabel").text = previous_event_string
		previous_button = null
		previous_event = null


func _on_reset_button_pressed() -> void:
	InputMap.load_from_project_settings()
	_create_action_list()


func _on_back_button_pressed() -> void:
	var game : Game = get_tree().get_first_node_in_group("Game")
	if game:
		SaveManager.save_controls_for_slot(game.save_id)

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_create_action_list()

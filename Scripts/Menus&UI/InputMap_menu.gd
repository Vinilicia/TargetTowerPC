extends Control

@export var buttons_container : Control
@export var reset_button : Button
@export var parent_button : Button

var input_button = preload("res://Scenes/Menus&UI/InputMap_button.tscn")


var mapping: bool = false
var remapping_action = null
var remapping_button = null
var previous_event : InputEvent = null
var previous_button : Button = null

var input_actions = {
	"up": "Up",
	"down": "Down",
	"left": "Left",
	"right": "Right",
	"shoot": "Shoot",
	"switch arrow": "Switch Arrow",
	"map": "Map"
}

var forbidden_keys = [
	KEY_ENTER,
	KEY_ESCAPE,
	KEY_ALT
]

func is_forbidden(event : InputEventKey) -> bool:
	for key in forbidden_keys:
		if key == event.keycode:
			return true
	return false

func _ready() -> void:
	_create_action_list()

func give_focus() -> void:
	var buttons = buttons_container.get_children()
	buttons[0].grab_focus()

func _create_action_list() -> void:
	var last_button : Button = null
	InputMap.load_from_project_settings()
	for button in buttons_container.get_children():
		if button is Button:
			button.pressed.disconnect(remap_action)
		button.queue_free()
	
	for action in input_actions:
		var button : Button = input_button.instantiate()
		var action_label : Label = button.find_child("ActionLabel")
		var input_label : Label = button.find_child("InputLabel")
		
		action_label.text = input_actions[action]
		
		var events = InputMap.action_get_events(action)
		if events.size() > 0:
			input_label.text = events[0].as_text().trim_suffix(" (Physical)")
		else:
			input_label.text = ""
		
		buttons_container.add_child(button)
		button.pressed.connect(remap_action.bind(button, action))
		if last_button != null:
			button.focus_neighbor_top = last_button.get_path()
		else:
			reset_button.focus_neighbor_bottom = button.get_path()
			parent_button.focus_neighbor_right = button.get_path()
			parent_button.focus_neighbor_left = button.get_path()
		var parent_path = parent_button.get_path()
		button.focus_neighbor_left = parent_path
		button.focus_neighbor_right = parent_path
		reset_button.focus_neighbor_left = parent_path
		reset_button.focus_neighbor_right = parent_path
		
		last_button = button
		
	reset_button.focus_neighbor_top = last_button.get_path()
	last_button.focus_neighbor_bottom = reset_button.get_path()


func remap_action(button, action) -> void:
	if !mapping:
		mapping = true
		remapping_action = action
		remapping_button = button
		
		button.find_child("InputLabel").text = "[Press any key]"

func _input(event: InputEvent) -> void:
	if mapping:
		if event is InputEventKey:
			if !is_forbidden(event):
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
	var event_string : String = event.as_text().trim_suffix(" (Physical)")
	var previous_event_string : String
	if previous_event != null:
		previous_event_string = previous_event.as_text().trim_suffix(" (Physical)")
	button.find_child("InputLabel").text = event_string
	if previous_button != null:
		previous_button.find_child("InputLabel").text = previous_event_string
		previous_button = null
		previous_event = null

func _on_reset_button_pressed() -> void:
	_create_action_list()

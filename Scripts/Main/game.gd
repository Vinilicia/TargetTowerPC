class_name Game

extends Node2D

@export var current_level : Node

@onready var level_transition : CanvasLayer = $Level_Transition

func change_level(next_level : String, spaw_position : Vector2):
	var new_level = load(next_level).instantiate()
	level_transition.dissolve_effect()
	call_deferred("remove_child", current_level)
	call_deferred("add_child", new_level)
	level_transition.reappear_effect()
	get_node("Player").global_position = spaw_position
	current_level = new_level

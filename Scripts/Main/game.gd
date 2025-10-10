class_name Game

extends Node2D

@export var current_level : Node

func change_level(next_level : String):
	var new_level = load(next_level).instantiate()
	call_deferred("remove_child", current_level)
	call_deferred("add_child", new_level)
	current_level = new_level

class_name Game

extends Node2D

@export var current_level : Node

@export var blackout_rect : ColorRect

var tween : Tween

func change_level(next_level : String, spawn_position : Vector2):
	if blackout_rect:
		tween = get_tree().create_tween()
		tween.tween_property(blackout_rect, "modulate", Color(1, 1, 1, 1), 0.2)
		tween.finished.connect(spawn_new_level.bind(next_level, spawn_position))

func spawn_new_level(next_level : String, spawn_position : Vector2) -> void:
	var new_level = load(next_level).instantiate()
	call_deferred("remove_child", current_level)
	call_deferred("add_child", new_level)
	get_node("Player").global_position = spawn_position
	current_level = new_level
	await get_tree().create_timer(0.2).timeout
	if blackout_rect:
		tween.stop()
		tween = get_tree().create_tween()
		tween.tween_property(blackout_rect, "modulate", Color(1, 1, 1, 0), 0.5)

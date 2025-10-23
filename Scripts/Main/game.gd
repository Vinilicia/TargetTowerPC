class_name Game

extends Node2D

@export var current_level : Room

@export var blackout_rect : ColorRect

var tween : Tween
var enemy_alive_persistence : Array[bool] = []
var last_room_name : String = ""

func change_level(next_level : String, spawn_position : Vector2):
	if blackout_rect:
		tween = get_tree().create_tween()
		tween.tween_property(blackout_rect, "modulate", Color(1, 1, 1, 1), 0.2)
		await tween.finished
	var old_level : Room = current_level
	handle_next_level(next_level, spawn_position)
	handle_last_level(old_level)
	await get_tree().create_timer(0.2).timeout
	if blackout_rect:
		tween.stop()
		tween = get_tree().create_tween()
		tween.tween_property(blackout_rect, "modulate", Color(1, 1, 1, 0), 0.5)

func handle_last_level(old_level : Room) -> void:
	enemy_alive_persistence = old_level.get_enemy_alive_array()
	print(enemy_alive_persistence)
	last_room_name = old_level.name
	call_deferred("remove_child", old_level)

func handle_next_level(next_level : String, spawn_position : Vector2) -> void:
	var new_level : Room = load(next_level).instantiate()
	call_deferred("add_child", new_level)
	if new_level.name == last_room_name:
		new_level.call_deferred("kill_enemies", enemy_alive_persistence)
	get_node("Player").global_position = spawn_position
	current_level = new_level

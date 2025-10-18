extends Area2D

@export var next_level : String
@export var spaw_position : Vector2

func _on_body_entered(_body: Node2D) -> void:
	var game : Game = get_parent().get_parent()
	game.change_level(next_level, spaw_position)

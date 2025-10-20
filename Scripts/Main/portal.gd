extends Area2D

@export var next_level : String
@export var spaw_position : Vector2

func _on_body_entered(_body: Node2D) -> void:
	var game : Game = get_tree().get_first_node_in_group("Game")
	game.change_level(next_level, spaw_position)

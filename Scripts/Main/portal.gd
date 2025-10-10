extends Area2D

@export var next_level : String

func _on_body_entered(body: Node2D) -> void:
	var game : Game = get_parent().get_parent()
	game.change_level(next_level)

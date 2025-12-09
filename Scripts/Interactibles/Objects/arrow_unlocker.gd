extends Area2D

@export var arrow_index : int 

func _on_player_entered(player: Node2D) -> void:
	player.unlock_arrow(arrow_index)

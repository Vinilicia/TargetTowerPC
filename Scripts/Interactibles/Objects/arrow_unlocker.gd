extends Area2D

@export var arrow_index : int 

#func _ready() -> void:
	#if SaveManager.save_file_data.get_available_arrow(arrow_index):
		#queue_free()

func _on_player_entered(player: Node2D) -> void:
	(player as Player).unlock_arrow(arrow_index)
	queue_free()

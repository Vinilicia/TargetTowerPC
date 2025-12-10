extends Area2D

@export var upgrade_index : int 

func _ready() -> void:
	if SaveManager.save_file_data.get_health_upgrade(upgrade_index):
		queue_free()
		
func _on_player_entered(player: Node2D) -> void:
	(player as Player).increase_total_health(upgrade_index)
	SaveManager.save_file_data.set_health_upgrade(upgrade_index)
	queue_free()

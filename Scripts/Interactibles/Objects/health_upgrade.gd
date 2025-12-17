extends Area2D

@export var upgrade_index : int 

func _ready() -> void:
	if SaveManager.save_file_data.get_health_upgrade(upgrade_index):
		queue_free()
		
func _on_player_entered(player: Node2D) -> void:
	AudioManager.play_song("PickUp")
	(player as Player).increase_total_health()
	SaveManager.save_file_data.set_health_upgrade(upgrade_index)
	queue_free()

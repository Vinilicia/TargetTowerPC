extends TileMapLayer

var can_down = false
	
func _on_player_entered(body: Node2D) -> void:
	can_down = true

func _on_player_exited(body: Node2D) -> void:
	can_down = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		if Input.is_action_pressed("down") and can_down:
			collision_enabled = false
			await get_tree().create_timer(0.1).timeout
			collision_enabled = true

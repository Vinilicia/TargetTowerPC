extends Arrow

@onready var plat_spawner = preload("res://Scenes/Interactibles/Objects/Platform.tscn")

var can_spawn : bool = true 

func _handle_collision(collision: KinematicCollision2D) -> void:
	if has_collided:
		return

	var body = collision.get_collider()
	var normal = collision.get_normal()
	var contact_point = collision.get_position()

	if not has_bounced and not body.is_in_group("Attachables"):
		bounce()
		return

	# cria plataforma
	if body.is_in_group("Attachables"):
		var platform = plat_spawner.instantiate()
		var local_pos = body.to_local(contact_point)
		body.add_child(platform)
		platform.position = local_pos
		
		if has_bounced or (flying_direction.y > 0) :
			platform.set_spawning_time(0.1)

		if abs(normal.y) > abs(normal.x):
			if normal.y < 0:
				platform.activate(0, false) # chão
			else:
				platform.activate(0, true)  # teto
		else:
			if normal.x > 0:
				platform.activate(-1, false) # parede direita
			else:
				platform.activate(1, false)  # parede esquerda

		has_collided = true
	queue_free()


func _on_hitbox_hit(_target: Node2D) -> void:
	velocity = Vector2.ZERO
	bounce()

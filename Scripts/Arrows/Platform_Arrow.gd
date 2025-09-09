extends Arrow

@onready var plat_spawner = preload("res://Scenes/Interactibles/Objects/Platform.tscn")
@export var raycast: RayCast2D

var can_spawn : bool = true 

func _on_body_entered(body: Node2D) -> void:
	if has_collided:
		return
	has_collided = true
	get_frozen()
	if can_spawn and body.is_in_group("Attachables"):
		print("A")
		can_spawn = false

		if raycast.is_colliding():
			var contact_point = raycast.get_collision_point()
			var normal = raycast.get_collision_normal().normalized()

			var platform = plat_spawner.instantiate()
			body.call_deferred("add_child", platform)
			platform.global_position = contact_point - body.global_position

			if abs(normal.y) > abs(normal.x):
				
				if normal.y < 0:
					platform.call_deferred("activate", 0, false)
				else:
					platform.call_deferred("activate", 0, true)
			else:
				if normal.x > 0:
					platform.call_deferred("activate", -1, false)
				else:
					platform.call_deferred("activate", 1, false)
			
		spawn_joint(body)
		despawn()
	else:
		bounce()

func _on_hitbox_hit(target: Node2D) -> void:
	_on_body_entered(target)

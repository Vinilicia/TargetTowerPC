extends Arrow

@onready var plat_spawner = preload("res://Scenes/Interactibles/Objects/Platform.tscn")

var can_spawn : bool = true 

func _on_body_entered(body) -> void:
	get_frozen()
	if can_spawn:
		can_spawn = false
		var platform = plat_spawner.instantiate()
		call_deferred("add_child", platform)
		platform.position = Vector2(5, -0.5)
		platform.call_deferred("activate", facing_direction, downward)
	if body.is_in_group("Attachables"):
		spawn_joint(body)
		despawn()
	if !body.is_in_group("Attachables"):
		bounce()

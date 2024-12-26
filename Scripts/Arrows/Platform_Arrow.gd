extends Arrow

@onready var plat_spawner = $Plat_Spawner

var can_spawn : bool = true 

func _on_body_entered(body) -> void:
	get_frozen()
	if can_spawn:
		can_spawn = false
		var platform = load("res://Scenes/Interactibles/Objects/Platform.tscn").instantiate()
		platform.position = plat_spawner.position
		if !downward:
			platform.change_to("horizontal")
		else:
			platform.change_to("vertical")
		call_deferred("add_child", platform)
	if body.is_in_group("Attachables"):
		spawn_joint(body)
		despawn()
	if !body.is_in_group("Attachables"):
		bounce()

func set_direction(dir : int) -> void:
	if direction != dir:
		$Collision.position.x *= -1
		$Plat_Spawner.position.x *= -1
		flip_sprite()
		direction = dir

func flip_children() -> void:
	super.flip_children()
	var plat_spawner = $Plat_Spawner
	plat_spawner.position = Vector2(0.5, -4.5)

extends SlimeBlob

@export var player_detector: Area2D
@export var fire_spawn: PackedScene

var disabled := true
var hit_ground_last_time := false

func _physics_process(delta: float) -> void:
	
	if disabled:
		set_collision_mask_value(3, false)
		super._physics_process(delta)
		return

	set_collision_mask_value(3, true)
	set_collision_mask_value(5, true)

	velocity.y += gravity * delta
	var collision = move_and_collide(velocity * delta, true)

	if collision:
		var normal = collision.get_normal()
		if normal.y < -0.7: 
			explode(collision.get_position())
		else:
			move_and_collide(velocity * delta)
	else:
		move_and_collide(velocity * delta)

func explode(pos : Vector2) -> void:
	var fire_area: Area2D = fire_spawn.instantiate()
	get_parent().call_deferred("add_child", fire_area)
	fire_area.set_deferred("width", 5)
	fire_area.set_deferred("position", pos + Vector2(0, -12))
	queue_free()

func _on_player_detector_body_entered(_body: Node2D) -> void:
	if velocity.y > 0:
		disabled = false

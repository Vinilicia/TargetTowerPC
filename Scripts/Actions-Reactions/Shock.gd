extends Area2D

var parent_node : Node2D
var coll : CollisionShape2D

func set_collision(collision_shape : Shape2D, collision_scale : float) -> void:
	coll = $Coll
	coll.set_deferred("shape", collision_shape)
	coll.set_deferred("scale", Vector2(1, 1.5) * collision_scale)

func is_shockable(body : Node2D) -> bool:
	if body.has_node("Reactions") and body != parent_node:
		return body.reactions.is_shockable
	else:
		return false

func handle_start_shock(body_or_area : Node2D) -> void:
	if is_shockable(body_or_area):
		body_or_area.reactions.get_hit_by_shock()
	parent_node.start_decharging()

func handle_stop_shock(body_or_area : Node2D) -> void:
	if is_shockable(body_or_area):
		if body_or_area.reactions.in_shock:
			body_or_area.reactions.exit_shock()

func _on_area_or_body_entered(body_or_area : Node2D) -> void:
	handle_start_shock(body_or_area)

func _on_area_or_body_exited(body_or_area : Node2D) -> void:
	handle_stop_shock(body_or_area)

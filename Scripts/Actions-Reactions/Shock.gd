extends Area2D

var parent_node : Node2D
var coll : CollisionShape2D

func set_collision(collision_shape : Shape2D, collision_scale : float) -> void:
	coll = $Coll
	print(collision_scale)
	coll.set_deferred("shape", collision_shape)
	coll.set_deferred("scale", Vector2(1, 1.5) * collision_scale)

func is_shockable(body : Node2D) -> bool:
	if body.has_node("Reactions") and body != parent_node:
		return body.reactions.is_shockable
	else:
		return false

func _on_area_or_body_entered(body_or_area : Node2D) -> void:
	print(coll.get_scale())

func _on_area_or_body_exited(body_or_area : Node2D) -> void:
	pass

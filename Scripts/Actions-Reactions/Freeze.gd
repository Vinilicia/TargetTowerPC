extends Area2D

var coll : CollisionShape2D
var parent_node : Node2D

func set_collision(collision_shape : Shape2D, collision_scale : float) -> void:
	coll = $Coll
	coll.call_deferred("set_shape", collision_shape)
	coll.call_deferred("set_scale", Vector2(1, 1) * collision_scale)

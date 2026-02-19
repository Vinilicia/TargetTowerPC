extends Arrow

var this_parent : Node2D

func setup_hitbox(parent : Node2D) -> void:
	super.setup_hitbox(parent)
	this_parent = parent

func _handle_collision(collision: KinematicCollision2D) -> void:
	var normal = collision.get_normal()
	var contact_point = collision.get_position()
	this_parent.global_position = contact_point + normal * 8
	queue_free()

func _on_hitbox_hit(target: Node2D) -> void:
	velocity = Vector2.ZERO
	var target_position = target.global_position
	target.global_position = get_parent().global_position
	this_parent.global_position = target_position
	queue_free()

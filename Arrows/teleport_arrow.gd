extends Arrow

var this_parent : Node2D

@export var teleport_duration : float = 0.3

func setup_hitbox(parent : Node2D) -> void:
	super.setup_hitbox(parent)
	this_parent = parent

func _handle_collision(collision: KinematicCollision2D) -> void:
	var normal = collision.get_normal()
	var contact_point = collision.get_position()
	move_parent(contact_point + normal * 8)
	queue_free()

func move_parent(pos : Vector2) -> void:
	if this_parent is Player:
		this_parent.move_smoothly(pos, teleport_duration)

func move_target(target : Node2D, pos : Vector2) -> void:
	target.global_position = pos
	target.visible = false
	target.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	get_tree().create_timer(teleport_duration).timeout.connect(func():
		target.visible = true
		target.set_deferred("process_mode", Node.PROCESS_MODE_INHERIT)
		)

func _on_hitbox_hit(target: Node2D) -> void:
	velocity = Vector2.ZERO
	var target_position = target.global_position
	move_target(target, get_parent().global_position)
	move_parent(target_position)
	queue_free()

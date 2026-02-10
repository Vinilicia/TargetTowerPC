extends CharacterBody2D

func _physics_process(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0.0
	move_and_slide()

func burn_out() -> void:
	queue_free()

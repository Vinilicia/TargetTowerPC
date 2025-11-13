extends Node2D

@export var speed : float = 200.0
@export var lifespan : float = 10.0

var velocity : Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if !velocity.is_zero_approx():
		position += velocity * delta

func fly(direction : Vector2) -> void:
	velocity = speed * direction
	get_tree().create_timer(lifespan).timeout.connect(
		func():
			queue_free()
	)
	

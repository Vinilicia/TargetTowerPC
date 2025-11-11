extends RigidBody2D

@export var min_delay : float
@export var max_delay : float

@export var anim_timer : Timer
@export var sprite : AnimatedSprite2D

func _ready() -> void:
	anim_timer.start(randf_range(min_delay, max_delay))

func _on_anim_timer_timeout() -> void:
	sprite.play("Shine")
	anim_timer.start(randf_range(min_delay, max_delay))

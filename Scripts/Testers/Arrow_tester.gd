extends AnimatableBody2D

@onready var current_position : Vector2 = global_position
@onready var move_duration : float = 0.01
@onready var initial_position : Vector2 = global_position

var final_position : Vector2 = Vector2.RIGHT * 40 + initial_position


func _physics_process(delta):
	position = position.lerp(current_position, 0.5)

func test_movement() -> void:
	var block_tween = create_tween()
	block_tween.tween_property(self, "current_position", final_position, move_duration)

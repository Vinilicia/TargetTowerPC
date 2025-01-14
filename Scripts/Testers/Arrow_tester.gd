extends AnimatableBody2D

@onready var move_duration : float = 0.1
var current_position : Vector2
var initial_position : Vector2

var final_position : Vector2

func _ready() -> void:
	current_position = global_position
	initial_position = global_position

func _physics_process(_delta):
	position = position.lerp(current_position, 0.5)
	

func activate() -> void:
	final_position = current_position + (Vector2.RIGHT * 40)
	var block_tween = create_tween()
	block_tween.tween_property(self, "current_position", final_position, move_duration)

func deactivate() -> void:
	final_position = current_position - (40 * Vector2.RIGHT)
	var block_tween = create_tween()
	block_tween.tween_property(self, "current_position", final_position, move_duration)

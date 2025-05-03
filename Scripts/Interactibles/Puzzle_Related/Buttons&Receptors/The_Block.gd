extends Node2D

@export var horizontal : bool = true
@export var move_duration : float = 0.3
@export var moving_distance : int = 45
@export_enum("Activated", "Deactivated") var start_state : String
@onready var block = $ActualBlock as AnimatableBody2D
@onready var sprite = $BlockSprite as AnimatedSprite2D

func _ready() -> void:
	if start_state == "Activated":
		sprite.play("Activate")
	else:
		was_deactivated()

func was_activated():
	var tween = create_tween()
	sprite.play("Activate")
	var final_pos = Vector2(0, 0)
	tween.tween_property(block, "position", final_pos, move_duration).set_ease(Tween.EASE_IN)

func was_deactivated():
	var tween = create_tween()
	sprite.play("Deactivate")
	var final_pos = Vector2(-moving_distance, 0)
	tween.tween_property(block, "position", final_pos, move_duration).set_ease(Tween.EASE_OUT)


func _on_red_target_activated() -> void:
	pass # Replace with function body.

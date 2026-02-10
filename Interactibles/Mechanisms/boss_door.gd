extends Node2D
class_name BossDoor

@export var sprite : AnimatedSprite2D
@export var door_body : AnimatableBody2D

func close() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(door_body, "position", Vector2(0, 0), 0.16)
	sprite.play("Close")

func open() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(door_body, "position", Vector2(0, -32), 0.21)
	sprite.play("Open")

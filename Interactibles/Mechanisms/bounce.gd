extends Node2D

@export var static_body : StaticBody2D
@export var area : Area2D

@export var bounce_force : float = -1000.0

func _on_bounce_area_body_entered(body: Node2D) -> void:
	var v_component : VelocityComponent = body.find_child("VelocityComponent")if v_component:
		v_component.set_knockback_velocity(Vector2.DOWN.rotated(rotation) * bounce_force)

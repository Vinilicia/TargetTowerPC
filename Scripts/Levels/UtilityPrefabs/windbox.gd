extends Node2D

@export var wind_direction : Vector2
@export var wind_force : float

func _on_wind_body_entered(body: Node2D) -> void:
	if body is Player:
		body.v_component.add_wind_velocity(wind_direction * wind_force)

func _on_wind_body_exited(body: Node2D) -> void:
	if body is Player:
		body.v_component.add_wind_velocity(wind_direction * -wind_force)

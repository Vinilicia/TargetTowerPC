extends Node2D

@export var belt_direction : Vector2
@export var belt_speed : float

var bodies_inside : Array[Node2D] = []

func reverse_direction() -> void:
	belt_direction *= -1
	for body in bodies_inside:
		var v_component = body.find_child("VelocityComponent")
		v_component.add_ground_velocity(belt_direction * belt_speed * 2)

func _on_belt_body_entered(body: Node2D) -> void:
	var v_component : VelocityComponent = body.find_child("VelocityComponent")
	if v_component:
		bodies_inside.append(body)
		v_component.add_ground_velocity(belt_direction * belt_speed)

func _on_belt_body_exited(body: Node2D) -> void:
	var v_component : VelocityComponent = body.find_child("VelocityComponent")
	if v_component:
		bodies_inside.erase(body)
		v_component.add_ground_velocity(belt_direction * -belt_speed)

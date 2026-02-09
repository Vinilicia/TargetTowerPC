@tool
extends Node2D

@export var area : Area2D

@export var wind_direction : Vector2
@export var wind_force : float
@export_group("Editor")

@export var size : Vector2i = Vector2i(2, 2):
	set(new_size):
		new_size = new_size.clampi(2, 1000)
		area.scale.x = new_size.x * 16
		area.position.x = new_size.x * 8
		area.scale.y = new_size.y * 16
		area.position.y = new_size.y * 8
		size = new_size

var bodies_inside: Array[Node2D] = []

func _on_wind_body_entered(body: Node2D) -> void:
	var v_component : VelocityComponent = body.find_child("VelocityComponent")
	if v_component:
		if !bodies_inside.has(body):
			bodies_inside.append(body)
			v_component.add_wind_velocity(wind_direction * wind_force)
		else:
			push_error("BODY ENTERED WIND BOX WHEN IT WAS ALREADY IN!!!")

func _on_wind_body_exited(body: Node2D) -> void:
	var v_component : VelocityComponent = body.find_child("VelocityComponent")
	if v_component:
		if bodies_inside.has(body):
			bodies_inside.erase(body)
			v_component.add_wind_velocity(wind_direction * -wind_force)
		else:
			push_error("BODY EXITED WIND AREA WITHOUT ENTERING!!!")

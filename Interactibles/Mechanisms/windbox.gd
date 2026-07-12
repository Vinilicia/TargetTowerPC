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

var bodies_inside: Array[CharacterBody2D] = []

func _physics_process(_delta: float) -> void:
	if !Engine.is_editor_hint():
		apply_wind()

func apply_wind() -> void:
	for body in bodies_inside:
		var v_component : VelocityComponent = body.find_child("VelocityComponent")
		if v_component:
			if body.is_on_floor():
				v_component.set_wind_velocity(Vector2.ZERO)
			else:
				v_component.set_wind_velocity(wind_direction * wind_force)

func _on_wind_body_entered(body: Node2D) -> void:
	assert(body is CharacterBody2D, "Corpo entrou em Windbox mas não era CharacterBody: " + body.name)
	if !bodies_inside.has(body as CharacterBody2D):
		bodies_inside.append(body as CharacterBody2D)
	else:
		push_error("BODY ENTERED WIND AREA TWICE!!! " + name + " -> " + body.name)

func _on_wind_body_exited(body: Node2D) -> void:
	assert(body is CharacterBody2D, "Corpo saiu de Windbox mas não era CharacterBody: " + body.name)
	if bodies_inside.has(body):
		bodies_inside.erase(body)
		var v_component : VelocityComponent = body.find_child("VelocityComponent")
		if v_component:
			v_component.set_wind_velocity(Vector2.ZERO)
	else:
		push_error("BODY EXITED WIND AREA WITHOUT ENTERING!!! " + name + " -> " + body.name)

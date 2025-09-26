@tool
extends Node2D

@onready var area : Area2D = $Belt
@onready var body : StaticBody2D = $StaticBody
@onready var tilemap : TileMapLayer = $Tilemap

@export var belt_direction : Vector2
@export var belt_speed : float
@export_group("Editor")
@export var length : int = 0:
	set(new_length):
		#new_length = clampi(new_length, 3, 1000)
		area.scale.x = new_length * 16
		area.position.x = new_length * 8
		body.scale.x = new_length * 16
		body.position.x = new_length * 8
		tilemap.clear()
		if new_length >= 3:
			tilemap.set_cell(Vector2i(0, -1), 2, Vector2i(0, 0), 0)
			for i in range(new_length - 2):
				tilemap.set_cell(Vector2i(i + 1, -1), 2, Vector2i(0, 1), 0)
			tilemap.set_cell(Vector2i(new_length - 1, -1), 2, Vector2i(0, 2), 0)
		length = new_length


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

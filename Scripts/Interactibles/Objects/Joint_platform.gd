extends Node2D

@export_enum("Wall", "Ceiling") var location : int
@export_enum("Left", "Right") var fall_direction : int

@onready var platform := $Platform as RigidBody2D

func _ready():
	pass
	

func start_gravity_switch() -> void:
	while true:
		await get_tree().create_timer(5).timeout
		platform.gravity_scale *= -1
		print("opa")

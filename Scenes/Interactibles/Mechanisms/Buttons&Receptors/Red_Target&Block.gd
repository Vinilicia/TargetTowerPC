extends Node2D

@export var target : Area2D
@export var block : Node2D

func _ready() -> void:
	if block.get_start_state() == "Activated":
		target.activated.connect(block.deactivate)
	elif block.get_start_state() == "Deactivated":
		target.activated.connect(block.activate)

extends Node2D
class_name Mechanism

@export var active_on_start : bool = false

var active : bool

signal activated
signal deactivated

func _ready() -> void:
	if active_on_start:
		activate()

func activate() -> void:
	active = true
	activated.emit()

func deactivate() -> void:
	active = false
	deactivated.emit()

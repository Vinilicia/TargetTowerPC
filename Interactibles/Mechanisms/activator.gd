extends Node2D
class_name Activator

@export var mechanism : Mechanism
@export var reversed : bool = false

signal on
signal off

func _ready() -> void:
	assert(mechanism != null, "Mechanism var empty on Activator: " + name)
	if !reversed:
		on.connect(mechanism.activate)
		off.connect(mechanism.deactivate)
		mechanism.deactivated.connect(turn_off)
	else:
		off.connect(mechanism.activate)
		on.connect(mechanism.deactivate)
		mechanism.activated.connect(turn_on)
		turn_on()

func activate(_variable : Variant = null) -> void:
	on.emit()
	turn_on()

func deactivate(_variable : Variant = null) -> void:
	off.emit()
	turn_off()

func turn_on() -> void:
	assert(false, "Activator must override 'turn on' function!! On " + name)

func turn_off() -> void:
	assert(false, "Activator must override 'turn off' function!! On " + name)

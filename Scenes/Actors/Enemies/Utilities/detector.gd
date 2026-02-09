extends RayCast2D
class_name Detector

@export var constant : bool = false

var is_colliding_now : bool = false

signal colliding
signal not_colliding

func _physics_process(_delta: float) -> void:
	if is_colliding():
		if constant or !is_colliding_now:
			is_colliding_now = true
			colliding.emit()
	else:
		if constant or is_colliding_now:
			is_colliding_now = false
			not_colliding.emit()

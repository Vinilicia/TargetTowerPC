extends Area2D

@onready var coll = $Coll

var pressed = false
signal Is_Pressed

func _on_body_entered(body):
	pressed = true
	emit_signal("Is_Pressed")
	coll.set_deferred("disabled", true)

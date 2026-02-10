extends Area2D

var pressed = false

signal Is_Pressed
signal Is_Unpressed

func _on_body_entered(body):
	pressed = true
	emit_signal("Is_Pressed")

func _on_body_exited(body):
	if pressed: 
		emit_signal("Is_Unpressed")
		pressed = false

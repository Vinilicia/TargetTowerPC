extends Area2D


var pressed = false
var can_be_pressed = true
signal Is_Pressed


func _on_body_entered(body):
	if can_be_pressed:
		emit_signal("Is_Pressed")
		pressed = true
		can_be_pressed = false


func _on_body_exited(body):
	if pressed: 
		pressed = false
		can_be_pressed = true

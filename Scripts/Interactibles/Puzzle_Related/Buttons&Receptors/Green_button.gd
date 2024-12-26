extends Area2D



@onready var anim = $AnimationPlayer


var pressed = false
var can_be_pressed = true
signal Is_Pressed
signal Is_Unpressed


func _on_body_entered(body):
	if can_be_pressed:
		emit_signal("Is_Pressed")
		pressed = true
		can_be_pressed = false
		anim.play("Being_Pressed")
		await anim.animation_finished
		anim.play("Pressed")


func _on_body_exited(body):
	if pressed: 
		emit_signal("Is_Unpressed")
		pressed = false
		can_be_pressed = true
		anim.play("Being_Unpressed")
		await anim.animation_finished
		anim.play("Idle")

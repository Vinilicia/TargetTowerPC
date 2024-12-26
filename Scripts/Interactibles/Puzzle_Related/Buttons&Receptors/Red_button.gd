extends Area2D


@onready var anim = $AnimationPlayer


var pressed = false
var can_be_pressed = true
signal Is_Pressed

func _process(delta):
	if pressed:
		emit_signal("Is_Pressed")
		can_be_pressed = false
		pressed = false
		anim.play("Being_Pressed")
		await anim.animation_finished
		anim.play("Pressed")
		


func _on_body_entered(body):
	if can_be_pressed:
		pressed = true

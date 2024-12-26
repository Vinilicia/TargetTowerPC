extends Area2D


@onready var timer = $Timer
@onready var anim = $AnimationPlayer

@export var pressed_time : float = 5

var pressed = false
var can_be_pressed = true
signal Is_Pressed
signal Is_Unpressed


func _on_body_entered(body):
	if can_be_pressed:
		emit_signal("Is_Pressed")
		pressed = true
		can_be_pressed = false
		timer.start(pressed_time)
		anim.play("Being_Pressed")
		await anim.animation_finished
		anim.play("Pressed")




func _on_timer_timeout():
	if pressed: 
		emit_signal("Is_Unpressed")
		pressed = false
		can_be_pressed = true
		anim.play("Being_Unpressed")
		await anim.animation_finished
		anim.play("Idle")

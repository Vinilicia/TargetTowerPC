extends Area2D

@onready var coll = $Collision as CollisionShape2D
@export var Pressed_time : float = 5

var pressed = false
var timer = Timer

signal Is_Pressed
signal Is_Unpressed

func _on_body_entered(body):
	pressed = true
	emit_signal("Is_Pressed")
	coll.set_deferred("disabled", true)
	create_timer()
	anim.play("Not Shining")

func create_timer() -> void:
	timer = Timer.new()
	timer.one_shot = true
	timer.autostart = false
	timer.timeout.connect(timer_timeout)
	add_child(timer)
	timer.start(Pressed_time)

func timer_timeout():
	if pressed: 
		emit_signal("Is_Unpressed")
		pressed = false
		coll.set_deferred("disabled", false)

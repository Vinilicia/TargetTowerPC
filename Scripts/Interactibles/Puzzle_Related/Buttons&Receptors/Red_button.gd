extends Area2D

@onready var coll = $Coll as CollisionShape2D
@onready var anim = $RedTargetSprite as AnimatedSprite2D

var pressed = false
signal Is_Pressed

func _on_body_entered(_body_or_area):
	pressed = true
	emit_signal("Is_Pressed")
	coll.set_deferred("disabled", true)
	anim.play("Not Shining")

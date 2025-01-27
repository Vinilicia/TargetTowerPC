extends Node2D

@onready var plataform = $Platform as AnimatableBody2D

@export var wait_duration: float
@export var move_speed: float
@export var distance: int
@export_enum("Horizontal", "Vertical") var direction: int

var follow := Vector2.ZERO
var platform_center := 8

func _ready():
	move_platform()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	plataform.position = plataform.position.lerp(follow, 0.5)

func move_platform():
	var move_direction = Vector2.RIGHT * distance if direction == 0 else Vector2.UP * distance
	var duration = move_direction.length() / float(move_speed * platform_center)
	
	var platform_tween = create_tween().set_loops().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	platform_tween.tween_property(self, "follow", move_direction, duration).set_delay(wait_duration)
	platform_tween.tween_property(self, "follow", Vector2.ZERO, duration).set_delay(wait_duration)

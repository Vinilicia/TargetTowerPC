extends Area2D

@export var Intensity : float
@export var Instant : bool 
@export var Extinguishes : bool

var duration : float
var collision_shape : CollisionShape2D
var collision_scale : float

var timer : Timer

func _ready() -> void:
	timer = $Timer
	if Extinguishes:
		start_timer()

func start_timer() -> void:
	timer.start(duration)

func _on_timer_timeout() -> void:
	extinguish()

func extinguish() -> void:
	queue_free()

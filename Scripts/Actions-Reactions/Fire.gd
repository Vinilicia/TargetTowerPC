extends Area2D

@export var Intensity : float
@export var Instant : bool 

var duration : float
var parent_node : Node2D

var timer : Timer
var coll : CollisionShape2D

signal extinguished


func set_collision(collision_shape : Shape2D, collision_scale : float) -> void:
	coll = $Coll
	coll.call_deferred("set_shape", collision_shape)
	coll.call_deferred("set_scale", Vector2(1, 1) * collision_scale)

func connect_extinguish_signal(function : Callable) -> void:
	extinguished.connect(function)

func _ready() -> void:
	if duration != 0:
		start_timer()

func start_timer() -> void:
	if timer != null:
		timer.free()
	timer = Timer.new()
	timer.one_shot = true
	timer.autostart = false
	add_child(timer)
	timer.start(duration)
	await timer.timeout
	extinguish()

func _on_timer_timeout() -> void:
	extinguish()

func extinguish() -> void:
	extinguished.emit()
	queue_free()

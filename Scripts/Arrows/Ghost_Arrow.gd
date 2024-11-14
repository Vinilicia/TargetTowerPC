extends Arrow

@export var Phaze_Reset_Time : float 

var phazed_body_count : int = 0
var gone_through : bool = false

var phazing_timer : Timer

func _on_body_entered(body : Node2D) -> void:
	if gone_through:
		super._on_body_entered(body)
	else:
		stop_phazing_timer()

func _on_body_exited(body: Node2D) -> void:
	create_phazing_timer()

func create_phazing_timer() -> void:
	phazing_timer = Timer.new()
	phazing_timer.autostart = false
	phazing_timer.timeout.connect(enable_collision)
	phazing_timer.one_shot = true
	add_child(phazing_timer)
	phazing_timer.start(Phaze_Reset_Time)

func stop_phazing_timer() -> void:
	if phazing_timer != null:
		phazing_timer.stop()
		phazing_timer.queue_free()

func enable_collision() -> void:
	gone_through = true

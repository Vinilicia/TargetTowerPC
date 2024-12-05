extends Reaction

var auto_defrosts : bool
var defrosting_time : float

var frozen : bool = false

var defrosting_timer : Timer

func react(body_or_area : CollisionObject2D) -> void:
	if body_or_area.get_collision_layer_value(10):
		get_hit_by_ice()

func initialize(new_parent: Node2D, freeze_properties: Dictionary) -> void:
	parent = new_parent
	enter_func = enter_ice
	exit_func = exit_ice
	
	auto_defrosts = freeze_properties.get("auto_defrosts")
	defrosting_time = freeze_properties.get("defrosting_time")


func get_hit_by_ice() -> void:
	enter_func.call()

func enter_ice() -> void:
	frozen = true
	enter_func = update_ice
	
	parent.enter_func.call()
	if auto_defrosts:
		start_defrosting_timer()

func update_ice() -> void:
	parent.update_ice_func.call()

func exit_ice() -> void:
	stop_defrosting_timer()
	enter_func = enter_ice
	parent.exit_func.call()

func start_defrosting_timer() -> void:
	defrosting_timer = Timer.new()
	defrosting_timer.autostart = false
	defrosting_timer.timeout.connect(exit_ice)
	defrosting_timer.one_shot = true
	parent.add_child(defrosting_timer)
	defrosting_timer.start(defrosting_time)

func stop_defrosting_timer() -> void:
	if defrosting_timer != null:
		defrosting_timer.stop()
		defrosting_timer.queue_free()

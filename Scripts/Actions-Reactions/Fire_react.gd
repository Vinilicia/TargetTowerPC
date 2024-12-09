extends Reaction

var fire_resistance : int
var time_to_fire : float
var burn_type : String
var time_on_fire : float
var emanates_heat : bool
var fire_intensity : float
var fire_scale : float

var on_fire : bool = false
var still_heating : bool = false

var heating_timer : Timer
var burning_timer : Timer
var fire : Area2D

func initialize(new_parent: Node2D, fire_properties: Dictionary) -> void:
	
	parent = new_parent
	
	take_func = enter_fire
	stop_func = exit_fire
	
	fire_resistance = fire_properties.get("fire_resistance")
	time_to_fire = fire_properties.get("time_to_fire")
	burn_type = fire_properties.get("burn_type")
	time_on_fire = fire_properties.get("time_on_fire")
	emanates_heat = fire_properties.get("emanates_heat")
	fire_intensity = fire_properties.get("fire_intensity")
	fire_scale = fire_properties.get("fire_scale")

func react(body_or_area : CollisionObject2D) -> void:
	if body_or_area.get_collision_layer_value(9):
		get_hit_by_fire(body_or_area.Intensity, body_or_area.Instant)

func get_hit_by_fire(intensity : int, instant : bool) -> void:
	if instant or on_fire:
		take_func.call()
	else:
		var heating_time : float = time_to_fire / float(max(1, intensity - fire_resistance))
		start_heating_timer(heating_time)

func create_fire() -> void:
	var coll_node : CollisionShape2D = parent.coll
	var coll_shape : Shape2D = coll_node.get_shape()
	fire = load("res://Scenes/Actions-Reactions/Fire.tscn").instantiate()
	fire.set_collision(coll_shape, fire_scale)
	fire.parent_node = parent
	fire.duration = time_on_fire
	fire.connect_extinguish_signal(stop_func)
	parent.call_deferred("add_child", fire)

func start_heating_timer(time_to_fire : float) -> void:
	if heating_timer == null:
		still_heating = true
		heating_timer = Timer.new()
		heating_timer.autostart = false
		heating_timer.one_shot = true
		heating_timer.timeout.connect(take_func)
		parent.add_child(heating_timer)
		heating_timer.start(time_to_fire)

func stop_heating_timer() -> void:
	if heating_timer != null:
		heating_timer.stop()
		heating_timer.call_deferred("free")

#func start_burning_timer() -> void:
	#still_heating = true
	#burning_timer = Timer.new()
	#burning_timer.autostart = false
	#burning_timer.one_shot = true
	#burning_timer.timeout.connect(stop_func)
	#parent.add_child(burning_timer)
	#burning_timer.start(time_on_fire)
#
#func restart_burning_timer() -> void:
	#stop_burning_timer()
	#start_burning_timer()
#
#func stop_burning_timer() -> void:
	#if burning_timer != null:
		#burning_timer.stop()
		#burning_timer.call_deferred("free")

func enter_fire() -> void:
	taken.emit()
	
	on_fire = true
	if emanates_heat:
		create_fire()
	
	take_func = update_fire

func update_fire() -> void:
	if burn_type == "Cool_off":
		fire.start_timer()

func exit_fire() -> void:
	stopped.emit()
	on_fire = false
	take_func = enter_fire

extends Node

@onready var parent : Node2D = get_parent()

@export_category("General")

@export var is_pushable : bool
@export var is_freezable : bool
@export var is_heatable : bool
@export var is_dryable : bool
@export var is_electrifiable : bool

############################################ GENERAL ############################################

func _ready():
	if is_freezable:
		freeze_ready()
	if is_heatable:
		#ready_heatable()
		pass

func _physics_process(delta):
	if is_pushable:
		pushable_handle_physics(delta)
	if is_heatable:
		heatable_handle_physics()


############################################# PUSHABLE #############################################

@export_category("Pushable")
@export var Weight : float

var knockback_vector := Vector2.ZERO
var dir = 0

func be_pushed(direction : int, push_force : Vector2) -> void:
	dir = direction
	knockback_vector = Vector2(0,0)
	if push_force.x - Weight > 0:
		knockback_vector.x = push_force.x - Weight
	if push_force.y - Weight > 0:
		knockback_vector.y = push_force.y - Weight
	knockback_vector *= dir

func pushable_handle_physics(delta):
	if knockback_vector.x != 0:
		parent.velocity += knockback_vector
		knockback_vector = Vector2.ZERO
	if parent.is_on_floor():
		parent.velocity.x = move_toward(parent.velocity.x, 0, parent.velocity.x/7 * dir)
	else:
		parent.velocity.x = move_toward(parent.velocity.x, 0, parent.velocity.x/10 * dir)

############################################ FLAMMABLE ############################################

@export_category("Heatable")

@export var Heat_Resistance : float
@export var Fire_Resistance : float

@export var Temp_To_Flamed : float

#valor base da intensidade do calor e sua range(* 10)
@export var Emanate_Heat : bool
@export var Base_Heat : float
@export_range(1, 10) var Fire_Range : int

#queimar
@export_enum("Destroy", "Cool_Off") var Burn_Type : String
@export var Burn_Time : float
@export var Max_Temp_Supported : int

var temperature : int = 0
var time_per_tick : float = 0
var was_hit : bool = false

#estados
var on_flame : bool = false
var still_heating : bool = false
var in_contact_with_fire : bool = false

#nós que podem ser criados
var heat_area : Area2D
var burning_timer : Timer
var heating_timer : Timer

var loop_number : int

func start_heating(heat : float, max_heat_value : float, instant : bool = false) -> void:
	var temp_to_gain : float = heat - Fire_Resistance
	loop_number = max(max_heat_value - temperature, 0)
	if loop_number != 0:
		if instant:
			temperature += temp_to_gain
		else:
			time_per_tick = Heat_Resistance / temp_to_gain
			create_heating_loop(time_per_tick)
		was_hit = true
	if instant:
		was_hit = true

func create_heating_loop(time_per_tick : float) -> void:
	still_heating = true
	heating_timer = Timer.new()
	heating_timer.autostart = false
	heating_timer.timeout.connect(gain_one_heat)
	heating_timer.one_shot = true
	parent.add_child(heating_timer)
	heating_timer.start(time_per_tick)

func set_contact(value : bool) -> void:
	in_contact_with_fire = value

func gain_one_heat() -> void:
	loop_number -= 1
	temperature += 1
	if loop_number > 0:
		heating_timer.start(time_per_tick)

func stop_heating_loop() -> void:
	still_heating = false
	loop_number = 0
	if heating_timer:
		heating_timer.stop()
		heating_timer.queue_free()
	lose_heat()

func create_heat_area() -> void:
	var coll_node : CollisionShape2D = parent.coll
	var coll_shape : Shape2D = coll_node.get_shape()
	heat_area = load("res://Scenes/Actions-Reactions/Flame.tscn").instantiate()
	parent.add_child(heat_area)
	heat_area.set_collision(coll_shape, 1 + float(Fire_Range)/10)
	heat_area.Max_Temp_Raise = 2
	heat_area.parent_node = parent

func disable_heat_area() -> void:
	heat_area.queue_free()

func create_burning_timer() -> void:
	if burning_timer == null:
		burning_timer = Timer.new()
		burning_timer.autostart = false
		burning_timer.timeout.connect(exit_burn)
		burning_timer.one_shot = true
		parent.add_child(burning_timer)
		burning_timer.start(Burn_Time)
	else:
		burning_timer.start(Burn_Time)

func lose_heat() -> void:
	temperature = 0

func enter_burn() -> void:
	still_heating = false
	parent.enter_burn_func.call()
	on_flame = true
	create_burning_timer()

func update_burn() -> void:
	if on_flame:
		parent.update_burn_func.call()
	if Burn_Type == "Cool_Off":
		create_burning_timer()

func exit_burn() -> void:
	if (Burn_Type == "Cool_Off" and !in_contact_with_fire) or Burn_Type == "Destroy":
		lose_heat()
		on_flame = false
		if heat_area:
			disable_heat_area()
		parent.exit_burn_func.call()
	else:
		create_burning_timer()

func update_flame_intensity() -> void:
	if heat_area != null:
		heat_area.Flame_Intensity = Base_Heat * temperature

func handle_fire_state() -> void:
	#ganhou temperatura
	if !on_flame and temperature >= Temp_To_Flamed:
		if Emanate_Heat:
			create_heat_area()
		enter_burn() 
		update_burn()
		was_hit = false
	if on_flame and was_hit:
		update_burn()
		was_hit = false
	if temperature >= Max_Temp_Supported and Burn_Type == "Destroy":
		exit_burn()

func heatable_handle_physics() -> void:
	handle_fire_state()
	update_flame_intensity()
############################################ FREEZABLE ############################################

@export_category("Freezable")
@export var Color_Change : Color = Color(0, 0, 1, 0.5)
@export var Auto_Defrost : bool
@export var Defrost_Time : float

signal freeze_ended


var frozen : bool = false

func freeze_ready():
	if Auto_Defrost:
		freeze_ended.connect(be_defrosted)


func be_frozen():
	frozen = true
	parent.coll.debug_color = parent.coll.debug_color + Color_Change
	if Auto_Defrost:
		await get_tree().create_timer(Defrost_Time).timeout
		emit_signal("freeze_ended")

func be_defrosted():
	parent.coll.debug_color = parent.coll.debug_color - Color_Change
	frozen = false


############################################ DRYABLE ############################################

@export_category("Dryable")

############################################ ELECTRIFIABLE ############################################

@export_category("Electrifiable")

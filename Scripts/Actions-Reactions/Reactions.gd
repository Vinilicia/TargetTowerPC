extends Node

@onready var parent : Node2D = get_parent()

@export_category("General")

@export var is_pushable : bool
@export var is_freezable : bool
@export var is_heatable : bool
@export var is_dryable : bool
@export var is_shockable : bool

############################################# GENERAL ############################################

func _physics_process(delta: float) -> void:
	if is_pushable:
		pushable_handle_physics(delta)
	
############################################# PUSHABLE #############################################

@export_category("Pushable")
@export var Weight : float

var knockback_vector := Vector2.ZERO
var dir = 0

func set_knock_dir(direction: int) -> void:
	dir = direction

func be_pushed(push_force : Vector2) -> void:
	knockback_vector = Vector2(0,0)
	if push_force.x - Weight > 0:
		knockback_vector.x = push_force.x - Weight
	if push_force.y + Weight < 0:
		knockback_vector.y = push_force.y + Weight
	knockback_vector.x *= dir

func pushable_handle_physics(_delta):
	if knockback_vector.x != 0:
		parent.velocity += knockback_vector
		knockback_vector = Vector2.ZERO
	if parent.is_on_floor():
		parent.velocity.x = move_toward(parent.velocity.x, 0, parent.velocity.x/7 * dir)
	else:
		parent.velocity.x = move_toward(parent.velocity.x, 0, parent.velocity.x/10 * dir)

############################################ FLAMMABLE ############################################

@export_category("Heatable")

#Intensidade do fogo que esse objeto produz, vai ser passado para a área de fogo
@export var Fire_Intensity : float

#Resistência a fogo, vai ser subtraída da intensidade da fonte ( objeto com intensidade 1 não 
#coloca fogo em objeto com resistencia 1 )
@export var Fire_Resistance : int

#Tempo base demorado para pegar fogo, assumindo que a intensidade da fonte é 1
@export var Time_To_Fire : float

#Tipo de saída do estado fogo. Se o objeto é destruído ou apenas volta ao normal
@export_enum("Cool_off", "Destroy") var Burn_Type : String

#Tempo demorado para sair do estado de fogo
@export var Time_On_Fire : float

#Se o objeto emana calor quando pega fogo. Inimigos provavelmente não vão
@export var Emanates_Heat : bool

#Range da área de fogo ao redor do objeto, 0 significa que a área tem o mesmo tamanho da colisão do
#objeto e 10 significa que tem o dobro
@export_range(0, 10) var Fire_Range : int


#Ta pegando fogo bicho( auto-explicativo i guess? )
var on_fire : bool = false
var still_heating : bool = false

var heating_timer : Timer
var burning_timer : Timer
var heat_area : Area2D

var enter_fire_func : Callable = enter_fire
var exit_fire_func : Callable = exit_fire

func get_hit_by_fire(intensity : int, instant : bool) -> void:
	if instant or on_fire:
		enter_fire_func.call()
	else:
		var heating_time : float = Time_To_Fire / float(max(1, intensity - Fire_Resistance))
		start_heating_timer(heating_time)

func create_heat_area() -> void:
	var coll_node : CollisionShape2D = parent.coll
	var coll_shape : Shape2D = coll_node.get_shape()
	heat_area = load("res://Scenes/Actions-Reactions/Flame.tscn").instantiate()
	heat_area.set_collision(coll_shape, 1 + float(Fire_Range)/10)
	heat_area.parent_node = parent
	parent.call_deferred("add_child", heat_area) 

func start_heating_timer(time_to_fire : float) -> void:
	if heating_timer == null:
		still_heating = true
		heating_timer = Timer.new()
		heating_timer.autostart = false
		heating_timer.one_shot = true
		heating_timer.timeout.connect(enter_fire_func)
		parent.add_child(heating_timer)
		heating_timer.start(time_to_fire)

func stop_heating_timer() -> void:
	if heating_timer != null:
		heating_timer.stop()
		heating_timer.call_deferred("free")

func start_burning_timer() -> void:
	still_heating = true
	burning_timer = Timer.new()
	burning_timer.autostart = false
	burning_timer.one_shot = true
	burning_timer.timeout.connect(exit_fire_func)
	parent.add_child(burning_timer)
	burning_timer.start(Time_On_Fire)

func restart_burning_timer() -> void:
	stop_burning_timer()
	start_burning_timer()

func stop_burning_timer() -> void:
	if burning_timer != null:
		burning_timer.stop()
		burning_timer.call_deferred("free")

func enter_fire() -> void:
	on_fire = true
	if Emanates_Heat:
		create_heat_area()
	start_burning_timer()
	
	parent.enter_fire_func.call()
	enter_fire_func = update_fire

func update_fire() -> void:
	parent.update_fire_func.call()
	if Burn_Type == "Cool_off":
		restart_burning_timer()

func exit_fire() -> void:
	if Burn_Type == "Cool_off":
		on_fire = false
		if Emanates_Heat:
			heat_area.queue_free()
		stop_burning_timer()
		
		parent.exit_fire_func.call()
	
	elif Burn_Type == "Destroy":
		
		parent.exit_fire_func.call()
		call_deferred("free")
	
	enter_fire_func = enter_fire


############################################ FREEZABLE ############################################

@export_category("Freezable")

@export var Auto_Defrosts : bool
@export var Defrosting_Time : float

var enter_ice_func : Callable = enter_ice
var exit_ice_func : Callable = exit_ice

var frozen : bool = false

var defrosting_timer : Timer

func get_hit_by_ice() -> void:
	enter_ice_func.call()


func enter_ice() -> void:
	frozen = true
	enter_ice_func = update_ice
	
	enter_fire_func = exit_ice
	exit_fire_func = func(): pass
	
	parent.enter_ice_func.call()
	if Auto_Defrosts:
		start_defrosting_timer()

func update_ice() -> void:
	parent.update_ice_func.call()

func exit_ice() -> void:
	stop_defrosting_timer()
	enter_ice_func = enter_ice
	
	enter_fire_func = enter_fire
	exit_fire_func = exit_fire
	
	parent.exit_ice_func.call()

func start_defrosting_timer() -> void:
	defrosting_timer = Timer.new()
	defrosting_timer.autostart = false
	defrosting_timer.timeout.connect(exit_ice)
	defrosting_timer.one_shot = true
	parent.add_child(defrosting_timer)
	defrosting_timer.start(Defrosting_Time)

func stop_defrosting_timer() -> void:
	if defrosting_timer != null:
		defrosting_timer.stop()
		defrosting_timer.queue_free()

############################################ SHOCKABLE ############################################

@export_category("Shockable")


var enter_shock_func : Callable = enter_shock
var exit_shock_func : Callable = exit_shock

var in_shock : bool = false

func get_hit_by_shock() -> void:
	enter_shock_func.call()

func enter_shock() -> void:
	in_shock = true
	parent.coll.debug_color += Color(1, 1, 0, 0.5)

func exit_shock() -> void:
	in_shock = false
	parent.coll.debug_color -= Color(1, 1, 0, 0.5)

############################################ DRYABLE ############################################

@export_category("Dryable")

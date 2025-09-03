extends Node2D

var parent : Node2D

@export_category("General")

@export var Is_pushable : bool
@export var Is_freezable : bool
@export var Is_flammable : bool
@export var Is_dryable : bool
@export var Is_shockable : bool

@export var collision_shape : Shape2D

var reaction_area : Area2D
var reaction_collision : CollisionShape2D

var fire_react_path : String = "res://Scenes/Actions-Reactions/Fire_React.tscn"


var fire_react : Reaction

############################################ FLAMMABLE ############################################

@export_category("Flammable")
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

#Intensidade do fogo que esse objeto produz, vai ser passado para a área de fogo
@export var Fire_Intensity : float

#Escala da colisão do fogo em relação a do objeto em si
@export_range(0, 2) var Fire_Scale : float

var fire_properties : Dictionary

############################################# GENERAL ############################################
var thing = true

var is_flammable : bool
var is_freezable : bool
var is_shockable : bool

func _ready() -> void:
	parent = get_parent()
	is_flammable = Is_flammable
	is_freezable = Is_freezable
	is_shockable = Is_shockable
	
	reaction_area = $Reaction_Area
	update_children()

func _process(_delta) -> void:
	if thing and parent.coll != null:
		thing = false
		initialize_area()

func initialize_area() -> void:
	reaction_collision = $Reaction_Area/Coll
	reaction_collision.shape = parent.coll.get_shape()

func update_children() -> void:
	if is_flammable and fire_react == null:
		fire_properties = {
			"fire_resistance": Fire_Resistance,
			"time_to_fire": Time_To_Fire,
			"burn_type": Burn_Type,
			"time_on_fire": Time_On_Fire,
			"emanates_heat": Emanates_Heat,
			"fire_intensity": Fire_Intensity,
			"fire_scale": Fire_Scale
		}
		spawn_fire_react()

func handle_reaction(body_or_area : Node2D) -> void:
	if fire_react != null:
		fire_react.react(body_or_area)

func spawn_fire_react() -> void:
	fire_react = load(fire_react_path).instantiate()
	add_child(fire_react)
	fire_react.initialize(parent, fire_properties)
	
	#fire_react.taken.connect(parent.enter_fire_func)
	#fire_react.stopped.connect(parent.exit_fire_func)

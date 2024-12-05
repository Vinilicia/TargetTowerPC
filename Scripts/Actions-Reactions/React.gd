extends Node

@onready var parent : Node2D = get_parent()

@export_category("General")

@export var is_pushable : bool
@export var is_freezable : bool
@export var is_flammable : bool
@export var is_dryable : bool
@export var is_shockable : bool

var fire_react_path : String = "res://Scenes/Actions-Reactions/Fire_React.tscn"
var freeze_react_path : String = "res://Scenes/Actions-Reactions/Freeze_React.tscn"
var shock_react_path


var fire_react : Node
var freeze_react : Node

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

var fire_properties : Dictionary = {
	"fire_resistance": Fire_Resistance,
	"time_to_fire": Time_To_Fire,
	"burn_type": Burn_Type,
	"time_on_fire": Time_On_Fire,
	"emanates_heat": Emanates_Heat,
	"fire_intensity": Fire_Intensity,
	"fire_scale": Fire_Scale
}

############################################ FREEZABLE ############################################

@export_category("Freezable")

@export var Auto_Defrosts : bool
@export var Defrosting_Time : float

var freeze_properties : Dictionary = {
	"auto_defrosts": Auto_Defrosts,
	"defrosting_time": Defrosting_Time
}

############################################# GENERAL ############################################

func _ready() -> void:
	initialize_children()

func initialize_children() -> void:
	if is_flammable:
		spawn_fire_react()
	if is_freezable:
		spawn_freeze_react()
	if is_shockable:
		spawn_shock_react()

func handle_reaction(body_or_area : Node2D) -> void:
	if fire_react != null:
		fire_react.react(body_or_area)
	if freeze_react != null:
		freeze_react.react(body_or_area)
	#if shock_react != null:
		#pass

func spawn_fire_react() -> void:
	fire_react = load(fire_react_path).instantiate()
	add_child(fire_react)
	fire_react.initialize(parent, fire_properties)

func spawn_freeze_react() -> void:
	freeze_react = load(freeze_react_path).instantiate()
	add_child(freeze_react)
	freeze_react.initialize(parent, freeze_properties)

func spawn_shock_react() -> void:
	pass

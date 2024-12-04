extends Node

@onready var parent : Node2D = get_parent()

@export_category("General")

@export var is_pushable : bool
@export var is_freezable : bool
@export var is_heatable : bool
@export var is_dryable : bool
@export var is_shockable : bool


############################################ FLAMMABLE ############################################

@export_category("Heatable")


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



############################################ FREEZABLE ############################################

@export_category("Freezable")

@export var Auto_Defrosts : bool
@export var Defrosting_Time : float

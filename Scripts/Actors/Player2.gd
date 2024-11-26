extends CharacterBody2D

#Relacionados a movimentação e tal. Ao platforming
@export var Move_Speed : float
@export var Jump_Force : float
@export var Gravity_Multiplier : float
@export var Jump_buffering_time : float

#Provavelemente isso vai ser retirado depois :) 
@export var Default_Knockback : Vector2 = Vector2(170, 0)

#Meio que pra debuggar. Só o tempo que ele pode ficar fora da tela antes de reiniciar a cena
@export var Exit_Time : float

#Coisas relacionadas a atirar flechas
@export var Max_hold_time : float
@export var Shoot_Delay : float

#Onde as flechas ficam e o maximo, pra poder voltar no inicio quando chegar no final
@export var Arrows_paths : Array[String]
@export var Max_Arrows : int


@onready var screen_exit_timer = $Timers/Screen_Exit_Timer as Timer

#Tem que ter um jeito de arrumar isso daqui. Namoral
@onready var arrow_spawner = $Arrow_Spawner as Marker2D
@onready var arrow_sprite = $Arrow_Spawner/Arrow_Sprite as Sprite2D

@onready var shooting_timer = $Timers/Shooting_Timer as Timer
@onready var jump_buffering = $Timers/Jump_Buffering as Timer

@onready var state_chart = $StateChart as StateChart
 
#Provavelmente vai sair quando botar um Reactions no player pra ele poder ser empurrado
var knockback_vector : Vector2

var gravity : float = ProjectSettings.get_setting("physics/2d/default_gravity")
var facing_direction : int = 1
var is_jumping : bool = false
var on_floor : bool = true
var is_on_screen : bool = true

var current_arrow : Arrow
var can_shoot : bool = true
var is_holding : bool = false
var holding_time : float = 0.0
var fall_jump_buffer : bool = false
var ledge_jump_buffer : bool = false

@export_category("Para debugar")
@export_range(0 , 9) var Initial_Arrow_Index : int # so vai ate 7 por enquanto

var current_arrow_index : int

func _ready():
	current_arrow_index = Initial_Arrow_Index
	current_arrow = equip_arrow(current_arrow_index)

func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	pass

func equip_arrow(index : int) -> Arrow:
	return Arrow.new()

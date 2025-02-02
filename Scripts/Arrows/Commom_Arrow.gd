extends Area2D
class_name Arrow

@onready var anim = $Anim_Player as AnimationPlayer
@onready var sprite = $Sprite as Sprite2D
@onready var coll = $Coll

@export var Flying_Speed : float = 320
@export var Charge_Multiplier : float = 2
@export var Despawn_Time : float = 0
@export var Cost : int = 1

var direction : int = 1
var charged : bool = false
var downward : bool = false
var velocity := Vector2.ZERO 

func _ready():
	body_entered.connect(_on_body_entered) 
	
func _physics_process(delta):
	position += velocity * delta 

func fly(is_charged : bool, _player : CharacterBody2D) -> void:
	if is_charged:
		charged = true
		velocity = Vector2(direction * Flying_Speed * Charge_Multiplier, 0)
	else:
		velocity = Vector2(direction * Flying_Speed, 0)

func fly_downward(_player : CharacterBody2D) -> void:
	flip_children()
	downward = true
	velocity = Vector2(0, Flying_Speed * 1.2)

func flip_children() -> void:
	rotation = deg_to_rad(90)

func set_direction(dir : int) -> void:
	if direction != dir:
		rotation = deg_to_rad(180)
		direction = dir

func spawn_joint(body) -> void:
	var pos = global_position
	var pos_relativa = pos - body.global_position
	self.get_parent().call_deferred("remove_child", self)
	body.call_deferred("add_child", self)
	self.position = pos_relativa

func bounce() -> void:
	despawn()

func despawn() -> void:
	await get_tree().create_timer(Despawn_Time).timeout
	queue_free()

func get_frozen() -> void:
	velocity = Vector2.ZERO
	coll.call_deferred("set_disabled", true)

func _on_body_entered(body: Node2D) -> void:
	get_frozen()
	if body.is_in_group("Attachables"):
		spawn_joint(body)
		despawn()
	else:
		bounce()

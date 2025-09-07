extends CharacterBody2D

@export_enum("Left", "Right") var direction : int

@onready var rock = preload("res://Scenes/Actors/Enemies/Throwable_rock.tscn")
@onready var sight_area := $SightArea as Area2D
@onready var rock_spawner = $RockSpawner as Marker2D
@onready var look_around_timer = $LookAroundTimer as Timer
@onready var attack_timer = $AttackTimer as Timer
@onready var loose_sight_timer = $LooseSightTimer as Timer

var player_is_nearby : bool = false
var player_target : CharacterBody2D
var timer_off : bool = false
var angle : float

func _ready() -> void:
	if direction == 0:
		direction = -1
	else:
		direction = 1
		flip()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		move_and_slide()
	
	if player_is_nearby:
		handle_attack()

func _throw_rock() -> void:
	timer_off = false
	var instance = rock.instantiate()
	get_parent().call_deferred("add_child", instance)
	instance.top_level = true
	instance.global_position = rock_spawner.global_position
	instance.call_deferred("throw", player_target.position)
	
func _player_entered_sight_area(player: Node2D) -> void:
	player_target = player
	player_is_nearby = true
	if !look_around_timer.is_stopped():
		look_around_timer.stop()
	if attack_timer.is_stopped():
		attack_timer.start()
	if !loose_sight_timer.is_stopped():
		loose_sight_timer.stop()

func _player_exited_sight_area(_player: Node2D) -> void:
	if loose_sight_timer.is_inside_tree():
		loose_sight_timer.start()

func flip() -> void:
	sight_area.position.x *= -1

func ran_out_of_health() -> void:
	queue_free()

func _on_look_around_timer_timeout() -> void:
	flip()

func handle_attack() -> void:
	if position.x - player_target.position.x > 0:
		if direction != -1:
			direction = -1
			flip()
	else:
		if direction != 1:
			direction = 1
			flip()

func _on_attack_timer_timeout() -> void:
	_throw_rock()

func _on_loose_sight_timer_timeout() -> void:
	player_is_nearby = false
	if attack_timer.is_inside_tree():
		attack_timer.stop()
	print("Anal")
	if look_around_timer.is_inside_tree():
		print("Sex")
		look_around_timer.start()

extends CharacterBody2D

@export_enum("Esquerda", "Direita") var direction : int
@export var sight_area_scale : Vector2 = Vector2(320, 150)

@onready var rock = load("res://Scenes/Actors/Enemies/Throwable_rock.tscn")
@onready var sight_area := $Sight_Area as Area2D
@onready var rock_spawner = $RockSpawner as Marker2D

var player_is_nearby : bool = false
var player_target : CharacterBody2D
var timer_off : bool = true
var angle : float

func _ready() -> void:
	sight_area.scale = sight_area_scale
	
	if direction == 0:
		direction = -1
	else:
		direction = 1
		
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		move_and_slide()
		
	if player_is_nearby:
		if position.x - player_target.position.x > 0:
			if direction != -1:
				direction = -1
				flip()
		else:
			if direction != 1:
				direction = 1
				flip()
		if timer_off:
			_throw_rock()
	
func _throw_rock() -> void:
	timer_off = false
	var instance = rock.instantiate()
	call_deferred("add_child", instance)
	instance.top_level = true
	instance.global_position = rock_spawner.global_position
	instance.call_deferred("throw", player_target.position)
	await get_tree().create_timer(2).timeout
	timer_off = true
	
func _player_entered_sight_area(player: Node2D) -> void:
	player_target = player
	player_is_nearby = true

func _player_exited_sight_area(player: Node2D) -> void:
	player_is_nearby = false

func flip() -> void:
	sight_area.position.x *= -1

func ran_out_of_health() -> void:
	queue_free()

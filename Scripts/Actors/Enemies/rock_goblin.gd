extends CharacterBody2D

@export_enum("Esquerda", "Direita") var direction: int

@onready var rock = load("res://Scenes/Actors/Enemies/Throwable_rock.tscn")
@onready var line_of_sight := $Line_Of_Sight as RayCast2D
@onready var sight_area := $Sight_Area/CollisionShape2D as CollisionShape2D
@onready var rock_spawner = $Rock_Spawner as Marker2D

var player_is_nearby : bool = false
var player_target : CharacterBody2D
var timer_off : bool = true
var angle : float

func _ready() -> void:
	if direction == 0:
		direction = -1;
	else:
		direction = 1;
		
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		move_and_slide()
		
	if player_is_nearby:
		line_of_sight.target_position = player_target.global_position - global_position
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
	get_parent().call_deferred("add_child", instance)
	instance.global_position = rock_spawner.global_position
	instance.direction = direction
	instance.throw(player_target.position)
	await get_tree().create_timer(2).timeout
	timer_off = true
	
func _player_entered_sight_area(player: Node2D) -> void:
	player_target = player
	player_is_nearby = true

func _player_exited_sight_area(player: Node2D) -> void:
	player_is_nearby = false

func flip() -> void:
	sight_area.position.x *= -1
	rock_spawner.position.x *= -1

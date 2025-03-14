extends CharacterBody2D

@export_enum("Esquerda", "Direita") var direction: int
@export var speed = 70.0

@onready var state_chart = $StateChart as StateChart

@onready var line_of_sight := $Line_Of_Sight as RayCast2D
@onready var wall_detector := $Detectors/Wall_Detector as RayCast2D
@onready var ground_detector := $Detectors/Ground_Detector as RayCast2D
@onready var attack_area := $Attack_Area/CollisionShape2D as CollisionShape2D
@onready var sight_area := $Sight_Area/CollisionShape2D as CollisionShape2D
@onready var arrow_detector := $Arrow_Detector as Area2D
@onready var arrow_detector_area := $Arrow_Detector as Area2D
@onready var coll: = $coll as CollisionShape2D

var is_player_inside: bool = false
var player_is_nearby: bool = false
var saw_player : bool = false
var player_target : CharacterBody2D
var player_relative_position : Vector2
var can_dash : bool = true

func _ready() -> void:
	if direction == 0:
		direction = -1;
	else:
		direction = 1;

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if (wall_detector.is_colliding() or not ground_detector.is_colliding()) and not saw_player:
		direction *= -1
		flip()
		
	velocity.x = direction * speed
	
	if player_is_nearby:
		player_relative_position = player_target.global_position - global_position
		line_of_sight.target_position = player_relative_position
		if !saw_player and line_of_sight.get_collider() == player_target:
			state_chart.send_event("Chase_Player")
			saw_player = true
		
	if not ((wall_detector.is_colliding() or not ground_detector.is_colliding()) and saw_player):
		move_and_slide()

func _player_entered_sight_area(player: Node2D) -> void:
	player_target = player
	player_is_nearby = true
	can_dash = false	

func _player_exited_sight_area(player: Node2D) -> void:
	player_is_nearby = false
	saw_player = false
	state_chart.send_event("Guard")
	can_dash = true

func _player_entered_attack_area(body: Node2D) -> void:
	is_player_inside = true
	await get_tree().create_timer(0.5).timeout
	if is_player_inside:
		#print_debug("tomou dano")
		attack_area.disabled = true
		attack_area.disabled = false

func _player_exited_attack_area(body: Node2D) -> void:
	is_player_inside = false

func _on_chasing_state_physics_processing(delta: float) -> void:
	if line_of_sight.get_collider() != player_target and saw_player:
		saw_player = false
		state_chart.send_event("Guard")
	if position.x - player_target.position.x > 0:
		if direction != -1:
			direction = -1
			flip()
	else:
		if direction != 1:
			direction = 1
			flip()

func flip() -> void:
	wall_detector.scale.x *= -1
	ground_detector.position.x *= -1
	attack_area.position.x *= -1
	sight_area.position.x *= -1
	arrow_detector.position *= -1

func _on_arrow_entered(arrow: Area2D) -> void:
	if can_dash:
		set_collision_layer_value(4, false)
		speed *= 3
		can_dash = false
		await get_tree().create_timer(0.5).timeout
		set_collision_layer_value(4, true)
		speed /= 3
		if not player_is_nearby:
			can_dash = true
	
	

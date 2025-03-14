extends CharacterBody2D

@export_enum("Esquerda", "Direita") var direction: int
@export var speed = 70.0

@onready var state_chart = $StateChart as StateChart

@onready var line_of_sight := $Line_Of_Sight as RayCast2D
@onready var wall_detector := $Detectors/Wall_Detector as RayCast2D
@onready var ground_detector := $Detectors/Ground_Detector as RayCast2D
@onready var attack_area := $Attack_Area/CollisionShape2D as CollisionShape2D
@onready var sight_area := $Sight_Area/CollisionShape2D as CollisionShape2D
@onready var arrow_detector := $Arrow_Detector/CollisionShape2D as CollisionShape2D
@onready var arrow_detector_area := $Arrow_Detector as Area2D
@onready var coll:= $coll as CollisionShape2D
@onready var shield:= $Shield/CollisionShape2D as CollisionShape2D
@onready var area_shield:= $Area_Shield/CollisionShape2D as CollisionShape2D

var shield_timer : Timer = null
var is_player_inside: bool = false
var player_is_nearby: bool = false
var saw_player : bool = false
var player_target : CharacterBody2D
var player_relative_position : Vector2
var stop : bool = false

func _ready() -> void:
	shield_timer = Timer.new()
	shield_timer.autostart = false
	add_child(shield_timer)
	shield_timer.one_shot = true
	shield_timer.timeout.connect(unstop_goblin)
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
		arrow_detector.disabled = true
		player_relative_position = player_target.global_position - global_position
		line_of_sight.target_position = player_relative_position
		if !saw_player and line_of_sight.get_collider() == player_target and shield.disabled:
			state_chart.send_event("Chase_Player")
			saw_player = true
	else:
		arrow_detector.disabled = false
		
	if (not ((wall_detector.is_colliding() or not ground_detector.is_colliding()) and saw_player)) and shield.disabled:
		move_and_slide()

func _player_entered_sight_area(player: Node2D) -> void:
	player_target = player
	player_is_nearby = true

func _player_exited_sight_area(player: Node2D) -> void:
	player_is_nearby = false
	saw_player = false
	if shield.disabled:
		state_chart.send_event("Guard")

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
			
func _on_shielding_state_physics_processing(delta: float) -> void:
	if player_target != null and line_of_sight.get_collider() == player_target and not stop:
		if position.y - player_target.position.y > 30:
			shield_up()
		else:
			if position.x - player_target.position.x > 0:
				shield_down()
				if direction != -1:
					direction = -1
					flip()
			else:
				shield_down()
				if direction != 1:
					direction = 1
					flip()

func flip() -> void:
	wall_detector.scale.x *= -1
	ground_detector.position.x *= -1
	attack_area.position.x *= -1
	sight_area.position.x *= -1
	arrow_detector.position.x *= -1
	shield.position.x *= -1
	area_shield.position.x *= -1

func shield_up():
	shield.rotation = deg_to_rad(90)
	shield.position.x = 0
	shield.position.y = -16
	area_shield.rotation = deg_to_rad(90)
	area_shield.position.x = 0
	area_shield.position.y = -18
	
func shield_down():
	shield.rotation = 0
	area_shield.rotation = 0
	if direction == -1:
		shield.position.x = -16
		area_shield.position.x = -18
	else:
		shield.position.x = 16
		area_shield.position.x = 18
	shield.position.y = -6
	area_shield.position.y = -6
	
func _on_arrow_entered(arrow: Area2D) -> void:
	if shield.disabled:
		arrow.set_collision_mask_value(4, false)
		set_collision_mask_value(2, false)
		speed *= 3
		await get_tree().create_timer(0.5).timeout
		set_collision_mask_value(2, true)
		speed /= 3

func _arrow_entered_area_shield(body: Node2D) -> void:
	if not shield.disabled:
		stop = true
		shield_timer.start(2.5)
		
func unstop_goblin() -> void:
	stop = false

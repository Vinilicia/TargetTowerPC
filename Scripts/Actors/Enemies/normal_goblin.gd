extends CharacterBody2D

const DASH_DURATION : float = 0.4
const DASH_SPEED_MULTIPLIER : float = 2

@export_enum("Esquerda", "Direita") var start_direction: int
@export var walk_speed: float = 70.0
@export var chase_speed: float = 105.0
@export var v_component : VelocityComponent
@export var lines_of_sight : Array[RayCast2D]   # vários raycasts

@onready var state_chart: StateChart = $StateChart

@onready var wall_detector: RayCast2D = $Detectors/WallDetector
@onready var ground_detector: RayCast2D = $Detectors/GroundDetector
@onready var attack_area: Area2D = $Areas/AttackArea
@onready var sight_area: Area2D = $Areas/SightArea
@onready var outer_arrow_detec: Area2D = $Areas/OuterArrowDetector
@onready var inner_arrow_detec: Area2D = $Areas/InnerArrowDetector
@onready var coll: CollisionShape2D = $Coll

@export var hurtbox: Hurtbox
@export var attack: Hitbox

var player_target: CharacterBody2D
var player_relative_position: Vector2

var direction: int = 1
var is_player_inside: bool = false
var player_is_nearby: bool = false
var saw_player: bool = false
var can_dash: bool = true


func _ready() -> void:
	# Normaliza a direção inicial
	direction = -1 if start_direction == 0 else 1
	if direction == 1:
		flip()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	var hit_wall := wall_detector.is_colliding()
	var no_ground := not ground_detector.is_colliding()

	if (hit_wall or no_ground) and not saw_player:
		_change_direction()

	if player_is_nearby:
		_update_lines_of_sight()
		if not saw_player and _player_visible_in_sight():
			_start_chase()

	if not ((hit_wall or no_ground) and saw_player):
		velocity = v_component.get_total_velocity()
		move_and_slide()


# ======================
# DETECÇÃO DO PLAYER
# ======================

func _update_lines_of_sight() -> void:
	for los in lines_of_sight:
		player_relative_position = player_target.global_position - los.global_position
		los.target_position = player_relative_position


func _player_visible_in_sight() -> bool:
	for los in lines_of_sight:
		if los.is_colliding() and los.get_collider() == player_target:
			return true
	return false


func _start_chase() -> void:
	state_chart.send_event("Chase_Player")
	saw_player = true


func _player_entered_sight_area(player: Node2D) -> void:
	player_target = player
	player_is_nearby = true
	can_dash = false	


func _player_exited_sight_area(_player: Node2D) -> void:
	player_is_nearby = false
	saw_player = false
	state_chart.send_event("Guard")
	can_dash = true


# ======================
# ATAQUE
# ======================

func _player_entered_attack_area(_body: Node2D) -> void:
	attack.set_deferred("monitorable", true)
	attack.visible = true
	await get_tree().create_timer(0.5).timeout
	attack.visible = false
	attack.set_deferred("monitorable", false)


func _player_exited_attack_area(_body: Node2D) -> void:
	is_player_inside = false


# ======================
# ESTADOS
# ======================

func _on_chasing_state_physics_processing(_delta: float) -> void:
	v_component.set_proper_velocity(chase_speed * direction, 1)
	
	if not _player_visible_in_sight() and saw_player:
		saw_player = false
		state_chart.send_event("Guard")

	var target_dir : int = sign(player_target.position.x - position.x)
	if target_dir != direction:
		direction = target_dir
		flip()


func _on_guarding_state_physics_processing(delta: float) -> void:
	v_component.set_proper_velocity(walk_speed * direction, 1)


# ======================
# MECÂNICAS
# ======================

func flip() -> void:
	# espelha todos os detectores e áreas
	wall_detector.scale.x *= -1
	ground_detector.position.x *= -1
	attack_area.position.x *= -1
	sight_area.position.x *= -1
	outer_arrow_detec.position *= -1
	attack.position.x *= -1
	lines_of_sight[2].position.x *= -1


func _change_direction() -> void:
	direction *= -1
	flip()


func _on_arrow_entered(_arrow: Area2D) -> void:
	if not can_dash:
		return
	hurtbox.get_invincible(DASH_DURATION)

	walk_speed *= DASH_SPEED_MULTIPLIER
	chase_speed *= DASH_SPEED_MULTIPLIER
	can_dash = false
	
	await get_tree().create_timer(DASH_DURATION).timeout
	walk_speed /= DASH_SPEED_MULTIPLIER
	chase_speed /= DASH_SPEED_MULTIPLIER

	if not player_is_nearby:
		can_dash = true


# ======================
# VIDA
# ======================

func _on_health_ran_out() -> void:
	queue_free()


func _on_health_lost_health(amount: float) -> void:
	print("Took ", amount, " damage.")

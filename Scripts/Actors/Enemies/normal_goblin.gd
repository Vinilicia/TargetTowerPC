extends CharacterBody2D

const DASH_DURATION : float = 0.4
const DASH_SPEED_MULTIPLIER : float = 2.0
const CHASE_PERSISTENCE_TIME : float = 1.0
const LOOK_AROUND_TIME : float = 2.0
const LOOK_AROUND_AREA_INCREASE : float = 1.5
const GIVING_UP_CHASE_TIME : float = 2.0

@export_enum("Esquerda", "Direita") var start_direction: int
@export var walk_speed: float
@export var chase_speed: float
@export var jump_force : float
@export var v_component : VelocityComponent
@export var direction_change_delay : float = 0.3
@export var lines_of_sight : Array[RayCast2D]

@onready var state_chart: StateChart = $StateChart

@onready var wall_detector: RayCast2D = $Detectors/WallDetector
@onready var jump_detector: RayCast2D = $Detectors/JumpDetector
@onready var fall_detector: RayCast2D = $Detectors/FallDetector
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
var outer_detector : bool = false
var inner_detector : bool = false
var is_changing_direction := false
var is_jumping : bool = false


func _ready() -> void:
	
	# Normaliza a direção inicial
	direction = -1 if start_direction == 0 else 1
	if direction == 1:
		flip()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		v_component.add_proper_velocity(get_gravity() * delta)
	else:
		if is_jumping:
			is_jumping = false
		v_component.set_proper_velocity(0, 2)

	if player_is_nearby:
		_update_lines_of_sight()
		if not saw_player and _player_visible_in_sight():
			_start_chase()

	if !is_changing_direction:
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
	is_player_inside = true
	assign_player(player)

func assign_player(player : Node2D) -> void:
	player_target = player
	player_is_nearby = true

func unnasign_player() -> void:
	if !is_player_inside:
		player_is_nearby = false
		saw_player = false
		state_chart.send_event("Guard")

func _player_exited_sight_area(_player: Node2D) -> void:
	is_player_inside = false
	await get_tree().create_timer(CHASE_PERSISTENCE_TIME).timeout
	unnasign_player()

func look_for_player() -> void:
	_change_direction()
	sight_area.scale.x *= LOOK_AROUND_AREA_INCREASE
	await get_tree().create_timer(LOOK_AROUND_TIME).timeout
	sight_area.scale.x /= LOOK_AROUND_AREA_INCREASE

# ======================
# ATAQUE
# ======================

func _player_entered_attack_area(_body: Node2D) -> void:
	attack.set_deferred("monitorable", true)
	attack.visible = true
	await get_tree().create_timer(0.5).timeout
	attack.visible = false
	attack.set_deferred("monitorable", false)


# ======================
# ESTADOS
# ======================

func jump() -> void:
	is_jumping = true
	v_component.set_proper_velocity(jump_force, 2)

func _on_chasing_state_physics_processing(_delta: float) -> void:
	v_component.set_proper_velocity(chase_speed * direction, 1)
	
	wall_detector.force_raycast_update()
	ground_detector.force_raycast_update()
	jump_detector.force_raycast_update()
	fall_detector.force_raycast_update()
	var hit_wall := wall_detector.is_colliding()
	var can_jump := !jump_detector.is_colliding()
	var no_ground := !ground_detector.is_colliding()
	var can_fall := fall_detector.is_colliding()
	if (hit_wall or no_ground):
		if hit_wall and can_jump and !is_jumping and abs(player_target.global_position.y - global_position.y) > 10  :
			jump()
		elif no_ground and can_fall:
			pass
		else:
			v_component.set_proper_velocity(0.0, 1)
	
	if not _player_visible_in_sight() and saw_player:
		var giving_up_timer : Timer = Timer.new()
		giving_up_timer.one_shot = true
		giving_up_timer.autostart = false
		giving_up_timer.wait_time = GIVING_UP_CHASE_TIME
		giving_up_timer.timeout.connect(func():
			saw_player = false
			state_chart.send_event("Guard")
			)
		add_child(giving_up_timer)
		giving_up_timer.start()
	
	var position_difference = player_target.position.x - position.x
	var target_dir : int = sign(position_difference)
	if target_dir != direction and is_on_floor() and abs(position_difference) > 10:
		_change_direction()


func _on_guarding_state_physics_processing(delta: float) -> void:
	v_component.set_proper_velocity(walk_speed * direction, 1)
	
	wall_detector.force_raycast_update()
	var hit_wall := wall_detector.is_colliding()
	ground_detector.force_raycast_update()
	var no_ground := !ground_detector.is_colliding()
	
	if (hit_wall or no_ground) and is_on_floor():
		_change_direction()


# ======================
# MECÂNICAS
# ======================

func flip() -> void:
	wall_detector.scale.x *= -1
	jump_detector.scale.x *= -1
	ground_detector.position.x *= -1
	fall_detector.position.x *= -1
	attack_area.position.x *= -1
	sight_area.position.x *= -1
	attack.position.x *= -1
	lines_of_sight[2].position.x *= -1
	outer_arrow_detec.scale *= -1
	inner_arrow_detec.scale *= -1


func _change_direction() -> void:
	if is_changing_direction:
		return
	
	is_changing_direction = true
	await get_tree().create_timer(direction_change_delay).timeout

	# só vira depois do delay
	direction *= -1
	flip()

	is_changing_direction = false


func _on_outer_detector_entered(_area: Area2D) -> void:
	outer_detector = true
	call_deferred("try_avoid")

func _on_inner_detector_entered(_area: Area2D) -> void:
	inner_detector = true

func try_avoid() -> void:
	if outer_detector and !inner_detector:
		avoid_arrow()

func avoid_arrow() -> void:
	if not can_dash:
		return
	can_dash = false
	hurtbox.get_invincible(DASH_DURATION)

	walk_speed *= DASH_SPEED_MULTIPLIER
	chase_speed *= DASH_SPEED_MULTIPLIER
	
	await get_tree().create_timer(DASH_DURATION * 2).timeout
	walk_speed /= DASH_SPEED_MULTIPLIER
	chase_speed /= DASH_SPEED_MULTIPLIER

	outer_detector = false
	inner_detector = false
	can_dash = true

# ======================
# VIDA
# ======================

func _on_health_ran_out() -> void:
	queue_free()

func _on_health_lost_health(amount: float) -> void:
	print("Took ", amount, " damage.")

func _on_hurtbox_got_hit_by(hitbox: Hitbox) -> void:
	if hitbox.get_collision_layer_value(10) and !saw_player:
		look_for_player()

func _on_inner_detector_exited(area: Area2D) -> void:
	inner_detector = false

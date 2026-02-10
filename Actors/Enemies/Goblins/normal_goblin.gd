extends CharacterBody2D

# ======================
# CONSTANTES
# ======================
const DASH_DURATION : float = 0.6
const DASH_SPEED_MULTIPLIER : float = 2.0
const LOOK_AROUND_TIME : float = 2.0
const LOOK_AROUND_AREA_INCREASE : float = 2
const ARROW_AVOID_DELAY : float = 0.15

# ======================
# EXPORTS
# ======================
@export_enum("Esquerda", "Direita") var start_direction: int
@export var walk_speed: float
@export var chase_speed: float
@export var jump_force : float
@export var v_component : VelocityComponent
@export var direction_change_delay : float = 0.3
@export var lines_of_sight : Array[RayCast2D]
@export var hurtbox: Hurtbox
@export var slash_hitbox : Hitbox

# ======================
# ONREADY
# ======================
@onready var state_chart: StateChart = $WhiteNodes/StateChart

@onready var wall_detector: RayCast2D = $Raycasts/Detectors/WallDetector
@onready var jump_detector: RayCast2D = $Raycasts/Detectors/JumpDetector
@onready var fall_detector: RayCast2D = $Raycasts/Detectors/FallDetector
@onready var ground_detector: RayCast2D = $Raycasts/Detectors/GroundDetector

@onready var jump_attack_area: Area2D = $Areas/JumpAttackArea
@onready var stab_attack_area: Area2D = $Areas/StabAttackArea
@onready var sight_area: Area2D = $Areas/SightArea
@onready var outer_arrow_detec: Area2D = $Areas/OuterArrowDetector
@onready var inner_arrow_detec: Area2D = $Areas/InnerArrowDetector

@onready var coll: CollisionShape2D = $Coll
@onready var giving_up_timer : Timer = $WhiteNodes/Timers/GivingUpTimer
@onready var jump_attack_timer : Timer = $WhiteNodes/Timers/JumpAttackTimer
@onready var stab_attack_timer : Timer = $WhiteNodes/Timers/StabAttackTimer

# ======================
# VARIÁVEIS DE ESTADO
# ======================
var player_target: CharacterBody2D
var player_relative_position: Vector2

var direction: int = 1
var current_speed : float
var is_player_inside: bool = false
var player_is_nearby: bool = false
var saw_player: bool = false

var can_dash: bool = true
var is_changing_direction := false
var is_jumping : bool = false
var still_cant_react : bool = false
var saw_arrow : bool = false

var attacking : bool = false
var can_jump_attack : bool = true
var can_stab_attack : bool = true
var player_in_range : bool = false
var start_attack : bool = false
var current_speed_multiplier : float = 1.0


# ======================
# CICLO DE VIDA
# ======================
func _ready() -> void:
	direction = -1 if start_direction == 0 else 1
	if direction == 1:
		flip()

var is_falling : bool = false

func _physics_process(delta: float) -> void:
	if not (attacking or player_in_range):
		v_component.set_proper_velocity(current_speed * direction * current_speed_multiplier, 1)
	
	if not is_on_floor():
		v_component.add_proper_velocity(get_current_gravity() * delta)
	else:
		if is_jumping:
			if is_falling:
				is_jumping = false
				is_falling = false
				v_component.set_proper_velocity(0.0, 2)
		else:
			is_falling = false
			v_component.set_proper_velocity(0.0, 2)
	
	if v_component.get_total_velocity().y > 0.0:
		is_falling = true

	if player_is_nearby:
		_update_lines_of_sight()
		if not saw_player and _player_visible_in_sight():
			_start_chase()

	if !is_changing_direction:
		velocity = v_component.get_total_velocity()
		move_and_slide()


# ======================
# GRAVIDADE
# ======================
func get_current_gravity() -> Vector2:
	return get_gravity() / 2 if attacking else get_gravity()

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
	assign_player(player)
	if !giving_up_timer.is_stopped():
		giving_up_timer.stop()

func assign_player(player : Node2D) -> void:
	player_target = player
	player_is_nearby = true

func unnasign_player() -> void:
	saw_player = false
	state_chart.send_event("Guard")

func _player_exited_sight_area(_player: Node2D) -> void:
	player_is_nearby = false
	if giving_up_timer.is_stopped() and giving_up_timer.is_inside_tree():
		giving_up_timer.start()

func look_for_player() -> void:
	_change_direction()
	sight_area.scale.x *= LOOK_AROUND_AREA_INCREASE
	await get_tree().create_timer(LOOK_AROUND_TIME).timeout
	sight_area.scale.x /= LOOK_AROUND_AREA_INCREASE


# ======================
# ATAQUE
# ======================
func _player_entered_jump_attack_area(_body: Node2D) -> void:
	if is_on_floor() and can_jump_attack:
		start_attack = false
		jump_attack()
	else:
		start_attack = true

func _player_exited_jump_attack_area(_body: Node2D) -> void:
	start_attack = false

func _player_entered_stab_attack_area(_body: Node2D) -> void:
	player_in_range = true
	state_chart.send_event("Attack")

func _player_exited_stab_attack_area(_body: Node2D) -> void:
	player_in_range = false

func attack() -> void:
	attacking = true
	slash_hitbox.set_deferred("monitorable", true)
	slash_hitbox.visible = true
	await get_tree().create_timer(0.5).timeout
	attacking = false
	slash_hitbox.visible = false
	slash_hitbox.set_deferred("monitorable", false)

func jump_attack() -> void:
	can_jump_attack = false
	can_stab_attack = false
	if !stab_attack_timer.is_stopped():
		stab_attack_timer.stop()
	v_component.set_proper_velocity(Vector2(100 * direction, -80))
	attack()
	_reset_cooldown(jump_attack_timer)
	_reset_cooldown(stab_attack_timer)

func stab_attack() -> void:
	can_stab_attack = false
	can_jump_attack = false
	if !jump_attack_timer.is_stopped():
		jump_attack_timer.stop()
	attack()
	_reset_cooldown(jump_attack_timer)
	_reset_cooldown(stab_attack_timer)

func _reset_cooldown(timer : Timer) -> void:
	timer.start()

func _on_jump_attack_timer_timeout() -> void:
	can_jump_attack = true

func _on_stab_attack_timer_timeout() -> void:
	can_stab_attack = true

# ======================
# ESTADOS
# ======================
func jump() -> void:
	is_jumping = true
	v_component.set_proper_velocity(jump_force, 2)

func _on_attack_state_physics_processing(_delta: float) -> void:
	if is_on_floor():
		v_component.set_proper_velocity(0.0, 1)
		if player_in_range and can_stab_attack:
			stab_attack()
	
	if !player_in_range and !attacking:
		state_chart.send_event("Chase")

func _on_chasing_state_physics_processing(_delta: float) -> void:

	# detectores
	wall_detector.force_raycast_update()
	ground_detector.force_raycast_update()
	jump_detector.force_raycast_update()
	fall_detector.force_raycast_update()

	var hit_wall := wall_detector.is_colliding()
	var can_jump := !jump_detector.is_colliding()
	var no_ground := !ground_detector.is_colliding()
	var can_fall := fall_detector.is_colliding()

	if (hit_wall or no_ground):
		var can_jump_now : bool = can_jump and !is_jumping and is_on_floor()
		var enough_y_dist = (player_target.global_position.y - global_position.y) < -10
		var enough_x_dist = (player_target.global_position.x - global_position.x) * direction > 15 * direction
		if hit_wall and can_jump_now and enough_x_dist and enough_y_dist:
			jump()
		elif no_ground and can_fall:
			pass
		else:
			v_component.set_proper_velocity(0.0, 1)

	if not _player_visible_in_sight() and saw_player:
		if giving_up_timer.is_stopped():
			giving_up_timer.start()

	var position_difference = player_target.position.x - position.x
	var target_dir : int = sign(position_difference)
	if target_dir != direction and is_on_floor() and abs(position_difference) > 10:
		_change_direction()

	if start_attack:
		_player_entered_jump_attack_area(null)

func _on_giving_up_timer_timeout() -> void:
	unnasign_player()

func _on_guarding_state_physics_processing(_delta: float) -> void:

	wall_detector.force_raycast_update()
	ground_detector.force_raycast_update()

	var hit_wall := wall_detector.is_colliding()
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
	jump_attack_area.position.x *= -1
	stab_attack_area.position.x *= -1
	sight_area.position.x *= -1
	slash_hitbox.position.x *= -1
	lines_of_sight[2].position.x *= -1
	outer_arrow_detec.scale.x *= -1
	inner_arrow_detec.scale.x *= -1

func _change_direction() -> void:
	if is_changing_direction:
		return
	
	is_changing_direction = true
	await get_tree().create_timer(direction_change_delay).timeout

	direction *= -1
	flip()
	is_changing_direction = false

func _on_outer_detector_entered(_area: Area2D) -> void:
	saw_arrow = true
	await get_tree().create_timer(1.5).timeout
	saw_arrow = false

func _on_inner_detector_entered(_area: Area2D) -> void:
	if saw_arrow:
		dash()

func dash() -> void:
	if not can_dash:
		return
	can_dash = false
	can_jump_attack = false
	can_stab_attack = false
	hurtbox.get_invincible(DASH_DURATION)

	current_speed_multiplier = DASH_SPEED_MULTIPLIER
	
	await get_tree().create_timer(DASH_DURATION).timeout
	
	current_speed_multiplier = 1.0

	can_jump_attack = true
	can_stab_attack = true
	can_dash = true
	can_jump_attack = true
	can_stab_attack = true


# ======================
# VIDA
# ======================
func _on_health_ran_out() -> void:
	queue_free()

func _on_health_lost_health(amount: float) -> void:
	print("Took ", amount, " damage.")

func _on_hurtbox_got_hit_by(hitbox: Hitbox) -> void:
	if hitbox.get_collision_layer_value(9) and !saw_player and !saw_arrow:
		look_for_player()

func _on_guarding_state_entered() -> void:
	current_speed = walk_speed

func _on_chasing_state_entered() -> void:
	current_speed = chase_speed

func _on_fire_manager_caught_fire() -> void:
	var health_man : HealthManager = $WhiteNodes/HealthManager
	var fire_man : FireManager = $FireManager
	if not fire_man.extinguished.is_connected(health_man.stop_burning):
		fire_man.extinguished.connect(health_man.stop_burning, 4)
		health_man.start_burning(0.5)

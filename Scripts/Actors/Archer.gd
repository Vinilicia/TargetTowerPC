extends CharacterBody2D
class_name Player

# ============================================================
# CONSTANTES
# ============================================================
const ARCHER_OFFSET_X := 28
const DEFAULT_MOVE_SPEED := 120.0
const DODGE_KNOCKBACK := 100
const DODGE_VERTICAL_VELOCITY := 0.0

# ============================================================
# EXPORTS E NODES
# ============================================================
@onready var anim: AnimationPlayer = $Archer/AnimationPlayer
@onready var enemy_tracker: RayCast2D = $AimEnemy/EnemyTracker
@onready var aim_enemy: Area2D = $AimEnemy/AimSight

@export var state_chart: StateChart

@export_group("Camera")
@export var camera_distance: float
@export var camera_move_duration: float
@export var camera_remote: RemoteTransform2D

@export_group("Combat")
@export_subgroup("Arrow")
@export_dir var arrow_paths: Array[String]
@export var max_hold_time: float
@export var shoot_delay: float

@export_subgroup("Dodge")
@export var dodge_duration: float = 0.3
@export var dodge_cooldown: float = 0.5
@export var dodge_horizontal_speed: float = 360.0
@export var dodge_up_speed: float = -200.0
@export var dodge_down_speed: float = 520.0
@export var dodge_up_limit: float = 200.0
@export var dodge_cancel_portion:float = 0.1


@export_group("Physics")
@export var jump_force: float
@export var default_knockback: Vector2 = Vector2(170, 0)
@export var gravity_multiplier: float
@export var jump_queuing_time: float
@export var air_stall_velocity: float
@export var coyote_time_timer: float

@export_subgroup("Nodes")
@export var v_component: VelocityComponent
@export var up_col: CollisionShape2D
@export var down_col: CollisionShape2D
@export var hurtbox: Hurtbox
@export var dodge_cancel_timer : Timer
@export var ledge_detector : RayCast2D

@export_category("Para debugar")
@export_range(0, 8) var initial_arrow_index: int

# ============================================================
# VARIÁVEIS AGRUPADAS
# ============================================================
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

var combat := {
	"shoot_direction": Vector2.RIGHT,
	"dodge_direction": Vector2.RIGHT,
	"holding_time": 0.0,
	"is_holding": false,
	"can_shoot": true,
	"update_flying_dir": false,
	"is_dodging": false,
	"can_dodge": true,
	"dodge_cancelled": false,
	"dodge_can_cancel": false
}

var jump_state := {
	"coyote_time": false,
	"jump_queued": false,
	"jumping": false
}

var facing_direction: int = 1
var move_speed : float = DEFAULT_MOVE_SPEED
var current_arrow: Arrow
var current_arrow_index: int
var arrow_spawn_point: Vector2 = Vector2.ZERO
var pos: Vector2
var tween: Tween
var dodged_this_frame: bool = false
var dodge_started_off_ledge: bool = false
var aim_enemy_pos: Vector2
var enemy_target: CharacterBody2D
var enemies_on_target: Array = []

# ============================================================
# READY
# ============================================================
func _ready():
	current_arrow_index = initial_arrow_index
	current_arrow = equip_arrow(current_arrow_index)
	velocity = Vector2.ZERO
	setup_camera()
	UiHandler.equiped_arrow_index = initial_arrow_index
	#Engine.time_scale = 0.5

# ============================================================
# MAIN LOOP
# ============================================================
func _physics_process(delta: float) -> void:
	update_hold_time(delta)
	apply_gravity(delta)
	handle_combat_inputs()
	handle_movement()
	handle_aim_enemy()
	handle_arrow_updates()
	velocity = v_component.get_total_velocity()
	corner_correction(7, delta)
	move_and_slide()
	dodged_this_frame = false

# ============================================================
# INPUT E COMBATE
# ============================================================
func update_hold_time(delta: float) -> void:
	if combat.is_holding:
		combat.holding_time += delta

func handle_combat_inputs() -> void:
	var dir_x : int = facing_direction
	var dir_y : int = 0
	var dodge_dir_y : int = 0 
	var dodge_dir_x : int = 0

	if Input.is_action_pressed("angle up"):
		dir_y = -1
	elif Input.is_action_pressed("angle down"):
		dir_y = 1
	elif Input.is_action_pressed("up"):
		dir_x = 0
		dir_y = -1
		dodge_dir_y = -1
	elif Input.is_action_pressed("down") and !is_on_floor():
		dir_x = 0
		dir_y = 1
		dodge_dir_y = 1
	if Input.is_action_pressed("left"):
		dodge_dir_x = -1
	elif Input.is_action_pressed("right"):
		dodge_dir_x = 1

	if enemy_target and enemy_tracker.get_collider() == enemy_target:
		combat.shoot_direction = aim_enemy_pos.normalized()
	else:
		combat.shoot_direction = Vector2(dir_x, dir_y).normalized()
	combat.dodge_direction = Vector2(dodge_dir_x, dodge_dir_y)
	
	aim_enemy.rotation = Vector2(dir_x, dir_y).normalized().angle()
	
	if Input.is_action_just_released("shoot"):
		combat.is_holding = false
		combat.update_flying_dir = false
	
	if Input.is_action_just_pressed("dodge") and combat.can_dodge:
		combat.can_dodge = false
		dodged_this_frame = true
		try_dodge()
		await get_tree().create_timer(dodge_cooldown).timeout
		combat.can_dodge = true

func try_dodge() -> void:
	var attempt_dodge_dir : Vector2 = combat.dodge_direction
	var dodge_dir : Vector2
	if is_on_floor():
		dodge_dir = Vector2(facing_direction * dodge_horizontal_speed, DODGE_VERTICAL_VELOCITY)
		dodge(dodge_dir, 1)
	else:
		if attempt_dodge_dir.y != 0:
			if attempt_dodge_dir.y == -1:
				var y_speed = v_component.get_proper_velocity(2)
				if y_speed < dodge_up_limit and y_speed > -dodge_up_limit/2:
					dodge_dir = Vector2(0, dodge_up_speed)
				else:
					dodge_dir = Vector2.ZERO
			else:
				dodge_dir = Vector2(0, dodge_down_speed)
			dodge(dodge_dir, 0.6)
		elif attempt_dodge_dir.x != 0:
			dodge_dir = Vector2(facing_direction * dodge_horizontal_speed, DODGE_VERTICAL_VELOCITY)
			dodge(dodge_dir, 1)
		else:
			dodge_dir = Vector2(0, dodge_down_speed)
			dodge(dodge_dir, 0.6)

func dodge(dodge_dir : Vector2, duration_multiplier : float) -> void:
	combat.is_dodging = true
	if dodge_dir.x != 0:
		v_component.set_proper_velocity(Vector2.ZERO)
	elif dodge_dir.y < 0:
		v_component.set_proper_velocity(0.0, 2)
	v_component.add_proper_velocity(dodge_dir)
	hurtbox.get_invincible(dodge_duration * duration_multiplier)
	if duration_multiplier == 1:
		if !is_ledge_ahead():
			dodge_started_off_ledge = true
		dodge_cancel_timer.start(dodge_duration * dodge_cancel_portion)
	await get_tree().create_timer(dodge_duration * duration_multiplier).timeout
	if combat.is_dodging:
		end_dodge()

func end_dodge() -> void:
	combat.is_dodging = false
	combat.dodge_cancelled = false
	combat.dodge_can_cancel = false
	dodge_started_off_ledge = false
	if jump_state.jump_queued and is_on_floor():
		move_speed = dodge_horizontal_speed
		state_chart.find_child("ToGrounded").taken.connect(func() : move_speed = DEFAULT_MOVE_SPEED)
		jump()

func _on_dodge_cancel_timer_timeout() -> void:
	combat.dodge_can_cancel = true

func _on_aim_sight_enemy_entered(enemy: Node2D) -> void:
	enemies_on_target.append(enemy)
	
func _on_aim_sight_enemy_exited(enemy: Node2D) -> void:
	enemies_on_target.erase(enemy)
	
func handle_aim_enemy() -> void:
	var closest: CharacterBody2D = null
	var min_dist: float = INF
	for enemy in enemies_on_target:
		if not is_instance_valid(enemy):
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist < min_dist:
			min_dist = dist
			closest = enemy
	if closest:
		aim_enemy_pos = closest.global_position - global_position
	enemy_tracker.target_position = aim_enemy_pos
	enemy_target = closest

func handle_arrow_updates() -> void:
	if combat.update_flying_dir:
		current_arrow.set_flying_direction(combat.shoot_direction)
		current_arrow.position = arrow_spawn_point

# ============================================================
# MOVIMENTO
# ============================================================
func apply_gravity(delta: float) -> void:
	if !is_on_floor():
		v_component.add_proper_velocity(Vector2(0, get_current_gravity(velocity.y) * delta))
		state_chart.send_event("Falling" if velocity.y >= 0 else "Rising")

func is_ledge_ahead() -> bool:
	return is_on_floor() and !ledge_detector.is_colliding()

func handle_movement() -> void:
	if combat.is_dodging:
		if Input.is_action_pressed("jump") and is_on_floor():
			jump_state.jump_queued = true
		if Input.is_action_just_released("jump"):
			jump_state.jump_queued = false
		
		var dir : int = int(Input.get_axis("left", "right"))
		if is_ledge_ahead() and dir != facing_direction and dodge_started_off_ledge:
			v_component.set_proper_velocity(Vector2.ZERO)
		
		if Input.is_action_just_pressed("dodge") and !dodged_this_frame:
			combat.dodge_cancelled = true
		if combat.dodge_cancelled and combat.dodge_can_cancel:
			end_dodge()
	else:
		if Input.is_action_just_pressed("jump") and (is_on_floor() or jump_state.coyote_time):
			jump()
		
		v_component.set_proper_velocity(0.0, 1)
		var dir: int = int(Input.get_axis("left", "right"))
		if dir:
			if facing_direction != dir:
				facing_direction = dir
				turn(facing_direction)
			move(facing_direction)

# ============================================================
# FUNÇÕES DE AÇÃO
# ============================================================
func jump(multiplier: float = 1) -> void:
	jump_state.jump_queued = false
	v_component.set_proper_velocity(jump_force * multiplier, 2)
	state_chart.send_event("Rising")

func move(facing_dir: int) -> void:
	v_component.add_proper_velocity(Vector2(move_speed * facing_dir, 0))

func equip_arrow(array_position: int) -> Arrow:
	var arrow: Arrow = load(arrow_paths[array_position]).instantiate()
	arrow.position = arrow_spawn_point
	return arrow

func get_current_gravity(velocity_in_y: float) -> float:
	return gravity if velocity_in_y < 0 else gravity * gravity_multiplier

func turn(facing_dir: int) -> void:
	$Archer.scale.x = facing_dir
	$Archer.position.x = -ARCHER_OFFSET_X * facing_dir
	ledge_detector.position.x = 8 * facing_dir
	pos = camera_remote.position
	var final_pos = Vector2(camera_distance * facing_dir, pos.y)
	tween = create_tween().set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera_remote, "position", final_pos, camera_move_duration)
	#aim_enemy.scale.x = facing_dir

func setup_camera() -> void:
	camera_remote.remote_path = get_parent().get_camera().get_path()

func dampen_jump(factor: float) -> void:
	var decel = -(v_component.get_proper_velocity(2) * factor)
	v_component.add_proper_velocity(Vector2(0, decel))

func hold_arrow() -> void:
	combat.update_flying_dir = true
	add_child(current_arrow)
	current_arrow.set_flying_direction(combat.shoot_direction)

func reset_arrow() -> void:
	current_arrow = equip_arrow(current_arrow_index)
	combat.update_flying_dir = false
	combat.holding_time = 0.0

func shoot() -> void:
	combat.is_holding = false
	combat.update_flying_dir = false
	current_arrow.top_level = true
	current_arrow.global_position = global_position + arrow_spawn_point
	current_arrow.fly(combat.holding_time > max_hold_time, self)
	reset_arrow()
	state_chart.send_event("CantShoot")

func air_stall() -> void:
	if v_component.get_proper_velocity(2) > 0:
		v_component.set_proper_velocity(-air_stall_velocity, 2)
	else:
		v_component.add_proper_velocity(Vector2(0, -air_stall_velocity))

func corner_correction(amount: int, delta: float) -> void:
	if !is_on_ceiling() and velocity.y < 0 and test_move(global_transform, Vector2(0, velocity.y * delta)):
		var step := 0.5
		for i in range(1, int(amount / step) + 1):
			var offset_x := i * step * facing_direction
			if !test_move(global_transform.translated(Vector2(offset_x, 0)), Vector2(0, velocity.y * delta)):
				translate(Vector2(offset_x, 0))
				if velocity.x * facing_direction < 0:
					velocity.x = 0
				break

# ============================================================
# ESTADOS (mantidos com nomes originais)
# ============================================================
#region ESTADOS
func _rising_to_falling_taken() -> void:
	anim.clear_queue()
	anim.play("Jump Apex")

func _falling_state_entered() -> void:
	anim.queue("Start Fall")
	anim.queue("Fall")

func _grounded_to_falling_taken() -> void:
	anim.stop()
	jump_state.coyote_time = true
	await get_tree().create_timer(coyote_time_timer).timeout
	jump_state.coyote_time = false

func _falling_to_grounded_taken() -> void:
	anim.play("Landing")
	

func _grounded_physics_processing(_delta: float) -> void:
	if velocity.x == 0:
		if anim.current_animation != "Idle":
			anim.play("Idle")
	else:
		if anim.current_animation != "Run":
			anim.play("Run Start")
			anim.queue("Run")

func _rising_state_entered() -> void:
	jump_state.jumping = true
	anim.clear_queue()
	anim.play("Jump")

func _rising_physics_processing(_delta: float) -> void:
	if !Input.is_action_pressed("jump") and jump_state.jumping:
		jump_state.jumping = false
		dampen_jump(0.75)
	if is_on_ceiling():
		dampen_jump(0.5)

func _can_shoot_state_entered() -> void:
	if combat.is_holding:
		combat.is_holding = false
		hold_arrow()

func _can_shoot_physics_processing(_delta: float) -> void:
	if Input.is_action_just_released("shoot"):
		shoot()
	if Input.is_action_just_pressed("shoot"):
		hold_arrow()
		shoot()

func _cannot_shoot_state_entered() -> void:
	await get_tree().create_timer(shoot_delay).timeout
	state_chart.send_event("CanShoot")

func _cant_shoot_physics_processing(_delta: float) -> void:
	if Input.is_action_pressed("shoot"):
		combat.is_holding = true

func _on_health_lost_health(_amount: float) -> void:
	print("OUCH!!!")
	modulate = Color(1, 0, 0, 1)
	await get_tree().create_timer(0.3).timeout
	modulate = Color(1, 1, 1, 1)

func _falling_state_processing(_delta: float) -> void:
	if is_on_floor():
		state_chart.send_event("Grounded")
	if Input.is_action_just_pressed("jump"):
		jump_state.jump_queued = true
		await get_tree().create_timer(jump_queuing_time).timeout
		jump_state.jump_queued = false

func _grounded_state_entered() -> void:
	
	if jump_state.jump_queued:
		jump()
	else:
		v_component.set_proper_velocity(0.0, 2)

func _standing_physics_processing(_delta: float) -> void:
	if Input.is_action_pressed("down") and velocity.x == 0:
		state_chart.set_expression_property("crouching", true)
		state_chart.send_event("Crouched")

func crouch():
	move_speed = 0
	up_col.disabled = true
	arrow_spawn_point = Vector2(0, 4)

func _crouched_entered() -> void:
	crouch()

func _crouched_physics_processing(_delta: float) -> void:
	if Input.is_action_just_released("down"):
		state_chart.send_event("Standing")

func stand() -> void:
	move_speed = DEFAULT_MOVE_SPEED
	up_col.disabled = false
	arrow_spawn_point = Vector2.ZERO

func _crouched_exited() -> void:
	stand()

func _standing_entered() -> void:
	state_chart.set_expression_property("crouching", false)

#endregion

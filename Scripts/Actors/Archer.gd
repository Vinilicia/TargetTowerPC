extends CharacterBody2D
class_name Player

# ============================================================
# CONSTANTES
# ============================================================
const ARCHER_OFFSET_X := 24
const DEFAULT_MOVE_SPEED := 120.0
const DODGE_KNOCKBACK := 100
const DODGE_VERTICAL_VELOCITY := 0.0
const SAFE_POSITION_CHECK_FRAME_DELAY : int = 30

# ============================================================
# EXPORTS E NODES
# ============================================================
@onready var anim: AnimationPlayer = $Archer/AnimationPlayer
@onready var enemy_tracker: RayCast2D = $Utilities/AimEnemy/EnemyTracker
@onready var aim_enemy: Area2D = $Utilities/AimEnemy/AimSight

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
@export var max_mana : int
@export var mana_regen_time : float = 1.0
@export var mana_regen_scaling : float = 0.7

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
@export var max_fall_speed : float = 300

@export_group("Nodes")
@export var v_component: VelocityComponent
@export var hurtbox: Hurtbox
@export var dodge_cancel_timer : Timer
@export var ledge_detector : RayCast2D
@export var wall_detector : RayCast2D
@export var health_manager : HealthManager
@export var mana_timer : Timer

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
var direction: int = 1
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
var enemies_on_sight: Array = []
var last_safe_position : Vector2
var frames_until_check : int = 0
var locked_walk: bool = false
var available_arrows: Array[bool] = [true, true, true, true, false, false, false, false, false]
var arrows : Array[Arrow] = []
var in_control : bool = true
@onready var current_mana : int = max_mana

# ============================================================
# READY
# ============================================================
func _ready():
	build_arrows()
	current_arrow_index = initial_arrow_index
	current_arrow = equip_arrow(current_arrow_index)
	velocity = Vector2.ZERO
	#await get_tree().process_frame
	await HudHandler.hud.ready
	HudHandler.hud.init_hearts(($Misc/HealthManager as HealthManager).max_health as int)
	HudHandler.hud.init_mana(max_mana)
	HudHandler.hud.change_arrow(current_arrow_index)
	
	mana_timer.wait_time = mana_regen_time
	#Engine.time_scale = 0.5

func build_arrows() -> void:
	if current_arrow and current_arrow.is_inside_tree():
		current_arrow.queue_free()
	arrows = []
	for i in range(arrow_paths.size()):
		if available_arrows[i]:
			var new_arrow : Arrow = load(arrow_paths[i]).instantiate()
			arrows.append(new_arrow)
	reset_arrow()

# ============================================================
# MAIN LOOP
# ============================================================
func _physics_process(delta: float) -> void:
	update_hold_time(delta)
	apply_gravity(delta)
	handle_combat_inputs()
	handle_arrow_updates()
	if in_control:
		handle_aim_enemy()
		handle_movement()
	velocity = v_component.get_total_velocity()
	corner_correction(7, delta)
	move_and_slide()
	update_safe_position()
	dodged_this_frame = false

func update_safe_position() -> void:
	if frames_until_check > 0:
		frames_until_check -= 1
		return

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)

		if collision.get_normal().y < -0.7:
			var floor_collider = collision.get_collider()

			if floor_collider is TileMap:
				last_safe_position = global_position
				frames_until_check = SAFE_POSITION_CHECK_FRAME_DELAY
		break

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
	
	if in_control:
		if Input.is_action_just_pressed("dodge") and combat.can_dodge:
			combat.can_dodge = false
			dodged_this_frame = true
			try_dodge()
			await get_tree().create_timer(dodge_cooldown).timeout
			combat.can_dodge = true
		
		if Input.is_action_just_pressed("switch arrow"):
			current_arrow_index = (current_arrow_index + 1) % arrows.size()
			if current_arrow.is_inside_tree():
				shoot()
			else:
				current_arrow = equip_arrow(current_arrow_index)
			HudHandler.hud.change_arrow(current_arrow_index)

func try_dodge() -> void:
	var attempt_dodge_dir : Vector2 = combat.dodge_direction
	var dodge_dir : Vector2
	if is_on_floor():
		dodge_dir = Vector2(direction * dodge_horizontal_speed, DODGE_VERTICAL_VELOCITY)
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
			dodge_dir = Vector2(direction * dodge_horizontal_speed, DODGE_VERTICAL_VELOCITY)
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
		play_anim("FrontDodge")
		if !is_ledge_ahead():
			dodge_started_off_ledge = true
		dodge_cancel_timer.start(dodge_duration * dodge_cancel_portion)
	elif dodge_dir.y < 0:
		play_anim("UpDodge")
	else:
		play_anim("DownDodge")
	await get_tree().create_timer(dodge_duration * duration_multiplier).timeout
	if combat.is_dodging:
		end_dodge()

func end_dodge() -> void:
	combat.is_dodging = false
	combat.dodge_cancelled = false
	combat.dodge_can_cancel = false
	dodge_started_off_ledge = false
	if jump_state.jump_queued and is_on_floor():
		var dir = int(Input.get_axis("left", "right"))
		if dir == facing_direction and !is_wall_ahead():
			move_speed = dodge_horizontal_speed
			$Misc/StateChart/Root/Memes/Grounded.state_entered.connect(reset_speed, 4)
		jump()
	jump_state.jump_queued = false

func reset_speed() -> void:
	move_speed = DEFAULT_MOVE_SPEED

func _on_dodge_cancel_timer_timeout() -> void:
	combat.dodge_can_cancel = true

func _on_aim_sight_enemy_entered(enemy: Node2D) -> void:
	enemies_on_sight.append(enemy)
	
func _on_aim_sight_enemy_exited(enemy: Node2D) -> void:
	enemies_on_sight.erase(enemy)
	
func handle_aim_enemy() -> void:
	var closest: CharacterBody2D = null
	var min_dist: float = INF
	for enemy in enemies_on_sight:
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
		if v_component.get_proper_velocity(2) <= max_fall_speed:
			v_component.add_proper_velocity(Vector2(0, get_current_gravity(velocity.y) * delta))
		state_chart.send_event("Falling" if velocity.y >= 0 else "Rising")

func is_ledge_ahead() -> bool:
	return is_on_floor() and !ledge_detector.is_colliding()

func is_wall_ahead() -> bool:
	var response := is_on_floor() and wall_detector.is_colliding()
	return response

func handle_movement() -> void:
	if Input.is_action_just_pressed("lock walk") and in_control:
		if locked_walk:
			move_speed = DEFAULT_MOVE_SPEED
		locked_walk = not locked_walk
		
	if combat.is_dodging and in_control:
		if Input.is_action_just_pressed("jump") and is_on_floor():
			jump_state.jump_queued = true
		if Input.is_action_just_released("jump"):
			jump_state.jump_queued = false
		
		if is_ledge_ahead():
			if jump_state.jump_queued or dodge_started_off_ledge:
				end_dodge()
		
		if Input.is_action_just_pressed("dodge") and !dodged_this_frame:
			combat.dodge_cancelled = true
		if combat.dodge_cancelled and combat.dodge_can_cancel:
			end_dodge()
	else:
		if Input.is_action_just_pressed("jump") and (is_on_floor() or jump_state.coyote_time) and in_control and !Input.is_action_pressed("down"):
			if is_on_floor():
				jump()
			elif jump_state.coyote_time:
				jump(1, true)
		
		var dir: int = int(Input.get_axis("left", "right")) if in_control else 0
		if dir:
			if direction != dir:
				direction = dir
				if not locked_walk:
					facing_direction = direction
					turn(facing_direction)
			if dir != facing_direction:
				move_speed = DEFAULT_MOVE_SPEED * 0.7
			elif move_speed < DEFAULT_MOVE_SPEED:
				move_speed = DEFAULT_MOVE_SPEED
			move(direction)
		else:
			v_component.set_proper_velocity(0.0, 1)

# ============================================================
# FUNÇÕES DE AÇÃO
# ============================================================
func jump(multiplier: float = 1, coyote : bool = false) -> void:
	AudioManager.play_song("PlayerJump")
	jump_state.jump_queued = false
	jump_state.jumping = true
	anim.clear_queue()
	if not coyote:
		play_anim("Jump")
		play_anim("Rise", true)
	else:
		play_anim("Rise")
	await get_tree().create_timer(0.08).timeout
	v_component.set_proper_velocity(jump_force * multiplier, 2)

func move(facing_dir: int) -> void:
	var current_h_speed = v_component.get_proper_velocity(1)
	var starting : bool = abs(current_h_speed) < 45
	var horizontal_velocity = lerp(current_h_speed, facing_dir * move_speed, 0.1 if starting else 1.0)
	v_component.set_proper_velocity(horizontal_velocity, 1)

func equip_arrow(array_position: int) -> Arrow:
	var arrow: Arrow = arrows[array_position].duplicate()
	arrow.position = arrow_spawn_point
	current_arrow_index = array_position
	return arrow

func get_current_gravity(velocity_in_y: float) -> float:
	return gravity * 0.8 if velocity_in_y < 0 else gravity * gravity_multiplier

func turn(facing_dir: int) -> void:
	$Archer.scale.x = facing_dir
	$Archer.position.x = -ARCHER_OFFSET_X * facing_dir
	ledge_detector.position.x = 8 * facing_dir
	wall_detector.scale.x = facing_dir
	pos = camera_remote.position
	var final_pos = Vector2(camera_distance * facing_dir, pos.y)
	tween = create_tween().set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera_remote, "position", final_pos, camera_move_duration)

func dampen_jump(factor: float) -> void:
	var decel = -(v_component.get_proper_velocity(2) * factor)
	v_component.add_proper_velocity(Vector2(0, decel))

func hold_arrow() -> void:
	combat.update_flying_dir = true
	current_arrow.setup_hitbox(self)
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
	lose_mana(current_arrow.Cost)

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
	play_anim("Apex")
	play_anim("Fall", true)

func _grounded_to_falling_taken() -> void:
	jump_state.coyote_time = true
	await get_tree().create_timer(coyote_time_timer).timeout
	jump_state.coyote_time = false
	if anim.current_animation != "Rise" and anim.current_animation != "Jump":
		anim.clear_queue()
		play_anim("Fall")

func _falling_to_grounded_taken() -> void:
	anim.clear_queue()
	play_anim("Land")

func _grounded_physics_processing(_delta: float) -> void:
	if anim.current_animation != "Land" and anim.current_animation != "Jump" and anim.current_animation != "FrontDodge":
		if v_component.get_proper_velocity().x == 0:
			if AudioManager.is_playing("Footsteps"):
				AudioManager.stop("Footsteps")
			if is_zero_approx(move_speed):
				if anim.current_animation != "Crouch":
					play_anim("Crouch")	
			elif anim.current_animation != "Idle":
				play_anim("Idle")
		else:
			if !AudioManager.is_playing("Footsteps"):
				AudioManager.play_song("Footsteps")
			if sign(v_component.get_proper_velocity().x) != facing_direction:
				if anim.current_animation != "RunBackwards":
					play_anim("RunBackwards") 
			elif anim.current_animation != "RunLoop" and anim.current_animation != "Run":
				play_anim("Run")
				play_anim("RunLoop", true)

func _rising_state_entered() -> void:
	anim.clear_queue()
	anim.queue("Rise")

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
	if Input.is_action_just_released("shoot") and current_mana >= current_arrow.Cost:
		shoot()
	if Input.is_action_just_pressed("shoot") and current_mana >= current_arrow.Cost:
		hold_arrow()
		shoot()

func heal_hp_on_bench() -> void:
	health_manager.gain_health(health_manager.max_health)

func heal_mana_on_bench() -> void:
	gain_mana(max_mana)

func gain_mana(amount : int) -> void:
	var true_amount : int = min(amount, max_mana - current_mana)
	current_mana += true_amount
	HudHandler.hud.gain_mana(true_amount)

func lose_mana(amount : int) -> void:
	var true_amount : int = min(current_mana, amount)
	current_mana -= true_amount
	HudHandler.hud.lose_mana(true_amount)
	if amount > 0:
		mana_timer.start(mana_regen_time * ( 1.5 if current_mana == 0 else 1.0))

func _cannot_shoot_state_entered() -> void:
	await get_tree().create_timer(shoot_delay).timeout
	state_chart.send_event("CanShoot")

func _cant_shoot_physics_processing(_delta: float) -> void:
	if Input.is_action_pressed("shoot"):
		combat.is_holding = true

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
	play_anim("Crouch")
	move_speed = 0
	$UpColl.disabled = true
	hurtbox.scale.y /= 1.5
	hurtbox.position.y += hurtbox.scale.y / 2
	hurtbox.position.x += 1
	hurtbox.scale.x += 2
	arrow_spawn_point = Vector2(0, 4)
	$Utilities/FireManager.update_hurtbox()

func _crouched_entered() -> void:
	crouch()

func _crouched_physics_processing(_delta: float) -> void:
	if Input.is_action_just_released("down"):
		state_chart.send_event("Standing")

func stand() -> void:
	play_anim("Idle")
	move_speed = DEFAULT_MOVE_SPEED
	$UpColl.disabled = false
	hurtbox.position.y -= hurtbox.scale.y / 2
	hurtbox.position.x -= 1
	hurtbox.scale.y *= 1.5
	hurtbox.scale.x -= 2
	arrow_spawn_point = Vector2.ZERO
	$Utilities/FireManager.update_hurtbox()

func _crouched_exited() -> void:
	stand()

func _standing_entered() -> void:
	state_chart.set_expression_property("crouching", false)

func play_anim(animation_name: String, queue: bool = false, blend: float = -1.0) -> void:
	if queue:
		if anim.current_animation == "Hurt":
			await anim.animation_finished
		anim.queue(animation_name)
	else:
		if anim.current_animation != "Hurt":
			anim.play(animation_name, blend)

#endregion

func set_available_arrows(available_arrows_loaded: Array[bool]):
	available_arrows = available_arrows_loaded

func wake_up(use_save : bool = true):
	if use_save:
		set_available_arrows(SaveManager.save_file_data.get_available_arrows())
	else:
		pass

func _on_fire_manager_caught_fire() -> void:
	var fire_man : FireManager = $Utilities/FireManager
	if not fire_man.extinguished.is_connected(health_manager.stop_burning):
		fire_man.extinguished.connect(health_manager.stop_burning, 4)
		health_manager.start_burning(1)

func _on_health_lost_health(amount: float) -> void:
	AudioManager.play_song("PlayerHit")
	HudHandler.hud.lose_hearts(amount as int)
	modulate = Color(1, 0, 0, 1)
	anim.clear_queue()
	in_control = false
	v_component.add_knockback_velocity(Vector2(default_knockback.x * -facing_direction, default_knockback.y))
	v_component.set_proper_velocity(0.0, 2)
	current_arrow.queue_free()
	reset_arrow()
	state_chart.send_event("CantShoot")
	play_anim("Hurt")
	await anim.animation_finished
	in_control = true
	var invisibility_time = hurtbox.invincibility_time
	var time_passed = 0
	while time_passed < invisibility_time:
		var mod_tween: Tween = create_tween()
		mod_tween.tween_property(self, "modulate", Color(1, 1, 1, 0.39), 0.15)
		mod_tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.15)
		await get_tree().create_timer(0.3).timeout
		time_passed += 0.3

func _on_health_manager_ran_out() -> void:
	get_tree().quit()

func _on_health_manager_gained_health(amount: int) -> void:
	HudHandler.hud.gain_hearts(amount as int)

func gain_control() -> void:
	in_control = true

func lose_control() -> void:
	in_control = false

func _on_mana_regen_timer_timeout() -> void:
	gain_mana(1)
	if current_mana < max_mana:
		mana_timer.start(mana_timer.wait_time * mana_regen_scaling)
	else:
		mana_timer.wait_time = mana_regen_time

func _on_grounded_state_exited() -> void:
	if AudioManager.is_playing("Footsteps"):
		AudioManager.stop("Footsteps")

func unlock_arrow(arrow_index : int) -> void:
	if arrow_index < available_arrows.size():
		available_arrows[arrow_index] = true

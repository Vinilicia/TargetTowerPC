extends CharacterBody2D
class_name Player

signal mana_changed(value : int)
signal took_damage

@export_group("Nodes")
@export var v_comp : VelocityComponent
@export var mana_timer : Timer
@export var sprite : Sprite2D
@export var melee_area : Area2D
@export var stomp_area : Area2D
@export var melee_hitbox : Hitbox
@export var stomp_hitbox : Hitbox
@export var anim_handler : Anim_Handler
@export var hurtbox : Hurtbox
@export var wall_detec : RayCast2D
@export var ledge_detec : RayCast2D

@export_group("Variant values")
@export_subgroup("Movement")
@export var jump_force : float = 300.0
@export var move_speed : float = 120.0
@export var coyote_time_duration : float = 0.08
@export var jump_buffer_duration : float = 0.08
@export var rise_multiplier : float = 0.75
@export_subgroup("Attacks")
@export_dir var arrow_paths: Array[String]
@export var arrow_cooldown : float = 0.5
@export var mana_regen_time : float = 1.0
@export_subgroup("Dodge")
@export var dodge_duration: float = 0.25
@export var dodge_cooldown: float = 0.5
@export var dodge_side_speed: float = 360.0
@export var dodge_up_speed: float = 200.0
@export var dodge_down_speed: float = 560.0
@export var dodge_up_limit: float = 200.0

enum TERRAIN_STATE { Grounded, Airbone }
enum ANIM_STATE { Grounded, Airbone, Hurt, Attack, Dodge}

# ------------------------------ MOVEMENT ------------------------------ 
var terrain_state : TERRAIN_STATE = TERRAIN_STATE.Grounded
var anim_state : ANIM_STATE = ANIM_STATE.Grounded
var coyote_time : bool = false
var jump_buffer : bool = false
var can_dodge: bool = true
var facing_direction : int = 1
var dodge_direction: Vector2 = Vector2.RIGHT
var in_control : bool = true
var crouching : bool = false
var dodging : bool = false

# ------------------------------ COMBAT ------------------------------ #
var arrows : Array[Arrow] = []
var current_arrow : Arrow
var arrow_index : int
var arrow_position : Vector2
var holding_arrow : bool = false
var holding_time: float = 0.0
var can_shoot : bool = true
var shoot_direction: Vector2 = Vector2.UP
var update_arrow_dir: bool = false
var max_mana : int = 6
var mana : int = 5

func _physics_process(delta: float) -> void:
	if in_control:
		movement_inputs()
		direction_inputs()
		combat_inputs()
	handle_terrain_state(delta)
	if is_on_floor():
		if terrain_state != TERRAIN_STATE.Grounded:
			terrain_state = TERRAIN_STATE.Grounded
			grounded_entered()
	else:
		if terrain_state != TERRAIN_STATE.Airbone:
			terrain_state = TERRAIN_STATE.Airbone
			airbone_entered()
	velocity = v_comp.get_total_velocity()
	move_and_slide()

func _ready() -> void:
	build_arrows()

func equip_arrow() -> Arrow:
	var arrow: Arrow = arrows[arrow_index].duplicate()
	arrow.position = arrow_position
	return arrow

func reset_arrow() -> void:
	current_arrow = equip_arrow()
	update_arrow_dir = false
	holding_time = 0.0

func build_arrows() -> void:
	if current_arrow and current_arrow.is_inside_tree():
		current_arrow.queue_free()
	arrows = []
	#var available_arrows := SaveManager.save_file_data.get_available_arrows()
	var available_arrows := [true, true, true, true, true, false]
	for i in range(arrow_paths.size()):
		if available_arrows[i]:
			var new_arrow : Arrow = load(arrow_paths[i]).instantiate()
			arrows.append(new_arrow)
	reset_arrow()

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

func airbone_entered() -> void:
	coyote_time = true
	get_tree().create_timer(coyote_time_duration).timeout.connect(func():
		coyote_time = false)
	anim_handler.change_state(Anim_Handler.ANIM_STATE.Airbone)

func grounded_entered() -> void:
	if jump_buffer:
		jump_buffer = false
		if crouching:
			slide()
		else:
			jump()
	else:
		v_comp.set_proper_velocity(0.0, 2)
	anim_handler.change_state(Anim_Handler.ANIM_STATE.Grounded)

func airbone_process(delta : float) -> void:
	v_comp.add_proper_velocity(Vector2.DOWN * get_current_gravity() * delta)
	corner_correction(7, delta)
	if is_on_ceiling():
		v_comp.add_proper_velocity(abs(v_comp.get_proper_velocity(2) * 0.4) * Vector2.DOWN)

func grounded_process(_delta: float) -> void:
	pass

func turn() -> void:
	facing_direction *= -1
	$Utilities.scale.x = facing_direction

func shorten_hitbox() -> void:
	$UpColl.disabled = true
	hurtbox.scale.y /= 1.5
	hurtbox.position.y += hurtbox.scale.y / 2
	hurtbox.position.x += 1
	hurtbox.scale.x += 2
	$Utilities/FireManager.update_hurtbox()

func crouch():
	anim_handler.crouched()
	crouching = true
	shorten_hitbox()
	arrow_position = Vector2(0, 4)

func increase_hitbox() -> void:
	$UpColl.disabled = false
	hurtbox.position.y -= hurtbox.scale.y / 2
	hurtbox.position.x -= 1
	hurtbox.scale.y *= 1.5
	hurtbox.scale.x -= 2
	$Utilities/FireManager.update_hurtbox()

func stand() -> void:
	anim_handler.stood()
	crouching = false
	increase_hitbox()
	arrow_position = Vector2.ZERO

func movement_inputs() -> void:
	var dir : int = int(Input.get_axis("left", "right"))
	if dir and !crouching:
		var x_vel : float = v_comp.get_proper_velocity(1)
		x_vel = lerp(x_vel, dir * move_speed, 0.3) 
		v_comp.set_proper_velocity(x_vel, 1)
		if dir != facing_direction:
			turn()
	else:
		v_comp.set_proper_velocity(0.0, 1)
		if Input.is_action_pressed("down") and !crouching and is_on_floor():
			crouch()
	if Input.is_action_just_released("down") and crouching:
		stand()
	
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			if crouching:
				slide()
			else:
				jump()
		else:
			if stomp_area.has_overlapping_areas():
				stomp_hitbox.monitorable = true
				get_tree().create_timer(0.1).timeout.connect(func(): 
					stomp_hitbox.monitorable = false
					)
				jump()
			if coyote_time:
				jump()
			if !jump_buffer:
				jump_buffer = true
				get_tree().create_timer(jump_buffer_duration).timeout.connect(func():
					jump_buffer = false)
	
	if Input.is_action_just_released("jump") and v_comp.get_proper_velocity(2) < 0.0:
		v_comp.set_proper_velocity(-10.0, 2)
	
	if Input.is_action_just_pressed("dodge") and can_dodge:
		dodge()

func slide() -> void:
	pass

func handle_terrain_state(delta: float) -> void:
	match terrain_state:
		TERRAIN_STATE.Grounded:
			grounded_process(delta)
		TERRAIN_STATE.Airbone:
			airbone_process(delta)

func combat_inputs() -> void:
	if holding_arrow:
		if !current_arrow.is_inside_tree():
			push_error("FLECHA NAO ESTAVA NA ARVORE MAS HOLDING_ARROW ERA TRUE")
			return
		current_arrow.scale.x = scale.x
		#print(scale.x)
		current_arrow.set_flying_direction(shoot_direction)
	
	if Input.is_action_just_pressed("shoot"):
		if not melee_area.has_overlapping_areas():
			if hold_arrow():
				call_deferred("shoot")
		else:
			melee_hitbox.monitorable = true
			get_tree().create_timer(0.2).timeout.connect(func() :
				melee_hitbox.monitorable = false
				)
	
	if Input.is_action_just_released("shoot") and holding_arrow:
		shoot()
	
	if Input.is_action_just_pressed("switch arrow"):
			arrow_index = (arrow_index + 1) % arrows.size()
			if current_arrow.is_inside_tree():
				shoot()
			else:
				current_arrow = equip_arrow()
			HudHandler.hud.change_arrow(arrow_index)

func calculate_dodge_vector() -> Vector2:
	var dodge_vec : Vector2 = Vector2.ZERO
	if dodge_direction.x != 0:
		dodge_vec = dodge_direction * dodge_side_speed
	else:
		if dodge_direction.y > 0:
			dodge_vec = dodge_direction * dodge_down_speed
		else:
			dodge_vec = dodge_direction * dodge_up_speed 
	return dodge_vec

func dodge() -> void:
	dodging = true
	in_control = false
	var dodge_vec := calculate_dodge_vector()
	if dodge_vec.x != 0:
		v_comp.set_proper_velocity(Vector2.ZERO)
		shorten_hitbox()
	elif dodge_vec.y < 0:
		if abs(v_comp.get_proper_velocity(2)) < dodge_up_limit:
			v_comp.set_proper_velocity(0.0, 2)
		else:
			dodge_vec = Vector2.ZERO
	v_comp.add_proper_velocity(dodge_vec)
	modulate = Color(1, 1, 1, 0.6)
	can_dodge = false
	var actual_duration := dodge_duration if dodge_vec.x != 0 else (dodge_duration * 0.6)
	var can_jump_at_end : bool = (dodge_vec.x != 0)
	hurtbox.get_invincible_for(dodge_duration)
	get_tree().create_timer(actual_duration).timeout.connect(end_dodge_check.bind(can_jump_at_end, sign(dodge_vec.x)))
	get_tree().process_frame.connect(dodge_process.bind(can_jump_at_end, sign(dodge_vec.x)))

func end_dodge_check(can_jump_at_end : bool, start_direction : int) -> void:
	if !end_dodge():
		return
	if can_jump_at_end and Input.is_action_pressed("jump") and is_on_floor():
		jump()
		get_tree().process_frame.connect(reset_speed.bind(move_speed, start_direction))
		move_speed *= 2
	if get_tree().process_frame.is_connected(dodge_process):
		get_tree().process_frame.disconnect(dodge_process)

func dodge_process(can_jump_at_end : bool, start_direction : int) -> void:
	if is_on_floor() and !ledge_detec.is_colliding():
		end_dodge_check(can_jump_at_end, start_direction)

func reset_speed(speed_to_reset : float, start_direction : int) -> void:
	if is_on_floor() or sign(v_comp.get_proper_velocity(1)) != sign(start_direction) or wall_detec.is_colliding():
		move_speed = speed_to_reset
		get_tree().process_frame.disconnect(reset_speed)

func end_dodge() -> bool:
	var dodge_ended := dodging;
	if dodging:
		in_control = true
		dodging = false
		modulate = Color(1, 1, 1, 1)
		if $UpColl.disabled:
			increase_hitbox()
		get_tree().create_timer(dodge_cooldown).timeout.connect(func():
			can_dodge = true
			)
	return dodge_ended

func hold_arrow() -> bool:
	if can_shoot:
		if mana >= current_arrow.Cost:
			holding_arrow = true
			current_arrow.call_deferred("set_flying_direction", shoot_direction)
			current_arrow.setup_hitbox(self)
			call_deferred("add_child", current_arrow)
			can_shoot = false
			return true
	return false

func shoot() -> void:
	holding_arrow = false
	current_arrow.reparent(get_parent())
	current_arrow.call_deferred("fly", false, self)
	mana -= current_arrow.Cost
	mana_changed.emit(-1 * current_arrow.Cost)
	reset_arrow()
	get_tree().create_timer(arrow_cooldown).timeout.connect(arrow_cooldown_end)

func arrow_cooldown_end() -> void:
	can_shoot = true
	if Input.is_action_pressed("shoot"):
		hold_arrow()

func direction_inputs() -> void:
	var dir_x : int = facing_direction
	var dir_y : int = 0
	var dodge_dir_y : int = 0 
	var dodge_dir_x : int = facing_direction

	if Input.is_action_pressed("angle up"):
		dir_y = -1
	if Input.is_action_pressed("angle down"):
		dir_y = 1
	if Input.is_action_pressed("up"):
		dir_x = 0
		dir_y = -1
		if !is_on_floor():
			dodge_dir_y = -1
			dodge_dir_x = 0
	if Input.is_action_pressed("down") and !is_on_floor():
		dir_x = 0
		dir_y = 1
		dodge_dir_y = 1
		dodge_dir_x = 0
	if Input.is_action_pressed("left"):
		if is_on_floor():
			dodge_dir_x = -1
			dodge_dir_y = 0
	elif Input.is_action_pressed("right"):
		if is_on_floor():
			dodge_dir_x = 1
			dodge_dir_y = 0
	shoot_direction = Vector2(dir_x, dir_y).normalized()
	dodge_direction = Vector2(dodge_dir_x, dodge_dir_y)

func jump() -> void:
	v_comp.set_proper_velocity(jump_force * Vector2.UP)

func get_current_gravity() -> Vector2:
	var y_vel : float = v_comp.get_proper_velocity(2)
	if y_vel >= 0.0:
		if y_vel > 400.0:
			return get_gravity() * 0.01
		return get_gravity()
	return get_gravity() * rise_multiplier

func _on_mana_changed(value : int) -> void:
	if value < 0:
		mana_timer.start(mana_regen_time)
	if value > 0:
		if Input.is_action_pressed("shoot"):
			hold_arrow()

func _on_mana_regen_timer_timeout() -> void:
	mana += 1
	mana_changed.emit(1)
	if mana < max_mana:
		mana_timer.start(mana_regen_time)

var default_knockback : Vector2 = Vector2(170, 0)

func flinch() -> void:
	in_control = false
	v_comp.set_proper_velocity(Vector2.ZERO)
	v_comp.add_knockback_velocity(Vector2(default_knockback.x * -facing_direction, default_knockback.y))
	current_arrow.queue_free()
	reset_arrow()
	can_shoot = false
	modulate = Color(1, 0, 0, 1)
	await get_tree().create_timer(0.25).timeout
	modulate = Color(1, 1, 1, 1)
	hurtbox.get_invincible()
	arrow_cooldown_end()
	in_control = true
	invincible_flicker()

func invincible_flicker() -> void:
	var mod_tween: Tween = create_tween()
	mod_tween.tween_property(self, "modulate", Color(1, 1, 1, 0.4), 0.15)
	mod_tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.15)
	await get_tree().create_timer(0.3).timeout
	if hurtbox.is_invincible:
		invincible_flicker()

func _on_health_manager_lost_health(amount: int) -> void:
	if amount > 0:
		took_damage.emit()
		flinch()

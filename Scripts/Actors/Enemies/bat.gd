extends Enemy

@onready var state_chart = $StateChart as StateChart

@export_subgroup("Timers")
@export var chasing_timer: Timer
@export var giving_up_timer: Timer
@export_subgroup("Raycasts")
@export var line_of_sight: RayCast2D
@export var ceiling_detector: RayCast2D
@export var avoidance_rays : Array[RayCast2D]
@export_subgroup("Areas")
@export var dash_area: Area2D
@export var dive_area: Area2D
@export var sight_area: Area2D
@export var contact_hitbox: Hitbox

# Configuração de comportamento
@export_group("Behavior")
@export var backtracking_speed: float
@export var chase_flying_speed: float
@export var starting_give_up_delay: float
@export var chasing_give_up_delay: float
@export var dash_speed: float
@export var dash_distance: float
@export var dash_delay: float
@export var attack_reaction_delay :float
@export var dash_hitbox_increase: float

# Ajustes de chasing
@export_group("Chase Tuning")
@export var chase_retarget_frames: int = 5
@export var facing_flip_deadzone: float = 2.0
@export var wander_strength : float = 15.0

# Estado atual
var current_speed: float
var facing_direction: int = 1
var moving: bool = false
var saw_player: bool = false
var player_is_nearby: bool = false
var player_in_attack_area: bool = false
var player_target: CharacterBody2D
var chasing_target_position: Vector2
var move_timer: Timer

# Movimento novo
var desired_velocity: Vector2 = Vector2.ZERO
var current_to_do: Callable = func(): pass
var auto_face: bool = true

# Controle interno
var give_up_time: float
var remaining_time_for_chase: float = -1
var _chase_frame_accum: int = 0
var stopping_tween: Tween
var current_attack: Callable = func(): pass
var current_attack_type: String = ""
var ceiling_retry_timer: Timer
var attack_delay_timer : Timer

@onready var sprite_anim : AnimationPlayer = $Bat/AnimationPlayer

#region Built-In
func _ready() -> void:
	ceiling_retry_timer = Timer.new()
	ceiling_retry_timer.one_shot = true
	ceiling_retry_timer.wait_time = 8.0
	ceiling_retry_timer.timeout.connect(_on_ceiling_retry_timeout)
	add_child(ceiling_retry_timer)
	
	attack_delay_timer = Timer.new()
	attack_delay_timer.one_shot = true
	add_child(attack_delay_timer)
	attack_delay_timer.timeout.connect(_on_attack_delay_timeout)

	move_timer = Timer.new()
	move_timer.one_shot = true
	add_child(move_timer)

func _physics_process(_delta: float) -> void:
	_update_facing_direction()
	_update_line_of_sight()

	# Suaviza o movimento (inércia)
	var current_v : Vector2 = v_component.get_proper_velocity()
	var lerped : Vector2 = current_v.lerp(desired_velocity, 0.15)
	v_component.set_proper_velocity(lerped)

	velocity = v_component.get_total_velocity()
	move_and_slide()
#endregion

#region Movimento baseado em tempo e velocidade
func move_for(duration: float, direction: Vector2, speed: float, todo: Callable = func(): pass) -> void:
	if stopping_tween and stopping_tween.is_running():
		stopping_tween.kill()
	if move_timer.is_connected("timeout", Callable(self, "_on_move_timeout")):
		move_timer.timeout.disconnect(Callable(self, "_on_move_timeout"))

	current_to_do = todo
	moving = true
	desired_velocity = direction.normalized() * speed

	move_timer.wait_time = duration
	move_timer.timeout.connect(_on_move_timeout)
	move_timer.start()

func _on_move_timeout() -> void:
	moving = false
	stop(0.1)
	current_to_do.call()
#endregion

#region Utilitárias
func stop(duration: float) -> void:
	stopping_tween = create_tween()
	stopping_tween.tween_property(v_component, "proper_velocity", Vector2.ZERO, duration).set_ease(Tween.EASE_IN)
	desired_velocity = Vector2.ZERO

func set_facing(dir: int) -> void:
	if dir == 0 or dir == facing_direction:
		return
	$Bat.flip_h = !($Bat.flip_h)
	facing_direction = dir
	for child in $BehaviorChanging.get_children():
		child.position = Vector2(child.position.x * -1, child.position.y)
	_update_ray_directions()
#endregion

#region Sensores e visão
func _update_facing_direction() -> void:
	if not auto_face:
		return
	if moving:
		var dx := desired_velocity.x
		if abs(dx) > facing_flip_deadzone:
			var dir_x : int = sign(dx)
			if dir_x != 0 and dir_x != facing_direction:
				set_facing(dir_x)

func _update_line_of_sight() -> void:
	if player_is_nearby:
		var rel := player_target.global_position - global_position
		line_of_sight.target_position = rel
		if not saw_player and line_of_sight.get_collider() == player_target:
			state_chart.send_event("SawPlayer")
			saw_player = true

func _player_entered_area(player: Node2D) -> void:
	player_target = player
	player_is_nearby = true

func _player_exited_area(_player: Node2D) -> void:
	player_is_nearby = false
#endregion

#region Estados base
func _idle_entered() -> void:
	sprite_anim.play("Idle")
	sight_area.scale = Vector2(300, 170)
	sight_area.position = Vector2(0, 50)

func _idle_exited() -> void:
	sight_area.scale = Vector2(350, 250)
	sight_area.position = Vector2.ZERO
#endregion

#region Estado Starting_Chase
func _starting_chase_state_entered() -> void:
	sprite_anim.play("StartChase")
	give_up_time = starting_give_up_delay
	remaining_time_for_chase = chasing_timer.wait_time
	chasing_timer.start()
	current_speed = backtracking_speed
	_apply_wander_variation()

	# Pequeno voo inicial para “acordar”
	move_for(0.5, Vector2(0, 1), current_speed)

func _starting_chase_physics_processing() -> void:
	var sees_player := line_of_sight.get_collider() == player_target
	if sees_player:
		giving_up_timer.stop()
		if chasing_timer.is_stopped():
			chasing_timer.start(remaining_time_for_chase)
	else:
		remaining_time_for_chase = chasing_timer.time_left
		chasing_timer.stop()
		if giving_up_timer.is_stopped():
			giving_up_timer.start(give_up_time)

func start_chase() -> void:
	state_chart.send_event("Started_Chase")

func give_up_chase() -> void:
	saw_player = false
	state_chart.send_event("Player_Got_Away")
#endregion

#region Estado Chasing
func _chasing_state_entered() -> void:
	if sprite_anim.current_animation != "Flying":
		sprite_anim.play("Flying")
	current_speed = chase_flying_speed
	give_up_time = chasing_give_up_delay
	_chase_frame_accum = 0

func _apply_wander_variation() -> void:
	var random_offset := Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * wander_strength
	v_component.add_proper_velocity(random_offset)
	var v : Vector2 = v_component.get_proper_velocity().normalized() * current_speed
	v_component.set_proper_velocity(v)

func _update_ray_directions():
	for ray in avoidance_rays:
		ray.scale.x = facing_direction

func _chasing_state_physics_processing(_delta: float) -> void:
	# vê se enxerga o player
	var sees_player := line_of_sight.get_collider() == player_target

	if sees_player:
		giving_up_timer.stop()
	else:
		if giving_up_timer.is_stopped():
			giving_up_timer.start(give_up_time)

	# retarget periódico
	_chase_frame_accum += 1
	if sees_player and _chase_frame_accum >= chase_retarget_frames:
		_chase_frame_accum = 0
		if is_instance_valid(player_target):
			var new_target := player_target.global_position
			var dir := (new_target - global_position).normalized()
			desired_velocity = dir * current_speed
			_apply_wander_variation()

			# vira quando o player estiver suficientemente deslocado no eixo X
			if abs(new_target.x - global_position.x) > facing_flip_deadzone:
				set_facing(sign(new_target.x - global_position.x))

	# --- Evitação com raycasts frontais ---
	if sees_player:
		var avoidance_force := Vector2.ZERO
		var active_rays := 0
		var avoidance_strength := 0.45  # ajuste fino: 0.2 .. 0.6

		for ray in avoidance_rays:
			if ray.is_colliding():
				active_rays += 1
				var collision_point := ray.get_collision_point()
				var away := global_position - collision_point
				if away.length() > 0.0:
					avoidance_force += away.normalized()

		if active_rays > 0:
			# média das direções de repulsão
			avoidance_force = (avoidance_force / active_rays).normalized()
			# escala pela força e pela velocidade atual para ficar proporcional ao comportamento
			avoidance_force *= avoidance_strength * current_speed

			# mistura a repulsão com a desired_velocity
			# preserva a intenção principal, mas aplica desvio
			var base_vel := desired_velocity
			if base_vel.length() == 0:
				# se não houver direção desejada (por exemplo, ainda não retargetou), use frente
				base_vel = Vector2(facing_direction, 0) * current_speed

			var mixed := base_vel + avoidance_force
			# limita o comprimento para não extrapolar a speed máxima
			desired_velocity = mixed.normalized() * current_speed


#endregion

#region Estado Backtracking
func _on_backtracking_state_entered() -> void:
	sprite_anim.play("Flying")
	desired_velocity = Vector2.ZERO
	current_speed = backtracking_speed
	_try_find_ceiling()

func _try_find_ceiling() -> void:
	var best_point := _find_best_ceiling_spot()
	if best_point != global_position:
		var dir := (best_point - global_position).normalized()
		move_for(1.0, dir, current_speed, func(): state_chart.send_event("Got_On_Idling_Spot"))
	else:
		var dir := Vector2(0, -1)
		move_for(2.0, dir, current_speed)
		if ceiling_retry_timer.is_stopped():
			ceiling_retry_timer.start()

func _on_ceiling_retry_timeout() -> void:
	_try_find_ceiling()

func _find_best_ceiling_spot() -> Vector2:
	var best_distance := INF
	var best_point := global_position
	for angle_deg in range(160, 19, -10):
		var dir = Vector2(cos(deg_to_rad(angle_deg)), -sin(deg_to_rad(angle_deg)))
		ceiling_detector.target_position = dir * 500
		ceiling_detector.force_raycast_update()
		if ceiling_detector.is_colliding():
			var normal = ceiling_detector.get_collision_normal()
			if is_zero_approx(normal.y - 1):
				var dist = (ceiling_detector.get_collision_point() - global_position).length()
				if dist < best_distance:
					best_distance = dist
					best_point = ceiling_detector.get_collision_point()
	return best_point
#endregion

#region Ataques
func dash() -> void:
	current_speed = dash_speed
	var dir := Vector2(facing_direction, 0)
	var duration := dash_distance / dash_speed
	move_for(duration, dir, current_speed, func(): state_chart.send_event("Finished_Attack"))

func dive() -> void:
	current_speed = dash_speed
	var dir := Vector2(0, 1)
	var duration := dash_distance / dash_speed
	move_for(duration, dir, current_speed, func(): state_chart.send_event("Finished_Attack"))
#endregion

#region Seleção e preparação de ataque

func _dash_area_body_entered(_body: Node2D) -> void:
	if $StateChart/State_Tree/Attacking.active:
		return
	current_attack = dash
	current_attack_type = "dash"
	player_in_attack_area = true
	_start_attack_delay()

func _dive_area_body_entered(_body: Node2D) -> void:
	if $StateChart/State_Tree/Attacking.active:
		return
	current_attack = dive
	current_attack_type = "dive"
	player_in_attack_area = true
	_start_attack_delay()

func _dash_area_body_exited(_body: Node2D) -> void:
	player_in_attack_area = false
	_cancel_attack_delay_if_running()

func _dive_area_body_exited(_body: Node2D) -> void:
	player_in_attack_area = false
	_cancel_attack_delay_if_running()


func _start_attack_delay() -> void:
	if attack_delay_timer.is_stopped():
		attack_delay_timer.start(attack_reaction_delay)

func _cancel_attack_delay_if_running() -> void:
	if not attack_delay_timer.is_stopped():
		attack_delay_timer.stop()

func _on_attack_delay_timeout() -> void:
	# Só ataca se o player ainda estiver dentro da área de ataque
	if player_in_attack_area:
		state_chart.send_event("Player_Got_In_Range")


func _preparing_state_entered() -> void:
	sprite_anim.play("StartDash")
	sprite_anim.queue("Dash")
	auto_face = false
	stop(0.1)
	contact_hitbox.scale *= dash_hitbox_increase
	dash_area.set_deferred("monitoring", false)
	dive_area.set_deferred("monitoring", false)
	current_speed = backtracking_speed - 10

	var retreat_dir: Vector2
	if current_attack_type == "dash":
		retreat_dir = Vector2(-facing_direction, 0)
	elif current_attack_type == "dive":
		retreat_dir = Vector2(0, -1)
	else:
		retreat_dir = Vector2(-facing_direction, 0)

	move_for(0.3, retreat_dir, current_speed, func():
		auto_face = true
		state_chart.send_event("Prepared_Attack")
	)
#endregion

#region Execução e recuperação
func _internal_attacking_state_entered() -> void:
	current_attack.call()

func _internal_attack_physics_processing(_delta: float) -> void:
	var hit_wall: bool = is_on_wall() and is_zero_approx(get_real_velocity().x)
	var hit_floor: bool = is_on_floor() and is_zero_approx(get_real_velocity().y)
	if hit_wall or hit_floor:
		stop(0.1)

func _recovering_state_entered() -> void:
	sprite_anim.play("Flying")
	contact_hitbox.scale *= (1 / dash_hitbox_increase)
	await get_tree().create_timer(dash_delay * 3).timeout
	dash_area.set_deferred("monitoring", true)
	dive_area.set_deferred("monitoring", true)
	state_chart.send_event("Recovered")
#endregion

#region Dano / Vida
func _took_damage(_amount: float) -> void:
	pass

func _ran_out_of_health() -> void:
	stop(0.1)
	call_deferred("free")

func _hurtbox_got_knocked(_hitbox : Hitbox) -> void:
	pass

func _on_fire_manager_caught_fire() -> void:
	var fire_man : FireManager = $FireManager
	if not fire_man.extinguished.is_connected(health_man.stop_burning):
		fire_man.extinguished.connect(health_man.stop_burning, 4)
		health_man.start_burning(0.5)
#endregion

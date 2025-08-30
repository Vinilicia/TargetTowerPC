extends CharacterBody2D

@onready var state_chart = $StateChart as StateChart

@export_group("Nodes")
@export var v_component: VelocityComponent
@export var navigator: NavigationAgent2D
@export_subgroup("Timers")
@export var chasing_timer: Timer
@export var giving_up_timer: Timer
@export var flinch_timer: Timer
@export_subgroup("Raycasts")
@export var line_of_sight: RayCast2D
@export var wall_detector: RayCast2D
@export var ceiling_detector: RayCast2D
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
@export var dash_hitbox_increase: float

# Ajustes de chasing
@export_group("Chase Tuning")
@export var chase_retarget_frames: int = 5       # atualiza alvo a cada N frames
@export var chase_retarget_epsilon: float = 6.0  # px: só move_to se mudou além disso
@export var facing_flip_deadzone: float = 2.0    # px: evita flip jitter

# Estado atual
var current_speed: float
var current_tolerance: float = 5
var facing_direction: int = 1
var moving: bool = false
var saw_player: bool = false
var player_is_nearby: bool = false
var player_target: CharacterBody2D
var player_relative_position: Vector2
var chasing_target_position: Vector2
var initial_position: Vector2
var move_target: Vector2

# Controle interno
var stopping_tween: Tween
var current_to_do: Callable = func (): pass
var current_attack: Callable = dash
var give_up_time: float
var remaining_time_for_chase: float = -1

# controle do retarget
var _chase_frame_accum: int = 0


#region Built-In
func _ready() -> void:
	initial_position = global_position

func _physics_process(_delta: float) -> void:
	_update_facing_direction()
	_update_line_of_sight()
	_check_reached_target()
	
	velocity = v_component.get_total_velocity()
	move_and_slide()

func _update_facing_direction() -> void:
	if moving:
		var dx := move_target.x - global_position.x
		if abs(dx) > facing_flip_deadzone:
			var dir_x : int = sign(dx)
			if dir_x != 0 and dir_x != facing_direction:
				turn_around()

func _update_line_of_sight() -> void:
	if player_is_nearby:
		player_relative_position = player_target.global_position - global_position
		line_of_sight.target_position = player_relative_position
		if not saw_player and line_of_sight.get_collider() == player_target:
			state_chart.send_event("SawPlayer")
			saw_player = true

func _check_reached_target() -> void:
	if moving and (move_target - global_position).length() < current_tolerance:
		print("Peanuts")
		stop(0.2)
		current_to_do.call()

func _player_entered_area(player: Node2D) -> void:
	player_target = player
	player_is_nearby = true

func _player_exited_area(_player: Node2D) -> void:
	player_is_nearby = false
#endregion

#region Usadas sempre
func turn_around() -> void:
	facing_direction *= -1
	for child in $BehaviorChanging.get_children():
		child.position = Vector2(child.position.x * -1, child.position.y)

func move_to(pos: Vector2, tolerance: float, todo: Callable = Callable()) -> void:
	if stopping_tween and stopping_tween.is_running():
		stopping_tween.kill()

	move_target = pos
	current_tolerance = tolerance
	current_to_do = todo if todo.is_valid() else func(): pass

	var dir = (pos - global_position).normalized()
	v_component.set_proper_velocity(current_speed * dir)
	moving = true

func stop(duration : float) -> void:
	moving = false
	stopping_tween = create_tween()
	stopping_tween.tween_property(v_component, "proper_velocity", Vector2.ZERO, duration).set_ease(Tween.EASE_IN)
#endregion

func _idle_entered() -> void:
	sight_area.scale = Vector2(300, 170)
	sight_area.position = Vector2(0, 50)

func _idle_exited() -> void:
	sight_area.scale = Vector2(400, 300)
	sight_area.position = Vector2.ZERO

#region Estado Starting_Chase
func _starting_chase_state_entered() -> void:
	give_up_time = starting_give_up_delay
	remaining_time_for_chase = chasing_timer.wait_time
	chasing_timer.start()
	current_speed = backtracking_speed
	move_to(global_position + Vector2(0, 30), 10)

func _starting_chase_physics_processing(_delta: float) -> void:
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
	current_speed = chase_flying_speed
	give_up_time = chasing_give_up_delay
	_chase_frame_accum = 0

	if is_instance_valid(player_target) and player_is_nearby and line_of_sight.get_collider() == player_target:
		chasing_target_position = player_target.position
	
	move_to(chasing_target_position, 10)

func _chasing_state_physics_processing(_delta : float) -> void:
	var sees_player := line_of_sight.get_collider() == player_target

	if sees_player:
		giving_up_timer.stop()
	else:
		if giving_up_timer.is_stopped():
			giving_up_timer.start(give_up_time)

	# só atualiza a cada N frames
	_chase_frame_accum += 1
	if sees_player and _chase_frame_accum >= chase_retarget_frames:
		_chase_frame_accum = 0
		var new_target := player_target.position
		if new_target.distance_to(chasing_target_position) >= chase_retarget_epsilon:
			chasing_target_position = new_target
			move_to(chasing_target_position, 10)
#endregion

#region Estado Backtracking
func _on_backtracking_state_entered() -> void:
	current_speed = backtracking_speed
	current_tolerance = -10

	var best_point := _find_best_ceiling_spot()
	move_to(best_point, 15, func(): state_chart.send_event("Got_On_Idling_Spot"))

func _find_best_ceiling_spot() -> Vector2:
	var best_distance := INF
	var best_point := global_position

	for angle_deg in range(160, 19, -10):
		var dir = Vector2(cos(deg_to_rad(angle_deg)), -sin(deg_to_rad(angle_deg)))
		ceiling_detector.target_position = dir * 500
		ceiling_detector.force_raycast_update()

		if ceiling_detector.is_colliding():
			var dist = (ceiling_detector.get_collision_point() - global_position).length()
			if dist < best_distance:
				best_distance = dist
				best_point = ceiling_detector.get_collision_point()
	
	return best_point
#endregion

func dash() -> void:
	current_speed = dash_speed
	var attack_pos : Vector2 = global_position + (facing_direction * Vector2(dash_distance, 0))
	move_to(attack_pos, 20, func (): state_chart.send_event("Finished_Attack"))

func dive() -> void:
	current_speed = dash_speed
	var attack_pos : Vector2 = global_position + Vector2(0, dash_distance)
	move_to(attack_pos, 20, func (): state_chart.send_event("Finished_Attack"))

func _dash_area_body_entered(_body: Node2D) -> void:
	if not $StateChart/State_Tree/Attacking.active:
		current_attack = dash
	state_chart.send_event("Player_Got_In_Range")

func _dive_area_body_entered(_body: Node2D) -> void:
	if not $StateChart/State_Tree/Attacking.active:
		current_attack = dive
	state_chart.send_event("Player_Got_In_Range")

func _preparing_state_entered() -> void:
	stop(0.1)
	contact_hitbox.scale *= dash_hitbox_increase
	await get_tree().create_timer(dash_delay).timeout
	dash_area.monitoring = false
	dive_area.monitoring = false
	state_chart.send_event("Prepared_Attack")

func _internal_attacking_state_entered() -> void:
	current_attack.call()

func _internal_attack_physics_processing(_delta: float) -> void:
	var hit_wall : bool = is_on_wall() and is_zero_approx(get_real_velocity().x)
	var hit_floor : bool = is_on_floor() and is_zero_approx(get_real_velocity().y)
	if hit_wall or hit_floor:
		move_target = global_position

func _recovering_state_entered() -> void:
	contact_hitbox.scale *= (1 / dash_hitbox_increase)
	wall_detector.target_position = Vector2.ZERO
	await get_tree().create_timer(dash_delay * 3).timeout
	dash_area.monitoring = true
	dive_area.monitoring = true
	state_chart.send_event("Recovered")

func _took_damage(_amount: float) -> void:
	pass

func _ran_out_of_health() -> void:
	stop(0.1)
	call_deferred("free")

func _hurtbox_got_knocked(_hitbox : Hitbox) -> void:
	pass

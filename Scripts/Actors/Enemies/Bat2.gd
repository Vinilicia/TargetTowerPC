extends CharacterBody2D

@onready var state_chart = $StateChart as StateChart

@export_group("Nodes")
@export var chasing_timer : Timer
@export var giving_up_timer : Timer
@export var flinch_timer : Timer
@export var line_of_sight : RayCast2D
@export var wall_detector : RayCast2D
@export var ceiling_detector : RayCast2D
@export var navigator : NavigationAgent2D
@export var dash_area : Area2D
@export var contact_hitbox : Hitbox
@export var v_component : VelocityComponent

@export_group("Behaviourial")
@export var backtracking_speed : float

@export_subgroup("Chase")
@export var chase_flying_speed : float
@export var starting_give_up_delay : float
@export var chasing_give_up_delay : float

@export_subgroup("Attacks")
@export var dash_speed : float
@export var dash_distance : float
@export var dash_delay : float
@export var dash_hitbox_increase : float

var current_speed : float
var current_tolerance : float = 5
var facing_direction : int = 1

var stopping_tween : Tween

var move_target : Vector2
var initial_position : Vector2
var movement_direction : Vector2
var distance_to_target : float

var player_is_nearby : bool = false
var saw_player : bool = false
var player_relative_position : Vector2
var player_target : CharacterBody2D
var chasing_target_position : Vector2 = Vector2(0, 0)

var remaining_time_for_chase : float = -1
var give_up_time : float


#region Built-In
func _ready() -> void:
	initial_position = global_position

func _physics_process(_delta: float) -> void:
	if sign(velocity.x) != facing_direction and sign(velocity.x) != 0:
		turn_around()
	
	if player_is_nearby:
		player_relative_position = player_target.global_position - global_position
		line_of_sight.target_position = player_relative_position
		if !saw_player and line_of_sight.get_collider() == player_target:
			state_chart.send_event("SawPlayer")
			saw_player = true
	
	if (move_target - global_position).length() < current_tolerance:
		stop(0.2)
	
	velocity = v_component.get_total_velocity()
	move_and_slide()

#Na função physics_process, como o processo de checar a linha de visão com o player é ligado à variável
#"player_is_nearby", em ambos esses casos abaixo, o inimigo começará ou deixará de ver o player quando ele
#entrar ou sair da área. A saída é usada tanto em Starting_Chase quanto em Chasing
func _player_entered_area(player: Node2D) -> void:
	player_target = player
	player_is_nearby = true

func _player_exited_area(_player: Node2D) -> void:
	player_is_nearby = false
#endregion

#region Usadas sempre
#funções essenciais que podem ser usadas a qualquer momento
func move_to(pos : Vector2, tol : float) -> void:
	move_target = pos
	current_tolerance = tol
	var movement_vector = (pos - global_position).normalized()
	v_component.set_proper_velocity(current_speed * movement_vector)

func turn_around() -> void:
	facing_direction *= -1
	for child in $BehaviorChanging.get_children():
		child.position = Vector2(child.position.x * -1, child.position.y)

func stop(duration : float) -> void:
	stopping_tween = create_tween()
	stopping_tween.tween_property(v_component, "proper_velocity", Vector2.ZERO, duration).set_ease(Tween.EASE_IN)
#endregion

func _idle_entered() -> void:
	stop(0.1)

#region Estado Starting_Chase
#Existe mais para rodar a lógica do delay antes da perseguição começar
func _starting_chase_state_entered() -> void:
	give_up_time = starting_give_up_delay
	remaining_time_for_chase = chasing_timer.wait_time
	chasing_timer.start()
	current_speed = backtracking_speed/2
	move_to(global_position + Vector2(0, 30), 3)

func _starting_chase_physics_processing(_delta: float) -> void:
	if line_of_sight.get_collider() != player_target:
		remaining_time_for_chase = chasing_timer.time_left
		chasing_timer.stop()
		if giving_up_timer.is_stopped():
			giving_up_timer.start(give_up_time)
	else:
		giving_up_timer.stop()
		if chasing_timer.is_stopped():
			chasing_timer.start(remaining_time_for_chase)

#Essas duas abaixo são conectadas aos nós chasing e giving_up timers
func start_chase() -> void:
	state_chart.send_event("Started_Chase") #Var pro estado Chasing

func give_up_chase() -> void:
	saw_player = false
	state_chart.send_event("Player_Got_Away") #Vai pro estado Idle ( caso em Starting ) ou para Backtracing
	# ( Chasing )

#endregion

#region Estado Chasing

func _chasing_state_entered() -> void:
	current_speed = chase_flying_speed
	give_up_time = chasing_give_up_delay

func _chasing_state_physics_processing(_delta : float) -> void:
	if line_of_sight.get_collider() == player_target:
		giving_up_timer.stop()
		chasing_target_position = player_target.position
	else:
		if giving_up_timer.is_stopped():
			giving_up_timer.start(give_up_time)
	
	move_to(chasing_target_position, 10)
#endregion

#region Estado Backtracking

func _on_backtracking_state_entered() -> void:
	stop(0.5)
	current_speed = backtracking_speed
	var start_angle : float = 155
	var end_angle : float = 25
	var step : int = -10
	var radius : int = 500
	var best_distance : float = 500
	var best_point : Vector2
	var current_distance : float = 500
	var ceiling_point : bool = false
	var multiplier : float = 1
	
	for angle_deg in range(start_angle, end_angle - 1, step):
		var angle_rad = deg_to_rad(angle_deg)
		var direction = Vector2(cos(angle_rad), -sin(angle_rad))

		ceiling_detector.target_position = direction * radius
		ceiling_detector.force_raycast_update()

		if ceiling_detector.is_colliding():
			var normal = ceiling_detector.get_collision_normal()

			if normal.dot(Vector2.DOWN) > 0.7:
				current_distance = (ceiling_detector.get_collision_point() - global_position).length()
				if current_distance < best_distance:
					best_distance = current_distance
					best_point = ceiling_detector.get_collision_point()
					ceiling_point = true
			elif abs(normal.dot(Vector2.RIGHT)) > 0.7:
				multiplier = 1
				if ceiling_point:
					multiplier = 1.3
					current_distance = (ceiling_detector.get_collision_point() - global_position).length() * multiplier
				if current_distance < best_distance:
					best_distance = current_distance
					best_point = ceiling_detector.get_collision_point()
					ceiling_point = false
	
	ceiling_detector.target_position = best_point
	
	navigator.target_position = best_point

func _backtracking_physics_processing(_delta: float) -> void:
	move_to(navigator.get_next_path_position(), 10)

func _navigator_target_reached() -> void:
	state_chart.send_event("Got_On_Idling_Spot")

#endregion


func _dash_area_body_entered(_body: Node2D) -> void:
	state_chart.send_event("Player_Got_In_Range")


func _preparing_state_entered() -> void:
	stop(0.1)
	contact_hitbox.scale *= dash_hitbox_increase
	wall_detector.target_position = facing_direction * Vector2(dash_distance, 0)
	await get_tree().create_timer(dash_delay).timeout
	dash_area.monitoring = false
	state_chart.send_event("Prepared_Attack")

var attack_pos

func _internal_attacking_state_entered() -> void:
	current_speed = dash_speed
	var vec = facing_direction * Vector2(dash_distance, 0)
	var wall_detec_point : Vector2 = wall_detector.get_collision_point()
	if wall_detector.is_colliding():
		attack_pos = wall_detec_point
	else:
		attack_pos = global_position + vec
	move_to(attack_pos, 10)


func _internal_attack_physics_processing(_delta: float) -> void:
	if (global_position - attack_pos).length() < 10:
		stop(0.3)
		state_chart.send_event("Finished_Attack")


func _recovering_state_entered() -> void:
	contact_hitbox.scale *= (1 / dash_hitbox_increase)
	wall_detector.target_position = Vector2.ZERO
	await get_tree().create_timer(dash_delay * 3).timeout
	dash_area.monitoring = true
	state_chart.send_event("Recovered")

#func flinch() -> void:
	#if speed_before_flinch == 0:
		#speed_before_flinch = current_speed
		#current_speed = 0
	#flinch_timer.start()

#func _flinch_timer_timeout() -> void:
	#current_speed = speed_before_flinch
	#speed_before_flinch = 0
#
#
#func _external_attacking_state_exited() -> void:
	#if !flinch_timer.is_stopped():
		#flinch_timer.stop()

func _took_damage(amount: float) -> void:
	#print("The bat took ", amount, " damage!")
	pass

func _ran_out_of_health() -> void:
	stop(0.1)
	call_deferred("free")

func _hurtbox_got_knocked(knockback_vector: Vector2) -> void:
	pass

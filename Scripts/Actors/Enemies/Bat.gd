extends CharacterBody2D

@onready var state_chart = $StateChart as StateChart

@export_category("Nodes")
@export var chasing_timer : Timer
@export var giving_up_timer : Timer
@export var line_of_sight : RayCast2D
@export var navigator : NavigationAgent2D

@export_category("Behaviourial")
@export_group("Idle")
@export var idle_flying_speed : float
@export var idle_movement_angle : float
@export var idle_moving_distance : float
@export var idle_stopping_delay : float
@export var idle_tolerance : int

@export_group("Chase")
@export var chase_flying_speed : float
@export var starting_give_up_delay : float
@export var chasing_give_up_delay : float

@export_group("Attacks")
@export var dash_speed_increase : float
@export var dash_attack_damage : float
@export var dash_duration : float
@export var dash_delay : float
@export var dash_hitbox_increase : float

var current_speed : float
var facing_direction : int = 1

var moving_tween : Tween
var stopping_tween : Tween

var initial_position : Vector2
var movement_direction : Vector2
var idle_target_position : Vector2
var distance_to_target : float
var last_idle_position : Vector2

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
			state_chart.send_event("Saw_Player")
			saw_player = true
	
	move_and_slide()

#Na função physics_process, como o processo de checar a linha de visão com o player é ligado à variável
#"player_is_nearby", em ambos esses casos abaixo, o inimigo começará ou deixará de ver o player quando ele
#entrar ou sair da área. A saída é usada tanto em Starting_Chase quanto em Chasing
func _player_entered_area(player: Node2D) -> void:
	player_target = player
	player_is_nearby = true

func _player_exited_area(player: Node2D) -> void:
	player_is_nearby = false
#endregion

#region Usadas sempre
#funções essenciais que podem ser usadas a qualquer momento
func move_to(pos : Vector2) -> void:
	if (pos - global_position).length() < 3:
		velocity = velocity
	else:
		var movement_vector = (pos - global_position).normalized()
		velocity = current_speed * movement_vector

func turn_around() -> void:
	facing_direction *= -1
	for child in $Behavior_Changing.get_children():
		child.position = Vector2(child.position.x * -1, child.position.y)
	for child in $Attacks.get_children():
		child.position = Vector2(child.position.x * -1, child.position.y)

func stop(duration : float) -> void:
	if moving_tween:
		moving_tween.kill()
	stopping_tween = create_tween()
	stopping_tween.tween_property(self, "velocity", Vector2.ZERO, duration).set_ease(Tween.EASE_IN)
#endregion

#region Estado Idle
#Estado Idle possui estados Moving e Stopped

func idle_movement_turn() -> void:
	var final_angle = deg_to_rad(idle_movement_angle) + PI
	idle_movement_angle = rad_to_deg(final_angle)

func pick_idle_target_position() -> void:
	movement_direction = (Vector2.RIGHT.rotated(deg_to_rad(idle_movement_angle)) * idle_moving_distance)
	idle_target_position = global_position + movement_direction
	await get_tree().create_timer(idle_stopping_delay).timeout
	state_chart.send_event("Started_Moving") #Vai pro estado Idle/Moving

func start_idle_moving() -> void:
	current_speed = 0
	moving_tween = create_tween()
	moving_tween.tween_property(self, "current_speed", idle_flying_speed, 1).set_ease(Tween.EASE_IN)

func _moving_physics_processing(_delta: float) -> void:
	move_to(idle_target_position)
	distance_to_target = (idle_target_position - global_position).length()
	if abs(distance_to_target) < idle_tolerance:
		idle_movement_turn()
		state_chart.send_event("Arrived") #Vai pro estado Idle/Stopped

func _stopped_state_entered() -> void:
	stop(1)
	pick_idle_target_position()

func _idle_state_exited() -> void:
	last_idle_position = global_position
#endregion

#region Estado Starting_Chase
#Existe mais para rodar a lógica do delay antes da perseguição começar
func _starting_chase_state_entered() -> void:
	stop(0.5)
	give_up_time = starting_give_up_delay
	remaining_time_for_chase = chasing_timer.wait_time
	chasing_timer.start()


func _starting_chase_physics_processing(delta: float) -> void:
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

func _chasing_state_physics_processing(delta : float) -> void:
	if line_of_sight.get_collider() == player_target:
		giving_up_timer.stop()
		chasing_target_position = player_target.position
	else:
		if giving_up_timer.is_stopped():
			giving_up_timer.start(give_up_time)
	
	move_to(chasing_target_position)
#endregion

#region Estado Backtracking

func _on_backtracking_state_entered() -> void:
	stop(0.5)
	current_speed = idle_flying_speed
	navigator.target_position = last_idle_position

func _backtracking_physics_processing(delta: float) -> void:
	move_to(navigator.get_next_path_position())

func _navigator_target_reached() -> void:
	state_chart.send_event("Got_On_Idling_Spot") #Vai para o estado Idle

#endregion

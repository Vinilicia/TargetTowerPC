extends CharacterBody2D

@onready var state_chart = $StateChart as StateChart

@export var health : int

@export_category("Nodes")
@export var chasing_timer : Timer
@export var giving_up_timer : Timer
@export var line_of_sight : RayCast2D
@export var breadcrumb_los : RayCast2D
@export var navigator : NavigationAgent2D

@export_category("Movement")
@export var idle_flying_speed : float
@export var idle_movement_angle : float
@export var idle_moving_distance : float
@export var idle_stopping_time : float
@export var los_tween_duration : float

@export var starting_give_up_time : float
@export var chasing_give_up_time : float
@export var chase_flying_speed : float

@export var dash_speed_increase : float

var breadcrumb_container : Node

var initial_position : Vector2
var idle_target_position : Vector2
var idle_tolerance : int = 40
var movement_direction : Vector2
var distance_to_target : float

var current_speed : float

var facing_direction : int = 1

var player_is_nearby : bool = false
var seeing_player : bool = false
var player_relative_position : Vector2

var remaining_time_for_chase : float = -1


var give_up_time : float

var saw_player : bool = false

var final_velocity : Vector2
var moving_tween : Tween
var stopping_tween : Tween

var player_target : CharacterBody2D

@export_category("Attacks")
@export var dash_attack_damage : int
@export var dash_attack_delay : float

@export var bite_attack_damage : int
@export var bite_attack_delay : float


func _ready() -> void:
	initial_position = global_position

func pick_idle_target_position() -> void:
	movement_direction = (Vector2.RIGHT.rotated(deg_to_rad(idle_movement_angle)) * idle_moving_distance)
	idle_target_position = global_position + movement_direction
	await get_tree().create_timer(idle_stopping_time).timeout
	state_chart.send_event("Started_Moving")

func move_to(pos : Vector2) -> void:
	var movement_vector = (pos - global_position).normalized()
	velocity = current_speed * movement_vector

func _physics_process(_delta: float) -> void:
	if player_is_nearby:
		player_relative_position = player_target.global_position - global_position
		line_of_sight.target_position = player_relative_position
		if !saw_player and line_of_sight.get_collider() == player_target:
			state_chart.send_event("Saw_Player")
			saw_player = true
	
	move_and_slide()

func turn_around() -> void:
	facing_direction *= -1
	for child in $Behavior_Changing.get_children():
		child.position = Vector2(child.position.x * -1, child.position.y)
	for child in $Attacks.get_children():
		child.position = Vector2(child.position.x * -1, child.position.y)

func idle_movement_turn() -> void:
	var final_angle = deg_to_rad(idle_movement_angle) + PI
	idle_movement_angle = rad_to_deg(final_angle)

func start_idle_moving() -> void:
	current_speed = 0
	moving_tween = create_tween()
	moving_tween.tween_property(self, "current_speed", idle_flying_speed, 1).set_ease(Tween.EASE_IN)

func _moving_physics_processing(_delta: float) -> void:
	move_to(idle_target_position)
	distance_to_target = (idle_target_position - global_position).length()
	if abs(distance_to_target) < idle_tolerance:
		idle_movement_turn()
		state_chart.send_event("Arrived")

func stop(duration : float) -> void:
	if moving_tween:
		moving_tween.kill()
	stopping_tween = create_tween()
	stopping_tween.tween_property(self, "velocity", Vector2.ZERO, duration).set_ease(Tween.EASE_IN)

func _stopped_state_entered() -> void:
	stop(1)
	pick_idle_target_position()


func _player_entered_area(player: Node2D) -> void:
	player_target = player
	player_is_nearby = true


func _starting_chase_state_entered() -> void:
	stop(0.5)
	give_up_time = starting_give_up_time
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

func start_chase() -> void:
	state_chart.send_event("Started_Chase")

func give_up_chase() -> void:
	saw_player = false
	state_chart.send_event("Player_Got_Away")

func _sight_area_body_exited(player: Node2D) -> void:
	player_is_nearby = false

func _chasing_state_entered() -> void:
	#player_target.add_pursuer()
	current_speed = chase_flying_speed
	give_up_time = give_up_time
	#get_breadcrumb_container()
	#breadcrumb_checking_timer.start()

#func get_chasing_target() -> void:	
	#target = null
	#if !breadcrumb_container.breadcrumbs.is_empty():
		#var breadcrumb : Breadcrumb
		#for i in range(breadcrumb_container.breadcrumb_count):
			#breadcrumb = breadcrumb_container.get_breadcrumb(i)
			#breadcrumb_los.target_position = breadcrumb.global_position - global_position
			#if breadcrumb_los.get_collider() == breadcrumb:
				#target = breadcrumb

var target_position : Vector2 = Vector2(0, 0)

func _chasing_state_physics_processing(delta : float) -> void:
	if line_of_sight.get_collider() == player_target:
		giving_up_timer.stop()
		target_position = player_target.position
	else:
		if giving_up_timer.is_stopped():
			giving_up_timer.start(give_up_time)
	
	move_to(target_position)


func _seeing_player_physics_processing(delta: float) -> void:
	if line_of_sight.get_collider() == player_target:
		if sign(player_relative_position.x) != facing_direction and sign(player_relative_position.x) != 0:
			turn_around()

func _idle_physics_processing(delta: float) -> void:
	if sign(velocity.x) != facing_direction and sign(velocity.x) != 0:
		turn_around()


func _on_backtracking_state_entered() -> void:
	stop(0.5)
	print(idle_position)
	current_speed = idle_flying_speed
	navigator.target_position = idle_position


func _backtracking_physics_processing(delta: float) -> void:
	move_to(navigator.get_next_path_position())



var idle_position : Vector2

func _idle_state_exited() -> void:
	idle_position = global_position


func _navigator_target_reached() -> void:
	state_chart.send_event("Got_On_Idling_Spot")

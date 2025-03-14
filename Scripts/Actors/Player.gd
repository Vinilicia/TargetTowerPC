extends CharacterBody2D
class_name Player

@export_category("Camera")
@export var camera_distance : float
@export var camera_move_duration : float

@export var remote : RemoteTransform2D


@export var Move_Speed : float
@export var Jump_Force : float
@export var Default_Knockback : Vector2 = Vector2(170, 0)
@export var Gravity_Multiplier : float
@export_dir var Arrows_paths : Array[String]
@export var Max_hold_time : float
@export var Shoot_Delay : float
@export var Jump_buffering_time : float
@export var Max_Arrows : int
@export var Exit_Time : float


@onready var screen_exit_timer = $Timers/Screen_Exit_Timer as Timer
@onready var arrow_spawner = $Arrow_Spawner as Marker2D
@onready var shooting_timer = $Timers/Shooting_Timer as Timer
@onready var arrow_sprite = $Arrow_Spawner/Arrow_Sprite as Sprite2D
@onready var jump_buffering = $Timers/Jump_Buffering as Timer
@onready var state_chart = $StateChart as StateChart
 

var knockback_vector : Vector2
var gravity : float = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_on_screen : bool = true
var can_shoot : bool = true
var current_arrow : Area2D
var holding_time : float = 0.0
var is_holding : bool = false
var fall_jump_buffer : bool = false
var ledge_jump_buffer : bool = false
var is_jumping : bool = false
var on_floor : bool = true
var facing_direction : int = 1

@export_category("Para debugar")
@export_range(0 , 9) var Initial_Arrow_Index : int # so vai ate 7 por enquanto

var current_arrow_index : int
var arrow_switcher

func _ready():
	velocity = Vector2.ZERO
	setup_camera()
	UiHandler.equiped_arrow_index = Initial_Arrow_Index
	current_arrow_index = Initial_Arrow_Index
	current_arrow = equip_arrow(current_arrow_index)
	turn(-facing_direction)
	turn(facing_direction)

func _process(delta):
	if is_holding == true:
		holding_time += delta
		arrow_sprite.visible = true

	if Input.is_action_pressed("shoot") and can_shoot:
		hold_arrow()
		can_shoot = false
	
	if Input.is_action_just_released("shoot") and is_holding:
		shoot_arrow()
	
	if UiHandler.equiped_arrow_index != current_arrow_index:
		current_arrow_index = UiHandler.equiped_arrow_index
		current_arrow = equip_arrow(current_arrow_index)

func hold_arrow() -> void:
	arrow_sprite.visible = true;
	is_holding = true

func receive_knockback(_knockback_vector : Vector2) -> void:
	print(_knockback_vector)
	knockback_vector = _knockback_vector
	var knockback_tween : Tween = get_tree().create_tween()
	knockback_tween.tween_property(self, "knockback_vector", Vector2.ZERO, 0.1)

func shoot_arrow() -> void:
	is_holding = false
	arrow_sprite.visible = false
	get_parent().call_deferred("add_child", current_arrow)
	current_arrow.global_position = arrow_spawner.global_position
	current_arrow.set_facing_direction(sign(arrow_spawner.position.x))
	var is_charged : bool = true
	if holding_time < Max_hold_time:
		current_arrow.fly(!is_charged, self)
	else:
		current_arrow.fly(is_charged, self)
	holding_time = 0.0
	shooting_timer.start(Shoot_Delay)
	current_arrow = equip_arrow(current_arrow_index % Max_Arrows)
	await shooting_timer.timeout
	can_shoot = true

func shoot_arrow_d() -> void:
	arrow_spawner.position = Vector2.ZERO
	is_holding = false
	arrow_sprite.visible = false
	get_parent().call_deferred("add_child", current_arrow)
	current_arrow.global_position = arrow_spawner.global_position
	current_arrow.set_facing_direction(sign(arrow_spawner.position.x))
	current_arrow.fly_downward(self)
	arrow_spawner.position = Vector2(8, 0) * facing_direction
	shooting_timer.start(Shoot_Delay)
	current_arrow = equip_arrow(current_arrow_index % Max_Arrows)
	await shooting_timer.timeout
	can_shoot = true

func equip_arrow(array_position : int) -> Area2D:
	var arrow = load(Arrows_paths[array_position]).instantiate()
	return arrow

func jump(multiplier : float = 1) -> void:
	on_floor = false
	velocity.y = Jump_Force * multiplier
	state_chart.send_event("jumped")

func move(facing_dir : int) -> void:
	velocity.x = facing_dir * Move_Speed

func _on_screen_exit_timer_timeout():
	die()

func die():
	get_tree().call_deferred("reload_current_scene")

func screen_exited():
	screen_exit_timer.start()

func screen_entered():
	screen_exit_timer.stop()

func get_current_gravity(velocity_in_y : float) -> float:
	if velocity_in_y < 0:
		return gravity
	else:
		return gravity * Gravity_Multiplier

var pos : Vector2
var tween : Tween

func turn(facing_dir) -> void:
	arrow_spawner.position.x = 8 * facing_dir
	arrow_sprite.scale.x = facing_dir
	pos = remote.position
	var final_pos = Vector2(camera_distance * facing_dir, pos.y)
	tween = create_tween().set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "pos", final_pos, camera_move_duration)

func _physics_process(delta): 
	remote.position = remote.position.lerp(pos, 0.5)
	
	if velocity.y > 0 and !is_on_floor():
		state_chart.send_event("is_falling")
	if is_on_floor():
		on_floor = true
		state_chart.send_event("hit_floor")
		if fall_jump_buffer:
			jump()
	if not is_on_floor():
		velocity.y += get_current_gravity(velocity.y) * delta

	if Input.is_action_just_pressed("jump") and (is_on_floor() or ledge_jump_buffer):
		jump()
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.25
	if Input.is_action_just_pressed("jump") and !is_on_floor() and can_shoot:
		hold_arrow()
		can_shoot = false
		shoot_arrow_d()
	
	var direction : int = int(Input.get_axis("left", "right"))
	if direction:
		if facing_direction != direction:
			facing_direction = direction
			turn(facing_direction)
		move(direction)
	else:
		velocity.x = move_toward(velocity.x, 0, Move_Speed)
		
	if knockback_vector != Vector2.ZERO:
		velocity += knockback_vector
	move_and_slide()

func _on_jumping_state_processing():
	if Input.is_action_just_pressed("jump"):
		fall_jump_buffer = true
		jump_buffering.start(Jump_buffering_time)

func _on_jump_buffering_timeout():
	fall_jump_buffer = false
	ledge_jump_buffer = false

var cam : Camera2D = null

func _on_falling_state_entered():
	#create_tween().tween_property(cam, "position_smoothing_speed", 0, 0.1)
	
	if on_floor == true:
		on_floor = false
		jump_buffering.start(Jump_buffering_time/10 * 6)
		ledge_jump_buffer = true

func _on_floor_state_entered():
	#cam.position_smoothing_enabled = true
	Default_Knockback = Vector2(170, 0)
	is_jumping = false

func _on_floor_state_exited():
	Default_Knockback *= 2
	is_jumping = true

func setup_camera() -> void:
	remote.remote_path = get_parent().get_camera().get_path()
	#cam = get_node(remote.remote_path)
	#remote.remote_path = cam.get_path()

func take_damage(amount : float) -> void:
	print("Took ", amount, " damage.")

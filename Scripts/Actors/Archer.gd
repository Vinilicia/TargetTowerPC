extends CharacterBody2D
class_name Player

@onready var anim = $Archer/AnimationPlayer

@export var state_chart : StateChart

@export_group("Camera")
@export var camera_distance : float
@export var camera_move_duration : float
@export var camera_remote : RemoteTransform2D

@export_group("Arrow")
@export_dir var arrow_paths : Array[String]
@export var max_hold_time : float
@export var shoot_delay : float

@export_group("Physics")
@export var v_component : VelocityComponent
@export var move_speed : float
@export var jump_force : float
@export var default_knockback : Vector2 = Vector2(170, 0)
@export var gravity_multiplier : float
@export var jump_buffering_time : float
@export var air_stall_velocity : float
 
var gravity : float = ProjectSettings.get_setting("physics/2d/default_gravity")
var can_shoot : bool = true
var current_arrow : Arrow
var holding_time : float = 0.0
var is_holding : bool = false
var facing_direction : int = 1
var current_arrow_index : int
var pos : Vector2
var tween : Tween
var shoot_direction : Vector2
var update_flying_dir : bool = false
var count_hold_time : bool = false
var dodge_direction : Vector2

@export_category("Para debugar")
@export_range(0 , 8) var initial_arrow_index : int

func _ready():
	current_arrow_index = initial_arrow_index
	current_arrow = equip_arrow(current_arrow_index)
	Engine.time_scale = 0.5
	velocity = Vector2.ZERO
	setup_camera()
	UiHandler.equiped_arrow_index = initial_arrow_index

func _physics_process(delta: float) -> void:
	if count_hold_time:
		holding_time += delta
	
	if Input.is_action_just_released("shoot"):
		count_hold_time = false
		is_holding = false
	
	shoot_direction = Vector2(1, 0)
	if Input.is_action_pressed("down"):
		if !is_on_floor():
			shoot_direction = Vector2(0, 1)
	if Input.is_action_pressed("up"):
		shoot_direction = Vector2(0, -1)
	if Input.is_action_pressed("angle down"):
		shoot_direction = Vector2(1, 1)
	if Input.is_action_pressed("angle up"):
		shoot_direction = Vector2(1, -1)
	shoot_direction.x *= facing_direction
	
	if update_flying_dir:
		current_arrow.set_flying_direction(shoot_direction)
	
	if !is_on_floor():
		v_component.add_proper_velocity(Vector2(0, get_current_gravity(velocity.y)  * delta))
		if velocity.y >= 0:
			state_chart.send_event("Falling")
		else:
			state_chart.send_event("Rising")
	
	if is_on_floor():
		state_chart.send_event("Grounded")
		v_component.set_proper_velocity(0.0, 2)
	if Input.is_action_just_pressed("jump") and is_on_floor():
		jump()
	if Input.is_action_just_released("jump") and velocity.y < 0:
		var decrement_yspeed = -(v_component.get_proper_velocity(2) * 0.75) 
		v_component.add_proper_velocity(Vector2(0, decrement_yspeed))
		
	v_component.set_proper_velocity(0.0, 1)
	var dir : int = int(Input.get_axis("left", "right"))
	if dir:
		if facing_direction != dir:
			facing_direction = dir
			turn(facing_direction)
		move(facing_direction)
	
	shoot_direction = Vector2(1, 0)
	dodge_direction = Vector2(1, 0)
	if Input.is_action_pressed("down"):
		if !is_on_floor():
			shoot_direction = Vector2(0, 1)
			dodge_direction = Vector2(0, 1)
	if Input.is_action_pressed("up"):
		shoot_direction = Vector2(0, -1)
		if !is_on_floor():
			dodge_direction = Vector2(0, -1)
	if Input.is_action_pressed("angle down"):
		shoot_direction = Vector2(1, 1)
	if Input.is_action_pressed("angle up"):
		shoot_direction = Vector2(1, -1)
	
	shoot_direction.x *= facing_direction
	dodge_direction.x *= facing_direction
	
	#if Input.is_action_just_pressed("dodge"):
		#dodge_roll()
	velocity = v_component.get_total_velocity()
	move_and_slide()

#func dodge_roll():
	#v_component.set_knockback_velocity(dodge_direction * 100)
	#await get_tree().create_timer(0.2).timeout
	#v_component.set_knockback_velocity(Vector2.ZERO)


func jump(multiplier : float = 1) -> void:
	v_component.set_proper_velocity(jump_force * multiplier, 2)

func move(facing_dir : int) -> void:
	v_component.add_proper_velocity(Vector2(move_speed * facing_dir, 0))

func die():
	get_tree().call_deferred("reload_current_scene")

func equip_arrow(array_position : int) -> Arrow:
	return load(arrow_paths[array_position]).instantiate() 

func get_current_gravity(velocity_in_y : float) -> float:
	if velocity_in_y < 0:
		return gravity
	else:
		return gravity * gravity_multiplier

func turn(facing_dir) -> void:
	$Archer.scale.x  = facing_dir
	$Archer.position.x = -28 * facing_dir
	#arrow_spawner.position.x = 8 * facing_dir
	#arrow_sprite.scale.x = facing_dir
	pos = camera_remote.position
	var final_pos = Vector2(camera_distance * facing_dir, pos.y)
	tween = create_tween().set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera_remote, "position", final_pos, camera_move_duration)

func setup_camera() -> void:
	camera_remote.remote_path = get_parent().get_camera().get_path()

func take_damage(amount : float) -> void:
	print("Took ", amount, " damage.")

func _rising_to_falling_taken() -> void:
	anim.clear_queue()
	anim.play("Jump Apex")

func _falling_state_entered() -> void:
	anim.queue("Start Fall")
	anim.queue("Fall")

func _grounded_to_falling_taken() -> void:
	anim.stop()

func _falling_to_grounded_taken() -> void:
	anim.play("Landing")

func _grounded_physics_processing(delta: float) -> void:
	if velocity.x == 0:
		if anim.current_animation != "Idle":
			anim.play("Idle")
	else:
		if anim.current_animation != "Run":
			anim.play("Run Start")
			anim.queue("Run")

func _rising_state_entered() -> void:
	anim.clear_queue()
	anim.play("Jump")

func _rising_physics_processing(delta: float) -> void:
	if is_on_ceiling():
		var decrement_yspeed = -(v_component.get_proper_velocity(2) * 0.2)
		v_component.add_proper_velocity(Vector2(0, decrement_yspeed))

func hold_arrow() -> void:
	update_flying_dir = true
	add_child(current_arrow)
	current_arrow.set_flying_direction(shoot_direction)

func air_stall() -> void:
	if v_component.get_proper_velocity(2) > 0:
		v_component.set_proper_velocity(-air_stall_velocity, 2)
	else:
		v_component.add_proper_velocity(Vector2(0, -air_stall_velocity))

func shoot() -> void:
	update_flying_dir = false
	current_arrow.top_level = true
	current_arrow.global_position = global_position
	if holding_time > max_hold_time:
		current_arrow.fly(true, self)
	else:
		current_arrow.fly(false, self)
	current_arrow = equip_arrow(current_arrow_index)
	state_chart.send_event("CantShoot")
	
	holding_time = 0
	#if shoot_direction == Vector2(0, 1):
		#air_stall()

func _can_shoot_state_entered() -> void:
	if is_holding:
		count_hold_time = true
		hold_arrow()

func _can_shoot_physics_processing(delta: float) -> void:
	if Input.is_action_just_released("shoot"):
		shoot()
	if Input.is_action_just_pressed("shoot"):
		hold_arrow()
		shoot()

func _cannot_shoot_state_entered() -> void:
	await get_tree().create_timer(shoot_delay).timeout
	state_chart.send_event("CanShoot")

func _cant_shoot_physics_processing(delta: float) -> void:
	if Input.is_action_pressed("shoot"):
		is_holding = true

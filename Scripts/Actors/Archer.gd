extends CharacterBody2D
class_name Player

@onready var anim = $Archer/AnimationPlayer

@export_group("Camera")
@export var camera_distance : float
@export var camera_move_duration : float
@export var camera_remote : RemoteTransform2D

@export_group("Arrow")
@export var arrow_remote : RemoteTransform2D
@export_dir var arrows_paths : Array[String]
@export var max_hold_time : float
@export var shoot_Delay : float
@export var max_arrows : int

@export_group("Physics")
@export var v_component : VelocityComponent
@export var move_speed : float
@export var jump_force : float
@export var default_knockback : Vector2 = Vector2(170, 0)
@export var gravity_multiplier : float
@export var jump_buffering_time : float

#@onready var shooting_timer = $Timers/Shooting_Timer as Timer
#@onready var arrow_sprite = $Arrow_Spawner/Arrow_Sprite as Sprite2D
#@onready var jump_buffering = $Timers/Jump_Buffering as Timer
@onready var state_chart = $StateChart as StateChart
 
var gravity : float = ProjectSettings.get_setting("physics/2d/default_gravity")
var can_shoot : bool = true
var current_arrow : Arrow
var holding_time : float = 0.0
var is_holding : bool = false
var facing_direction : int = 1
var current_arrow_index : int
var pos : Vector2
var tween : Tween

@export_category("Para debugar")
@export_range(0 , 8) var Initial_Arrow_Index : int

func _ready():
	Engine.time_scale = 0.5
	velocity = Vector2.ZERO
	setup_camera()
	UiHandler.equiped_arrow_index = Initial_Arrow_Index
	turn(-facing_direction)
	turn(facing_direction)

func _physics_process(delta: float) -> void:
	print(anim.current_animation)
	if !is_on_floor():
		v_component.add_proper_velocity(Vector2(0, get_current_gravity(velocity.y)  * delta))
		if velocity.y >= 0:
			state_chart.send_event("Falling")
		else:
			state_chart.send_event("Rising")
	
	if is_on_floor():
		state_chart.send_event("Grounded")
		v_component.set_proper_velocity(0 as float, 2)
	if Input.is_action_just_pressed("jump") and is_on_floor():
		jump()
	if Input.is_action_just_released("jump") and velocity.y < 0:
		v_component.set_proper_velocity(0.25, 2)
	var direction : int = int(Input.get_axis("left", "right"))
	if direction:
		if facing_direction != direction:
			facing_direction = direction
			turn(facing_direction)
		move(direction)
	else:
		v_component.set_proper_velocity(0 as float, 1)
	
	velocity = v_component.get_total_velocity()
	move_and_slide()

func jump(multiplier : float = 1) -> void:
	v_component.set_proper_velocity(jump_force * multiplier, 2)
	state_chart.send_event("jumped")

func move(facing_dir : int) -> void:
	v_component.set_proper_velocity(move_speed * facing_dir, 1)

func die():
	get_tree().call_deferred("reload_current_scene")

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
	tween.tween_property(self, "pos", final_pos, camera_move_duration)

func setup_camera() -> void:
	camera_remote.remote_path = get_parent().get_camera().get_path()

func take_damage(amount : float) -> void:
	print("Took ", amount, " damage.")

func _rising_to_falling_taken() -> void:
	anim.play("Jump Apex")

func _falling_state_entered() -> void:
	anim.queue("Start Fall")
	anim.queue("Fall")

func _grounded_to_falling_taken() -> void:
	anim.stop()

func _falling_to_grounded_taken() -> void:
	anim.play("Landing")

func _grounded_state_physics_processing(delta: float) -> void:
	if velocity.x == 0:
		if anim.current_animation != "Idle":
			anim.play("Idle")
	else:
		if anim.current_animation != "Run":
			anim.play("Run")

func _rising_state_entered() -> void:
	anim.clear_queue()
	anim.play("Jump")

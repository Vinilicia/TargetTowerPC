extends CharacterBody2D

@export var Move_Speed : float
@export var Jump_Force : float
@export var Default_Knockback : Vector2 = Vector2(170, 0)
@export var Gravity_Multiplier : float
@export var Arrows_paths : Array[String]
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
var current_arrow : CharacterBody2D
var holding_time : float = 0.0
var is_holding : bool = false
var fall_jump_buffer : bool = false
var ledge_jump_buffer : bool = false
var is_jumping : bool = false
var on_floor : bool = true
var facing_direction : int

var current_arrow_index = 5

func _ready():
	current_arrow = equip_arrow(current_arrow_index)

func _process(delta):
	if is_holding == true:
		holding_time += delta
		arrow_sprite.visible = true

	if Input.is_action_pressed("shoot") and can_shoot:
		hold_arrow()
		can_shoot = false
	
	if Input.is_action_just_released("shoot") and is_holding:
		shoot_arrow()
	
	if Input.is_action_just_pressed("Switch_Arrow"):
		current_arrow_index += 1
		print(current_arrow_index % Max_Arrows)
		current_arrow = equip_arrow(current_arrow_index % Max_Arrows)

func hold_arrow() -> void:
	arrow_sprite.visible = true;
	is_holding = true

func receive_knockback(facing_direction : int, force : float, knockback_force : Vector2 = Default_Knockback) -> void:
	knockback_vector = knockback_force * facing_direction * force
	var knockback_tween := get_tree().create_tween()
	knockback_tween.tween_property(self, "knockback_vector", Vector2.ZERO, 0.1)

func shoot_arrow() -> void:
	is_holding = false
	arrow_sprite.visible = false
	get_parent().call_deferred("add_child", current_arrow)
	current_arrow.global_position = arrow_spawner.global_position
	current_arrow.set_direction(sign(arrow_spawner.position.x))
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
	current_arrow.set_direction(sign(arrow_spawner.position.x))
	current_arrow.fly_downward(self)
	arrow_spawner.position = Vector2(8, 0) * facing_direction
	shooting_timer.start(Shoot_Delay)
	current_arrow = equip_arrow(current_arrow_index % Max_Arrows)
	await shooting_timer.timeout
	can_shoot = true

func equip_arrow(array_position : int) -> CharacterBody2D:
	var arrow = load(Arrows_paths[array_position]).instantiate()
	return arrow

func jump(multiplier : float = 1) -> void:
	on_floor = false
	velocity.y = Jump_Force * multiplier
	state_chart.send_event("jumped")

func move(facing_direction : int) -> void:
	velocity.x = facing_direction * Move_Speed

func _on_screen_exit_timer_timeout():
	print_debug("Macarrão")
	die()

func die():
	get_tree().reload_current_scene()

func screen_exited():
	screen_exit_timer.start()

func screen_entered():
	screen_exit_timer.stop()

func get_current_gravity(velocity_in_y : float) -> float:
	if velocity_in_y < 0:
		return gravity
	else:
		return gravity * Gravity_Multiplier

func _physics_process(delta):
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
	var direction : int = Input.get_axis("left", "right")
	if direction:
		facing_direction = direction
	if direction:
		move(direction)
		arrow_spawner.position.x = 8 * direction 
		arrow_sprite.scale.x = direction
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

func _on_falling_state_entered():
	if on_floor == true:
		on_floor = false
		jump_buffering.start(Jump_buffering_time/10 * 6)
		ledge_jump_buffer = true

func _on_floor_state_entered():
	Default_Knockback = Vector2(170, 0)
	is_jumping = false

func _on_floor_state_exited():
	Default_Knockback *= 2
	is_jumping = true

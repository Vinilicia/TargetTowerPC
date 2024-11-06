extends CharacterBody2D


@export var Jump_Force : int 


@onready var wall_detec_for_jump = $Wall_Detec_For_Jump as RayCast2D
@onready var wall_detec = $Wall_Detec as RayCast2D
@onready var speed : int = 0
@onready var reactions = $Reactions
@onready var coll = $Coll


var gravity : float = ProjectSettings.get_setting("physics/2d/default_gravity")
var direction = 0
var frozen : bool = false
var fire_level : int
var health : int = 5

var enter_burn_func : Callable = start_taking_fire_damage
var exit_burn_func : Callable = stop_taking_fire_damage
var update_burn_func : Callable = update_taking_fire_damage

var on_fire : bool = false
func _physics_process(delta):
	$Wall_Detec_For_Jump.target_position.x = 13 * direction
	$Wall_Detec.target_position.x = 13 * direction
	if !is_on_floor():
		velocity.y += gravity * delta
	if wall_detec.is_colliding() and not wall_detec_for_jump.is_colliding():
		jump()
		velocity.x += (10 * direction)
	if direction:
		move(direction, speed)
		direction = 0
	if !frozen:
		move_and_slide()

func _process(delta):
	if health <= 0:
		print_debug("I died")
		queue_free()

func move(dir : int, spd : int):
	velocity.x += dir * spd

func jump(multiplier : float = 1) -> void:
	velocity.y = Jump_Force * multiplier

func get_frozen(freezetime : float) -> void:
	frozen = true
	$Coll.debug_color = $Coll.debug_color + Color(0, 0, 20, 0)
	await get_tree().create_timer(freezetime).timeout
	frozen = false
	$Coll.debug_color = $Coll.debug_color - Color(0, 0, 20, 0)

func fire_ticking() -> void:
	await get_tree().create_timer(2.0 / float(fire_level)).timeout
	print_debug(2.0 / float(fire_level))
	health -= 1
	coll.debug_color += Color(1, 0, 0, 0.9)
	await get_tree().create_timer(0.1).timeout
	coll.debug_color -= Color(1, 0, 0, 0.9)
	fire_level -= 1
	if fire_level > 0:
		fire_ticking()

func start_taking_fire_damage() -> void:
	on_fire = true
	fire_level = 1
	fire_ticking()

func update_taking_fire_damage() -> void:
	fire_level += 1

func stop_taking_fire_damage() -> void:
	pass

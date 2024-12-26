extends CharacterBody2D

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var reactions
@onready var coll = $Coll

var enter_fire_func : Callable = start_burning
var exit_fire_func : Callable = stop_burning
var update_fire_func : Callable = update_burning

func _ready():
	reactions = $React
	coll = $Coll

func _physics_process(delta):
	if !is_on_floor():
		velocity.y += gravity * delta
	move_and_slide()

func start_burning() -> void:
	coll.debug_color += Color(0, 1, 0, 1)

func update_burning() -> void:
	pass

func stop_burning() -> void:
	queue_free()

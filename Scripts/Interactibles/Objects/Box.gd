extends CharacterBody2D

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var reactions
var coll

var massiveness = 1
var enter_burn_func : Callable = start_burning
var exit_burn_func : Callable = stop_burning
 
func _ready():
	reactions = $Reactions
	coll = $Coll

func _physics_process(delta):
	if !is_on_floor():
		velocity.y += gravity * delta
	move_and_slide()

func start_burning() -> void:
	coll.debug_color += Color(0, 1, 0, 1)

func stop_burning() -> void:
	queue_free()

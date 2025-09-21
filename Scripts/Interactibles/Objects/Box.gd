extends CharacterBody2D
#
#var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
#
#var reactions
#@onready var coll = $Coll
#
#var enter_fire_func : Callable = start_burning
#var exit_fire_func : Callable = stop_burning
#var update_fire_func : Callable = update_burning
#
func _physics_process(delta):
	if Input.is_action_just_pressed("jump"):
		velocity = Vector2.LEFT * 50
	move_and_slide()
#
#func start_burning() -> void:
	#coll.debug_color += Color(0, 1, 0, 1)
#
#func update_burning() -> void:
	#pass
#
#func stop_burning() -> void:
	#queue_free()

func burn_out() -> void:
	queue_free()

extends RigidBody2D

@export var min_delay : float
@export var max_delay : float

@export var anim_timer : Timer
@export var sprite : AnimatedSprite2D
@export var value : int
@export var flying_speed : float = 100

var player : Node2D = null

func _ready() -> void:
	anim_timer.start(randf_range(min_delay, max_delay))
	#dgo_to_player()

@export var fly_acceleration: float = 300.0

func _physics_process(delta: float) -> void:
	if player == null:
		return

	var direction = to_local(player.global_position + Vector2(0, -5)).normalized()
	var target_velocity = direction * flying_speed
	linear_velocity = linear_velocity.lerp(target_velocity, delta * 5.0)


func _on_anim_timer_timeout() -> void:
	sprite.play("Shine")
	anim_timer.start(randf_range(min_delay, max_delay))

func get_collected() -> void:
	anim_timer.stop()
	flying_speed = 0.0
	linear_velocity = Vector2.ZERO
	sprite.play("Collected")
	await sprite.animation_finished
	queue_free()

func go_to_player() -> void:
	gravity_scale = 0.0
	collision_mask = 0
	player = get_tree().get_first_node_in_group("Player")

func _on_player_detec_body_entered(body: Node2D) -> void:
	($PlayerDetec as Area2D).set_deferred("monitoring", false)
	get_collected()

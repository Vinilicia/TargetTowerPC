extends CharacterBody2D

@export var min_delay : float
@export var max_delay : float

@export var anim_timer : Timer
@export var sprite : AnimatedSprite2D
@export var value : int = 1
@export var flying_speed : float = 100
@export var fly_acceleration: float = 300.0
@export var v_comp : VelocityComponent

var player : Node2D = null
var on_ground : bool = false

func _ready() -> void:
	anim_timer.start(randf_range(min_delay, max_delay))
	#go_to_player()

func _physics_process(delta: float) -> void:
	if player != null:
		var direction = to_local(player.global_position + Vector2(0, -5)).normalized()
		var target_velocity = direction * flying_speed
		v_comp.proper_velocity.lerp(target_velocity, delta * 5)
	
	if is_on_floor():
		if not on_ground:
			on_ground = true
			v_comp.set_proper_velocity(Vector2.ZERO)
	else:
		v_comp.add_proper_velocity(get_gravity() * delta)
	velocity = v_comp.get_total_velocity()
	move_and_slide()

func _on_anim_timer_timeout() -> void:
	sprite.play("Shine")
	anim_timer.start(randf_range(min_delay, max_delay))

func get_collected() -> void:
	AudioManager.play_song("Money")
	anim_timer.stop()
	flying_speed = 0.0
	v_comp.set_proper_velocity(Vector2.ZERO)
	sprite.play("Collected")
	HudHandler.hud.add_money(value)
	await sprite.animation_finished
	queue_free()

func go_to_player() -> void:
	collision_mask = 0
	player = get_tree().get_first_node_in_group("Player")

func _on_player_detec_body_entered(_body: Node2D) -> void:
	if SaveManager.save_file_data.get_money() == SaveManager.save_file_data.get_max_money():
		return
	else:
		($PlayerDetec as Area2D).set_deferred("monitoring", false)
		get_collected()

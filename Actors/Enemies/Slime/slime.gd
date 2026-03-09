extends Enemy

enum SlimeType { COMMON, FIRE, ICE }

@export var type : SlimeType = SlimeType.COMMON
@export var sprite : Sprite2D

@export_group("Fire Slime")
@export var fire_blob : PackedScene
@export var fire_attack_delay : float = 2.5
@export var fire_sprite_modulate : Color = Color(0, 0, 0, 0.785)

@export_group("Ice Slime")
@export var ice_blob : PackedScene
@export var ice_attack_delay : float = 2.5
@export var ice_sprite_modulate : Color = Color(0, 0, 0, 0.785)

@export_group("General")

@export var blob : PackedScene
@export var sight_area : Area2D
@export var blob_spawner : Marker2D
@export var ice_manager : IceManager
@export var look_around_timer : Timer
@export var attack_timer : Timer
@export var default_attack_delay : float = 2.0
@export var lose_sight_timer : Timer
@export var default_sprite_modulate : Color = Color(0, 0, 0, 0.785)

var player_is_nearby : bool = false
var player_target : CharacterBody2D
var can_engage : bool = false
var current_blob : PackedScene = null

func can_attack() -> bool:
	return player_is_nearby \
		and can_engage \
		and is_instance_valid(player_target)

func try_start_attack() -> void:
	if can_attack() and attack_timer.is_stopped():
		attack_timer.start()

func stop_attack() -> void:
	if not attack_timer.is_stopped():
		attack_timer.stop()

func change_type(new_type : SlimeType) -> void:
	match new_type:
		SlimeType.COMMON:
			attack_timer.wait_time = default_attack_delay
			sprite.modulate = default_sprite_modulate
			current_blob = blob
		SlimeType.FIRE:
			attack_timer.wait_time = fire_attack_delay
			sprite.modulate = fire_sprite_modulate
			current_blob = fire_blob
		SlimeType.ICE:
			attack_timer.wait_time = ice_attack_delay
			sprite.modulate = ice_sprite_modulate
			current_blob = ice_blob
	type = new_type

func _ready() -> void:
	change_type(type)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		v_component.add_proper_velocity(get_gravity() * delta)
	else:
		v_component.set_proper_velocity(Vector2.ZERO)

	velocity = v_component.get_total_velocity()
	move_and_slide()

func _throw_blob() -> void:
	if not can_attack():
		return

	var instance = current_blob.instantiate()
	get_parent().call_deferred("add_child", instance)
	instance.top_level = true
	instance.global_position = blob_spawner.global_position
	instance.call_deferred("arc_throw", player_target.global_position)

func _player_entered_sight_area(player: Node2D) -> void:
	player_target = player
	player_is_nearby = true

	if lose_sight_timer.is_inside_tree():
		lose_sight_timer.stop()
	try_start_attack()

func _player_exited_sight_area(_player: Node2D) -> void:
	if lose_sight_timer.is_inside_tree():
		lose_sight_timer.start()

func _on_lose_sight_timer_timeout() -> void:
	player_is_nearby = false
	player_target = null
	stop_attack()

func _on_screen_entered() -> void:
	can_engage = true
	try_start_attack()

func _on_screen_exited() -> void:
	can_engage = false
	stop_attack()

func _on_attack_timer_timeout() -> void:
	_throw_blob()

func ran_out_of_health() -> void:
	queue_free()

func _on_fire_manager_caught_fire() -> void:
	change_type(SlimeType.FIRE)

func _on_ice_manager_froze() -> void:
	change_type(SlimeType.ICE)

extends Enemy

enum SlimeType { COMMON, FIRE }

@export var type : SlimeType = SlimeType.COMMON
@export var sprite : Sprite2D

@export_group("Fire Slime")
@onready var fire_blob = preload("res://Scenes/Actors/Enemies/Fire_Slime_Blob.tscn")
@export var fire_attack_delay : float = 2.5
@export var fire_sprite_modulate : Color = Color(0, 0, 0, 0.785)

@export_group("General")
@export_enum("Left", "Right") var direction : int

@onready var blob = preload("res://Scenes/Actors/Enemies/Slime_Blob.tscn")
@export var sight_area : Area2D
@export var blob_spawner : Marker2D
@export var look_around_timer : Timer
@export var attack_timer : Timer
@export var default_attack_delay : float = 2.0
@export var lose_sight_timer : Timer
@export var default_sprite_modulate : Color = Color(0, 0, 0, 0.785)

var player_is_nearby : bool = false
var player_target : CharacterBody2D
var timer_off : bool = false
var angle : float
var current_blob : PackedScene = null

func change_type(new_type : SlimeType) -> void:
	if new_type == SlimeType.COMMON:
		attack_timer.wait_time = default_attack_delay
		sprite.modulate = default_sprite_modulate
		current_blob = blob
	elif new_type == SlimeType.FIRE:
		attack_timer.wait_time = fire_attack_delay
		sprite.modulate = fire_sprite_modulate
		current_blob = fire_blob

	type = new_type

func _ready() -> void:
	change_type(type)
	if direction == 0:
		direction = -1
	else:
		direction = 1
		flip()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		v_component.add_proper_velocity(get_gravity() * delta)
	else:
		v_component.set_proper_velocity(Vector2.ZERO)
	if player_is_nearby:
		handle_attack()
	velocity = v_component.get_total_velocity()
	move_and_slide()

func _throw_blob() -> void:
	timer_off = false
	var instance = current_blob.instantiate()
	get_parent().call_deferred("add_child", instance)
	instance.top_level = true
	instance.global_position = blob_spawner.global_position
	instance.call_deferred("arc_throw", player_target.position)
	
func _player_entered_sight_area(player: Node2D) -> void:
	player_target = player
	player_is_nearby = true
	if !look_around_timer.is_stopped():
		look_around_timer.stop()
	if attack_timer.is_stopped():
		attack_timer.start()
	if !lose_sight_timer.is_stopped():
		lose_sight_timer.stop()

func _player_exited_sight_area(_player: Node2D) -> void:
	if lose_sight_timer.is_inside_tree():
		lose_sight_timer.start()

func flip() -> void:
	sight_area.position.x *= -1

func ran_out_of_health() -> void:
	queue_free()

func _on_look_around_timer_timeout() -> void:
	flip()

func handle_attack() -> void:
	if position.x - player_target.position.x > 0:
		if direction != -1:
			direction = -1
			flip()
	else:
		if direction != 1:
			direction = 1
			flip()

func _on_attack_timer_timeout() -> void:
	_throw_blob()

func _on_lose_sight_timer_timeout() -> void:
	player_is_nearby = false
	if attack_timer.is_inside_tree():
		attack_timer.stop()
	if look_around_timer.is_inside_tree():
		look_around_timer.start()

func _on_fire_manager_caught_fire() -> void:
	change_type(SlimeType.FIRE)

func _on_screen_exited() -> void:
	if lose_sight_timer and !lose_sight_timer.is_stopped():
		lose_sight_timer.stop()
		_on_lose_sight_timer_timeout()

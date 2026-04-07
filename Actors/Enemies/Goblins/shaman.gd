extends Enemy

@export var line_of_sight : RayCast2D
@export var attack_timer : Timer
@export var bat_scene : PackedScene
@export var bolt_scene : PackedScene

@export var base_attack_delay := 4.0
@export var attack_delay_variation := 0.5
@export var giving_up_delay := 0.4

@export var summon_bat_chance := 1.0
@export var magic_bolt_texture : Texture2D
@export var magic_bolt_scale : Vector2
@export var magic_bolt_speed : float = 200
@export var projectile_lifespan : float = 5.0

var saw_player := false
var player : Player = null

var engaging_state := false
var idle_state := true
var preparing_attack := false

func _ready() -> void:
	super._ready()

func _physics_process(delta: float) -> void:
	if player:
		if look_for_player():
			if !saw_player:
				saw_player = true
				engaging_state = true
		elif saw_player:
			saw_player = false
			get_tree().create_timer(giving_up_delay).timeout.connect(give_up_chase)
	elif engaging_state:
		engaging_state = false
		saw_player = false
		idle_state = true
		preparing_attack = false
	
	if engaging_state:
		if !preparing_attack:
			preparing_attack = true
			start_attack_timer()
	
	grounded_behaviour(delta)

func start_attack_timer() -> void:
	var random_delay = randf_range(base_attack_delay - attack_delay_variation,
								   base_attack_delay + attack_delay_variation)
	attack_timer.start(random_delay)

func get_random_empty_position() -> Vector2:
	if !player:
		printerr("Sem player ao tentar escolher posição de Spawn!!")
		return Vector2.ZERO
	var space := get_world_2d().direct_space_state
	var distance_to_player := 70

	var max_attempts := 20
	for i in range(max_attempts):
		var x_sign : int = sign(randi_range(1, 2) - 1.5)
		var rand_angle : float = deg_to_rad(randi_range(-20, -10))
		var rand_vec := (Vector2.RIGHT.rotated(rand_angle) * distance_to_player)
		rand_vec = Vector2(rand_vec.x * x_sign, rand_vec.y)
		var random_pos = rand_vec + player.global_position

		# Checa colisão no ponto
		var shape := CircleShape2D.new()
		shape.radius = 8.0

		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = shape
		query.transform = Transform2D(0, random_pos)
		query.collision_mask = collision_mask

		var result := space.intersect_shape(query, 1)
		if result.is_empty():
			return random_pos

	return Vector2.ZERO

func summon_bat() -> void:
	modulate = Color(1, 0, 0, 1)
	await get_tree().create_timer(0.5).timeout
	var new_bat = bat_scene.instantiate()
	new_bat.starts_chasing = true
	var bat_pos := get_random_empty_position()
	if bat_pos != Vector2.ZERO:
		new_bat.position = bat_pos
	get_parent().call_deferred("add_child", new_bat)
	await get_tree().create_timer(0.5).timeout
	modulate = Color(1, 1, 1, 1)

func shoot_bolt() -> void:
	if !player:
		printerr("Player enixestente ao tentar um ataque de Bolt!!")
		return
	var direction : Vector2 = to_local(player.global_position + Vector2(0, -10)).normalized()
	modulate = Color(0, 1, 0, 1)
	await get_tree().create_timer(0.3).timeout
	var new_bolt : Node2D = bolt_scene.instantiate()
	new_bolt.top_level = true
	new_bolt.position = global_position
	new_bolt.rotation = direction.angle() - (PI / 2)
	get_parent().call_deferred("add_child", new_bolt)
	new_bolt.call_deferred("fly", direction)
	await get_tree().create_timer(0.5).timeout
	modulate = Color(1, 1, 1, 1)

func attack() -> void:
	if randf() < summon_bat_chance:
		summon_bat()
	else:
		shoot_bolt()
	start_attack_timer()

func give_up_chase() -> void:
	if !saw_player:
		engaging_state = false
		preparing_attack = false
		idle_state = true

func look_for_player() -> bool:
	line_of_sight.target_position = to_local(player.global_position)
	line_of_sight.force_raycast_update()
	if line_of_sight.is_colliding():
		if line_of_sight.get_collider() is Player:
			return true
	return false

func _on_visible_notifier_screen_entered() -> void:
	player = get_tree().get_first_node_in_group("Player")
	if !player:
		printerr("Player não encontrado no grupo PLAYER!!!")

func _on_visible_notifier_screen_exited() -> void:
	player = null

func _on_attack_timer_timeout() -> void:
	if engaging_state:
		attack()

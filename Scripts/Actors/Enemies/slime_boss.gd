extends Boss

@export var jump_force : Vector2
@export var spinning_speed : float = 90
@export var raycast : RayCast2D
@export var markers_node : Node2D

@export_group("Behaviour")
@export var default_timer : float
@export var default_timer_offset : float
@export var gravity_scale : float = 0.6
@export var bounce_delay := 0.1
@export_range(0, 1, 0.1) var bounce_chance : float
@export_range(0, 1, 0.1) var pursue_chance : float
@export_range(0, 1, 0.1) var shoot_chance : float
@export_range(0, 1, 0.1) var dispersed_volley_chance : float
@export_range(0, 1, 0.1) var patterned_volley_chance : float

var top_left_marker : Marker2D
var top_right_marker : Marker2D
var bottom_left_marker : Marker2D
var bottom_right_marker : Marker2D
var where_is : String
var engaging_time : float = 0.0
var current_time : float = 10
var jumping := false
var jump_targets: Array = []

@onready var blob : PackedScene = preload("res://Scenes/Actors/Enemies/Slime_Blob.tscn")

signal landed

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	for marker : Marker2D in markers_node.get_children():
		marker.top_level = true
		marker.position += global_position
	top_left_marker = markers_node.get_child(0)
	top_right_marker = markers_node.get_child(1)
	bottom_right_marker = markers_node.get_child(2)
	bottom_left_marker = markers_node.get_child(3)
	find_where_is()
	generate_new_time()

func find_where_is() -> void:
	var closest : float = 200000
	if (top_left_marker.global_position - global_position).length() < closest:
		where_is = "Top_left"
		closest = (top_left_marker.global_position - global_position).length()
	if (top_right_marker.global_position - global_position).length() < closest:
		where_is = "Top_right"
		closest = (top_right_marker.global_position - global_position).length()
	if (bottom_left_marker.global_position - global_position).length() < closest:
		where_is = "Bottom_left"
		closest = (bottom_left_marker.global_position - global_position).length()
	if (bottom_right_marker.global_position - global_position).length() < closest:
		where_is = "Bottom_right"
		closest = (bottom_right_marker.global_position - global_position).length()

func generate_new_time() -> void:
	current_time = randf_range(default_timer - default_timer_offset, default_timer + default_timer_offset)
	engaging_time = 0.0

func _physics_process(delta: float) -> void:
	if engaging:
		engaging_time += delta
		if engaging_time > current_time:
			generate_new_time()
			choose_attack()
		raycast.target_position = to_local(player.global_position)
	grounded_behaviour(delta * gravity_scale)
	
	if jumping and is_on_floor():
		jumping = false
		on_land()



func on_land() -> void:
	v_component.set_proper_velocity(0.0, 1)
	
	await get_tree().create_timer(bounce_delay).timeout
	if jump_targets.size() > 0:
		perform_jump(jump_targets.pop_front())
	else:
		find_where_is()
		engaging = true
	landed.emit()

func jump_to_high_ground() -> void:
	var target : Vector2
	if where_is == "Bottom_left":
		target = top_right_marker.global_position
	elif where_is == "Bottom_right":
		target = top_left_marker.global_position
	perform_jump(target, -20)

var num_ground_attacks : int = 0
var num_top_attacks : int = 0
@export var ground_attack_max := 3
@export var top_attack_max := 2

func choose_attack() -> void:
	engaging = false
	if where_is == "Bottom_left" || where_is == "Bottom_right":
		if num_ground_attacks < ground_attack_max:
			num_ground_attacks += 1
			var rand := randf()
			if rand < bounce_chance:
				bounce()
			elif rand < bounce_chance + pursue_chance:
				pursue()
			elif rand < bounce_chance + pursue_chance + shoot_chance:
				straight_shot()
				engaging = true
			else:
				push_error("SOMA DE CHANCES DE ATAQUE GROUNDED NÃO É IGUAL A 1!!!")
		else:
			jump_to_high_ground()
			num_ground_attacks = 0
	else:
		if num_top_attacks < top_attack_max:
			num_top_attacks += 1
			var rand := randf()
			if rand < dispersed_volley_chance:
				dispersed_volley()
			elif rand < dispersed_volley_chance + patterned_volley_chance:
				patterned_volley()
			else:
				push_error("SOMA DE CHANCES DE ATAQUE TOP NÃO É IGUAL A 1!!!")
		else:
			num_top_attacks = 0
			pursue()

@export var num_volley_attacks : int = 5

func dispersed_volley() -> void:
	var targets : Array[Vector2] = []
	var start := bottom_left_marker.global_position
	var end := bottom_right_marker.global_position
	for i in range(num_volley_attacks):
		var new_target : Vector2 = start + ((end - start) * (float(i) / float(num_volley_attacks - 1)))
		new_target = to_local(new_target) + position
		targets.append(new_target)
	for i in range(num_volley_attacks):
		var mirror = num_volley_attacks - 1 - i
		shoot(targets[i])
		shoot(targets[mirror])
		await get_tree().create_timer(0.4).timeout
	engaging = true
@export var num_patterned_shots : int = 6
@export var patterned_rand_x_offset : float = 20

func patterned_volley() -> void:
	var targets : Array[Vector2] = []
	var start := bottom_left_marker.global_position
	var end := bottom_right_marker.global_position
	var full_delay := false
	for j in range(num_patterned_shots):
		var num := randi_range(4, 5)
		for i in range(num):
			var this_start = start + Vector2(patterned_rand_x_offset, 0) * randf_range(-1, 1)
			var this_end = end + Vector2(patterned_rand_x_offset, 0) * randf_range(-1, 1)
			var new_target : Vector2 = this_start + ((this_end - this_start) * (float(i) / float(num - 1)))
			new_target = to_local(new_target) + position
			targets.append(new_target)
		if full_delay:
			for i in range(num):
				shoot(targets[i])
				await get_tree().create_timer(0.1).timeout
			await get_tree().create_timer(1.0).timeout
		else:
			for i in range(num):
				shoot(targets[num - i - 1])
				await get_tree().create_timer(0.1).timeout
			await get_tree().create_timer(0.3).timeout
		targets.clear()
		full_delay = !full_delay
	engaging = true

func straight_shot() -> void:
	modulate = Color(0.7, 0, 0, 1)
	await get_tree().create_timer(0.4).timeout
	shoot(to_local(player.global_position + position + Vector2(0, 5)), true)
	modulate = Color(1, 1, 1, 1)

func shoot(target : Vector2, straight : bool = false) -> void:
	var blob_instance : SlimeBlob = blob.instantiate()
	get_parent().call_deferred("add_child", blob_instance)
	blob_instance.position = position
	blob_instance.general_damage = false
	if straight:
		blob_instance.call_deferred("straight_throw", target)
	else:
		blob_instance.call_deferred("arc_throw", target)
	
@export var num_consecutive_jumps := 5

func pursue() -> void:
	for i in range(num_consecutive_jumps):
		engaging = false
		var target = player.global_position
		perform_jump(target, 0, 60)
		await landed
		engaging = true

func bounce() -> void:
	var end: Vector2
	var start := global_position
	if where_is == "Bottom_left":
		end = bottom_right_marker.global_position
		start = bottom_left_marker.global_position
	else:
		end = bottom_left_marker.global_position
		start = bottom_right_marker.global_position

	var direction := (end - start)

	var p1 := start + direction * (1.0 / 3.0)
	var p2 := start + direction * (2.0 / 3.0)
	jump_targets = [start, p1, p2, end]
	perform_jump(jump_targets.pop_front(), )


func perform_jump(target: Vector2, offset : float = 10, height_increase : float  = 50) -> void:
	jumping = true
	var start := global_position
	var end := target

	var x0 = start.x
	var y0 = start.y
	var xf = end.x - (offset if start.x < end.x else -offset)
	var yf = end.y

	var g = get_gravity().y * gravity_scale

	var highest_point = min(y0, yf)
	var yMax = highest_point - height_increase

	var vy = -sqrt(2.0 * g * abs(yMax - y0)) 
	var t_up = abs(vy) / g

	var t_down = sqrt(2.0 * abs(yf - yMax) / g)

	var total_t = t_up + t_down

	var vx = (xf - x0) / total_t
	
	v_component.set_proper_velocity(Vector2(vx, vy))

func die() -> void:
	AudioManager.play_song("BossDeath")
	super.die()

func grounded_behaviour(delta : float) -> void:
	if !is_on_floor():
		apply_gravity(delta)
	
	velocity = v_component.get_total_velocity()
	move_and_slide()

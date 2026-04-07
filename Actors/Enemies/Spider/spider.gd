extends Enemy

const PIVOT_OFFSET := Vector2(0, 4.0) # ponto fixo relativo ao inimigo

@export var speed: float = 35.0
@export var movedir: float = 1.0
@export var start_surface: surfaceState = surfaceState.ground
@export var fall_speed : float = 150.0

@export var up_ray: RayCast2D
@export var down_ray: RayCast2D
@export var backup_down_ray: RayCast2D
@export var side_ray: RayCast2D
@export var plat_detec : Area2D

enum moveState{ walking, falling, descending }
enum surfaceState{ ground, wall_left, wall_right, ceiling }

var direction: Vector2
var waittime: float = 1.0
var rotating := false
var is_ready : bool = false
var surface_state : surfaceState = surfaceState.ground
var move_state : moveState = moveState.falling

func set_start_rotation() -> void:
	match start_surface:
		surfaceState.ground:
			pass
		surfaceState.wall_left:
			rotate(deg_to_rad(90))
		surfaceState.wall_right:
			rotate(deg_to_rad(-90))
		surfaceState.ceiling:
			rotate(deg_to_rad(180))

func snap_to_surface() -> void:
	if down_ray.is_colliding():
		position = down_ray.get_collision_point() - Vector2(0, $BodyCollision.scale.y / 2 - 1).rotated(rotation)

func _ready() -> void:
	super._ready()
	var original_down_ray_pos := down_ray.target_position
	down_ray.target_position = Vector2(0, 50)
	set_start_rotation()
	await get_tree().create_timer(1).timeout
	if down_ray.is_colliding():
		snap_to_surface()
		down_ray.target_position = original_down_ray_pos
		is_ready = true
		move_state = moveState.walking
	else:
		push_error("ARANHA " + name + " NÃO ENCONTROU SUPERFÍCIE!")

func is_not_grounded() -> bool:
	match surface_state:
		surfaceState.ground:
			return not is_on_floor()
		surfaceState.ceiling:
			return not is_on_ceiling()
		_:
			return not is_on_wall()

func walking_state_process() -> void:
	down_ray.force_update_transform()
	down_ray.force_raycast_update()
	backup_down_ray.force_update_transform()
	backup_down_ray.force_raycast_update()
	force_update_transform()
	if is_not_grounded() and !plat_detec.has_overlapping_bodies():
		if !down_ray.is_colliding():
			move_state = moveState.falling
			v_component.set_proper_velocity(Vector2.ZERO)
			return
	if !down_ray.is_colliding() and backup_down_ray.is_colliding():
		rotate_and_snap(90 * movedir)
	elif movedir != sign(backup_down_ray.position.x) or direction == Vector2.ZERO:
		update_direction()
		v_component.set_proper_velocity(direction * speed, 1)

	if side_ray.is_colliding():
		if surface_state == surfaceState.ceiling and randf() < 0.7:
			movedir *= -1
			update_direction()
		else:
			rotate_and_snap(90 * -movedir)
	

	if surface_state == surfaceState.ceiling:
		if up_ray.is_colliding():
			var collider = up_ray.get_collider()
			if collider is Player:
				rotate_and_snap(180)
				fall_from_ceiling()

func _physics_process(delta: float) -> void:
	if !is_ready:
		return
	if rotating:
		return
	
	if move_state == moveState.walking:
		walking_state_process()
	elif move_state == moveState.falling:
		if is_on_floor():
			await rotate_and_snap(-rotation_degrees)
			move_state = moveState.walking
			choose_random_direction()
		grounded_behaviour(delta)
	
	velocity = v_component.get_total_velocity()
	move_and_slide()

func fall_from_ceiling() -> void:
	move_state = moveState.descending
	v_component.set_proper_velocity(Vector2(0, fall_speed))
	get_tree().process_frame.connect(check_to_stop_fall)

func check_to_stop_fall() -> void:
	if is_on_floor():
		move_state = moveState.walking
		v_component.set_proper_velocity(Vector2.ZERO)
		get_tree().process_frame.disconnect(check_to_stop_fall)

func update_direction() -> void:
	var angle = rotation
	direction = Vector2.from_angle(angle)
	direction.x = round(direction.x)
	direction.y = round(direction.y)
	direction *= movedir
	side_ray.target_position.x = abs(side_ray.target_position.x) * movedir
	backup_down_ray.position.x = abs(backup_down_ray.position.x) * -movedir
	down_ray.position.x = abs(down_ray.position.x) * -movedir

func rotate_and_snap(degrees: float, duration := 0.3) -> void:
	if rotating:
		return
	rotating = true

	var abs_deg := absf(degrees)
	var use_pivot := abs_deg < 91.0 
	
	var total_angle_rad := deg_to_rad(degrees)
	var state := {"last_angle": 0.0,
		"first": true,
		}

	var tween := create_tween()
	tween.tween_method(func(current_tweened_angle: float):
		if state.first:
			state.first = false
		var delta_angle: float = current_tweened_angle - state.last_angle
		state.last_angle = current_tweened_angle
		
		if use_pivot:
			var local_pivot_pos := Vector2(
				PIVOT_OFFSET.x * movedir * -signf(degrees), 
				PIVOT_OFFSET.y * signf(degrees) * movedir
			).rotated(rotation)
			
			var current_pivot_global = global_position + local_pivot_pos
			
			# 3. Rotacionamos a posição global em relação a esse pivô instantâneo
			var diff = global_position - current_pivot_global
			global_position = current_pivot_global + diff.rotated(delta_angle)
		
		# 4. Aplica a rotação (seja com pivô ou no próprio eixo)
		rotation += delta_angle
		
	, 0.0, total_angle_rad, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await tween.finished
	change_state()
	set_deferred("rotating", false)
	snap_to_surface.call_deferred()

func change_state() -> void:
	var vector := Vector2(1, 0).rotated(rotation)
	if vector.is_equal_approx(Vector2.RIGHT):
		surface_state = surfaceState.ground
	elif vector.is_equal_approx(Vector2.UP):
		surface_state = surfaceState.wall_left
	elif vector.is_equal_approx(Vector2.DOWN):
		surface_state = surfaceState.wall_right
	elif vector.is_equal_approx(Vector2.LEFT):
		surface_state = surfaceState.ceiling

func choose_random_direction() -> void:
	print("Dir")
	var rand : float = randf()
	if rand < 0.5:
		movedir = -1.0
		update_direction()
	else:
		movedir = 1.0
		update_direction()

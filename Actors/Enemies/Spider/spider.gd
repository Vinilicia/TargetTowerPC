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
@export var ice_manager : IceManager

enum moveState{ walking, falling, descending }
enum surfaceState{ ground, wall_left, wall_right, ceiling }

var direction: Vector2
var waittime: float = 1.0
var rotating := false
var is_ready : bool = false
var on_plat :int = 0
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
	position = down_ray.get_collision_point() - Vector2(0, $BodyCollision.scale.y / 2 - 1).rotated(rotation)

func _ready() -> void:
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
	return not is_on_floor() and not is_on_wall() and not is_on_ceiling()

func _physics_process(delta: float) -> void:
	if !is_ready:
		return
	if rotating:
		return
	
	if move_state == moveState.walking:
	
		down_ray.force_update_transform()
		down_ray.force_raycast_update()
		backup_down_ray.force_update_transform()
		backup_down_ray.force_raycast_update()
		force_update_transform()
		
		if is_not_grounded():
			if to_local(down_ray.get_collision_point()).length() - ($BodyCollision.scale.x / 2) < 2.0:
				snap_to_surface()
			else:
				move_state = moveState.falling
				v_component.set_proper_velocity(Vector2.ZERO)
				return
		
		if down_ray.is_colliding():
			update_direction()
			v_component.set_proper_velocity(direction * speed, 1)
		elif backup_down_ray.is_colliding():
			rotate_and_snap(90 * movedir)
			position += Vector2(-movedir * direction.y, movedir * direction.x) * 10

		if side_ray.is_colliding():
			if surface_state == surfaceState.ceiling and randf() < 0.7:
				movedir *= -1
				update_direction()
				side_ray.set_deferred("target_position.x", abs(side_ray.target_position.x) * movedir)
			else:
				rotate_and_snap(90 * -movedir)

		if surface_state == surfaceState.ceiling:
			if up_ray.is_colliding():
				var collider = up_ray.get_collider()
				if collider is Player:
					rotate_and_snap(180)
					fall_from_ceiling()
	
	elif move_state == moveState.falling:
		if is_on_floor():
			rotate_and_snap(-rotation_degrees)
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

func _on_floor_timer_timeout() -> void:
	if surface_state != surfaceState.ground:
		return

	if up_ray.is_colliding() and randf() < 0.3:
		rotate_and_snap(180)

func rotate_and_snap(degrees: float, duration := 0.3) -> void:
	if rotating:
		return
	rotating = true

	var abs_deg := absf(degrees)
	var use_pivot := abs_deg < 91.0  # ou abs_deg < 91.0 se quiser tolerância

	var pivot: Vector2
	if use_pivot:
		# Pivô fixo relativo
		var local_pivot := Vector2(PIVOT_OFFSET.x * movedir * -signf(degrees), PIVOT_OFFSET.y * signf(degrees) * movedir)
		pivot = global_position + local_pivot.rotated(rotation)
	else:
		# Se não for 90°, gira no próprio eixo
		pivot = global_position

	# Estados iniciais
	var start_rotation := rotation
	var target_rotation := rotation + deg_to_rad(degrees)
	var start_position := global_position

	var to_pivot := start_position - pivot
	
	# Tween de rotação
	var tween := create_tween()
	tween.tween_method(func(value):
		var current_angle: float = lerp(start_rotation, target_rotation, value)
		var rotated_offset := to_pivot.rotated(current_angle - start_rotation)
		global_position = pivot + rotated_offset
		rotation = current_angle
	, 0.0, 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await tween.finished
	change_state()
	rotating = false

func change_state() -> void:
	if abs(rotation_degrees) < 2 and abs(rotation_degrees) > -2:
		surface_state = surfaceState.ground
	elif rotation_degrees < 91 and rotation_degrees > 89:
		surface_state = surfaceState.wall_left
	elif rotation_degrees < -89 and rotation_degrees > 91:
		surface_state = surfaceState.wall_right
	elif abs(rotation_degrees) < 181 and abs(rotation_degrees) > 179:
		surface_state = surfaceState.ceiling

func choose_random_direction() -> void:
	var rand : float = randf()
	if rand < 0.5:
		movedir = -1.0
		update_direction()
	else:
		movedir = 1.0
		update_direction()

func _on_plat_detec_body_entered(_body: Node2D) -> void:
	on_plat += 1

func _on_plat_detec_body_exited(_body: Node2D) -> void:
	on_plat -= 1

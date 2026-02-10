extends Enemy

@export var speed: float = 35.0
@export var movedir: float = 1.0
@export_enum("floor", "wall_left", "wall_right", "ceiling") var start_surface: String = "floor"
@export var fall_speed := 100.0

@export var up_ray: RayCast2D
@export var down_ray: RayCast2D
@export var side_ray: RayCast2D

var direction: Vector2
var waittime: float = 1.0
var rotating := false
var surface_state: String = "floor"
var _floor_timer: Timer
var is_ready : bool = false
var on_plat :int = 0


func _ready() -> void:
	match start_surface:
		"floor":
			rotation_degrees = 0
			surface_state = "floor"
		"ceiling":
			rotation_degrees = 180
			surface_state = "ceiling"
		"wall_left":
			rotation_degrees = -90  
			surface_state = "wall"
			movedir = -1.0
		"wall_right":
			rotation_degrees = 90
			surface_state = "wall"
			movedir = 1.0

	side_ray.target_position.x = abs(side_ray.target_position.x) * movedir
	update_direction()


	await get_tree().process_frame
	
	_floor_timer = Timer.new()
	_floor_timer.wait_time = 3.0
	_floor_timer.autostart = false
	_floor_timer.one_shot = false
	add_child(_floor_timer)
	_floor_timer.timeout.connect(_on_floor_timer_timeout)

	_on_surface_changed(surface_state)
	await get_tree().create_timer(0.5).timeout
	is_ready = true

# =====================================================
# RESTANTE DAS FUNÇÕES (mantidas, as que você já tinha)
# =====================================================

func _snap_to_surface_on_spawn() -> void:
	var ray := down_ray
	var axis := Vector2.DOWN
	var original_length := ray.target_position.length()

	ray.target_position = axis.normalized() * 500
	ray.force_raycast_update()

	if ray.is_colliding():
		var collision_point := ray.get_collision_point()
		var to_point := collision_point - global_position
		global_position += to_point.limit_length(500)

	ray.target_position = axis.normalized() * original_length

func is_not_grounded() -> bool:
	return not is_on_floor() and not is_on_wall() and not is_on_ceiling()

func _physics_process(_delta: float) -> void:
	if !is_ready:
		return
	if rotating:
		return
	if is_not_grounded() and !on_plat:
		_snap_to_surface_on_spawn()
	if down_ray.is_colliding():
		update_direction()
		v_component.set_proper_velocity(direction * speed, 1)
		waittime -= 0.1
	else:
		if waittime < 1.0:
			_rotate_and_snap(90 * movedir)
		position += Vector2(-movedir * direction.y, movedir * direction.x) * 10
		waittime = 1.0

	if side_ray.is_colliding():
		if surface_state == "ceiling" and randf() < 0.7:
			movedir *= -1
			update_direction()
			await get_tree().process_frame
			side_ray.target_position.x = abs(side_ray.target_position.x) * movedir
		else:
			_rotate_and_snap(90 * -movedir)

	if surface_state == "ceiling":
		if up_ray.is_colliding():
			var collider = up_ray.get_collider()
			if collider is Player:
				_rotate_and_snap(180)

	velocity = v_component.get_total_velocity()
	move_and_slide()


func update_direction() -> void:
	var angle = rotation
	direction = Vector2.from_angle(angle)
	direction.x = round(direction.x)
	direction.y = round(direction.y)
	direction *= movedir
	side_ray.target_position.x = abs(side_ray.target_position.x) * movedir


# Timer handler existente (mantive como você tinha)
func _on_floor_timer_timeout() -> void:
	if surface_state != "floor":
		return

	if up_ray.is_colliding() and randf() < 0.3:
		_rotate_and_snap(180)


const PIVOT_OFFSET := Vector2(-1, 4.0) # ponto fixo relativo ao inimigo

func _rotate_and_snap(degrees: float, duration := 0.3) -> void:

	if !_floor_timer.is_stopped():
		_floor_timer.stop()
	if rotating:
		return
	rotating = true

	var abs_deg := absf(degrees)
	var use_pivot := abs_deg < 91.0  # ou abs_deg < 91.0 se quiser tolerância

	var pivot: Vector2
	if use_pivot:
		# Pivô fixo relativo
		var local_pivot := Vector2(PIVOT_OFFSET.x * movedir, PIVOT_OFFSET.y * signf(degrees) * movedir)
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

	
	# Pós-rotação
	await get_tree().process_frame
	down_ray.force_raycast_update()
	if down_ray.is_colliding():
		update_direction()
		_update_surface_state()
	else:
		if surface_state == "ceiling":
			_fall_from_ceiling_with_tween()
		elif surface_state == "floor":
			_climb_to_ceiling_with_tween()

	rotating = false




# (mantive suas funções de climb/fall/randomize etc — não as repito aqui para não alongar demais)
# ... _climb_to_ceiling_with_tween(), _fall_from_ceiling_with_tween(), _randomize_direction_after_fall() ...


# =====================================================
# DETECÇÃO DE SUPERFÍCIE (agora com detecção de transição)
# =====================================================
func _update_surface_state() -> void:
	var deg := fposmod(round(rotation_degrees), 360)
	var new_state: String

	match deg:
		0:
			new_state = "floor"
		180:
			new_state = "ceiling"
		90, 270:
			new_state = "wall"
		_:
			if deg > 45 and deg < 135:
				new_state = "wall"
			elif deg > 135 and deg < 225:
				new_state = "ceiling"
			elif deg > 225 and deg < 315:
				new_state = "wall"
			else:
				new_state = "floor"

	# Se mudou, chama handler de transição
	if new_state != surface_state:
		surface_state = new_state
		_on_surface_changed(new_state)


# Quando muda de superfície, start/stop do timer
func _on_surface_changed( new_state: String) -> void:
	up_ray.enabled = false
	# Start timer quando entrar em floor
	if new_state == "floor":
		if _floor_timer and _floor_timer.is_stopped():
			_floor_timer.start()
	elif new_state == "ceiling":
		if _floor_timer and not _floor_timer.is_stopped():
			_floor_timer.stop()
		up_ray.force_raycast_update()
		await get_tree().create_timer(0.4).timeout
		up_ray.enabled = true
		up_ray.force_raycast_update()
	else:
		# Para o timer em qualquer outro estado
		if _floor_timer and not _floor_timer.is_stopped():
			_floor_timer.stop()

# =====================================================
# 🧗 SUBIDA SUAVE COM TWEEN (quando sobe do chão)
# =====================================================
func _climb_to_ceiling_with_tween() -> void:
	up_ray.enabled = false
	side_ray.enabled = false
	var fall_distance := 300.0
	var fall_target := global_position + Vector2.DOWN.rotated(rotation) * fall_distance

	# Verifica colisão com o chão
	down_ray.target_position = Vector2(0, fall_distance)
	down_ray.force_raycast_update()

	if down_ray.is_colliding():
		fall_target = down_ray.get_collision_point() + Vector2(0, -3)
		fall_distance = global_position.distance_to(fall_target)

	# Mantém uma velocidade de queda de ~30 px/s
	var fall_time := fall_distance / fall_speed

	# Cria o tween
	var tween := create_tween()
	tween.tween_property(self, "global_position", fall_target, fall_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	up_ray.enabled = true
	side_ray.enabled = true
	down_ray.target_position = Vector2(0, 7)

	# Define novo estado e direção aleatória
	_update_surface_state()
	_randomize_direction_after_fall()
	update_direction()



# =====================================================
# 💧 QUEDA SUAVE COM TWEEN (quando cai do teto)
# =====================================================
func _fall_from_ceiling_with_tween() -> void:
	up_ray.enabled = false
	side_ray.enabled = false
	var fall_distance := 300.0
	var fall_target := global_position + Vector2.DOWN.rotated(rotation) * fall_distance

	# Verifica colisão com o chão
	down_ray.target_position = Vector2(0, fall_distance)
	down_ray.force_raycast_update()

	if down_ray.is_colliding():
		fall_target = down_ray.get_collision_point() + Vector2(0, -3)
		fall_distance = global_position.distance_to(fall_target)

	# Mantém uma velocidade de queda de ~30 px/s
	var fall_time := fall_distance / fall_speed

	# Cria o tween
	var tween := create_tween()
	tween.tween_property(self, "global_position", fall_target, fall_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

	await tween.finished
	up_ray.enabled = true
	side_ray.enabled = true
	down_ray.target_position = Vector2(0, 7)

	# Define novo estado e direção aleatória
	_update_surface_state()
	_randomize_direction_after_fall()
	update_direction()


# =====================================================
# 🔀 Direção aleatória ao tocar o chão
# =====================================================
func _randomize_direction_after_fall() -> void:
	movedir = -1.0 if randf() < 0.5 else 1.0
	side_ray.target_position.x = abs(side_ray.target_position.x) * movedir

func _on_plat_detec_body_entered(_body: Node2D) -> void:
	on_plat += 1

func _on_plat_detec_body_exited(_body: Node2D) -> void:
	on_plat -= 1

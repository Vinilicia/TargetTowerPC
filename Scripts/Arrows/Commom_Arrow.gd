extends CharacterBody2D
class_name Arrow

@export var anim : AnimationPlayer
@export var sprite : Sprite2D
@export var trail : NodePath # ou o tipo real, mantive NodePath para generalizar
@export var hitbox : Hitbox

@export var Flying_Speed : float = 400
@export var Charge_Multiplier : float = 2
@export var Despawn_Time : float = 0
@export var Cost : int = 1
@export var default_bounce : Vector2 = Vector2(30, -100)

var flying_direction : Vector2 = Vector2(1, 0)
var facing_direction : int = 1
var charged : bool = false
var has_collided : bool = false
var bouncing : bool = false
var has_bounced : bool = false    # novo: indica se já deu o bounce

func _physics_process(delta):
	if bouncing:
		velocity.y += 980 * delta

	var collision := move_and_collide(velocity * delta)
	if collision:
		print("Velocidade: ", velocity, "Delta: ", delta)
		var normal := collision.get_normal()
		var contact_point := collision.get_position()

		# Pega múltiplos contatos na POSIÇÃO ATUAL usando collide_shape
		var contacts := _get_contacts_at_position($Coll.global_position)

		if contacts.size() >= 2:
			print("AA")
			collision = get_real_collision(delta)
			if !collision:
				print("BB")
				return

		# Lógica de impacto (spawn, prender, etc.)
		_handle_collision(collision)

func get_real_collision(delta : float) -> KinematicCollision2D:
	print(global_position)
	position -= velocity * delta
	print(global_position)
	return move_and_collide(velocity * delta, true)

func _get_contacts_at_position(pos: Vector2) -> Array:
	var shape_node: CollisionShape2D = $Coll
	if not is_instance_valid(shape_node) or shape_node.shape == null:
		return []

	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = shape_node.shape
	params.transform = Transform2D(rotation, shape_node.scale, 0.0, pos)
	params.collision_mask = 1 << 2
	params.exclude = [self, get_parent()]
	params.collide_with_bodies = true
	params.collide_with_areas = false

	var space := get_world_2d().direct_space_state
	# Importante: collide_shape retorna múltiplos contatos (inclusive do mesmo collider/tilemap)
	return space.intersect_shape(params, 16) # pega até 16 contatos

func fly(is_charged: bool, _player: CharacterBody2D) -> void:
	_enable_collision()
	hitbox.set_deferred("monitorable", true)
	if is_charged:
		charged = true
		velocity = flying_direction.normalized() * Flying_Speed * Charge_Multiplier
	else:
		velocity = flying_direction.normalized() * Flying_Speed
	var collision := move_and_collide(velocity.normalized() * 2)
	if collision:
		global_position += collision.get_normal() * 5

func flip_children() -> void:
	rotation = deg_to_rad(90)

func set_flying_direction(dir_vector: Vector2) -> void:
	rotation = dir_vector.angle()
	flying_direction = dir_vector.normalized()

func _disable_collision() -> void:
	set_collision_mask_value(3, false)
	set_collision_mask_value(5, false)

func _enable_collision() -> void:
	set_collision_mask_value(3, true)
	set_collision_mask_value(5, true)

func spawn_joint(body) -> void:
	_disable_collision()
	velocity = Vector2.ZERO
	var pos_relativa = global_position - body.global_position
	# remover da hierarquia atual e adicionar ao novo parent
	get_parent().call_deferred("remove_child", self)
	body.call_deferred("add_child", self)
	position = pos_relativa

func bounce() -> void:
	var dir = -int(sign(flying_direction.x))
	if dir == 0:
		# se não houver componente X (vertical), usa facing_direction
		dir = -facing_direction
	var bounce_vector = Vector2(default_bounce.x * dir, default_bounce.y)
	bouncing = true
	has_bounced = true
	velocity = bounce_vector

func despawn() -> void:
	await get_tree().create_timer(Despawn_Time).timeout
	queue_free()

func stop() -> void:
	velocity = Vector2.ZERO

func _handle_collision(collision: KinematicCollision2D) -> void:
	if has_collided:
		return

	var body = collision.get_collider()
	var normal = collision.get_normal()
	var contact_point = collision.get_position()

	if body.is_in_group("Attachables"):
		has_collided = true
		spawn_joint(body)
		despawn()
		return

	if not has_bounced:
		bounce()
	else:
		has_collided = true
		spawn_joint(body)
		despawn()

func _on_hitbox_hit(target: Node2D) -> void:
	velocity = Vector2.ZERO
	queue_free()

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
		var body = collision.get_collider()
		var normal = collision.get_normal()
		var contact_point = collision.get_position()

		# primeiro tenta corrigir a posição usando o helper
		var pushed_ok := _try_push_out(contact_point, normal)
		if not pushed_ok:
			# fallback simples: joga um pouco na direção oposta à normal
			global_position = contact_point - normal * 4.0

		# agora executa a lógica de impacto (spawn de plataforma, prender flecha, etc.)
		_handle_collision(collision)




# === helper para empurrar a flecha pra fora da geometria válida ===
# retorna true se conseguiu encontrar/ajustar, false caso contrário
func _try_push_out(contact_point: Vector2, normal: Vector2) -> bool:
	var shape_node: CollisionShape2D = $Coll
	if not is_instance_valid(shape_node) or shape_node.shape == null:
		return false

	var space := get_world_2d().direct_space_state
	var shape := shape_node.shape

	# funções utilitárias
	var _is_position_free := func(candidate_pos: Vector2) -> bool:
		var params = PhysicsShapeQueryParameters2D.new()
		params.shape = shape
		params.transform = Transform2D(rotation, candidate_pos)
		params.exclude = [self]
		params.collide_with_bodies = true
		params.collide_with_areas = false
		var res = space.intersect_shape(params, 1)
		return res.size() == 0


	# lista de candidatos iniciais (experimentais e rápidos)
	var push_dist := 4.0
	var candidates := [
		# preferir sair exatamente pela normal (para fora da superfície)
		contact_point - normal * push_dist,
		# tentativa separando apenas por eixo X
		contact_point - Vector2(sign(normal.x), 0) * push_dist,
		# tentativa separando apenas por eixo Y
		contact_point - Vector2(0, sign(normal.y)) * push_dist,
		# tentar a partir da posição atual da flecha (pequeno deslocamento)
		global_position - normal * push_dist,
		# tentar mover um pouco para frente / para trás na direção de voo
		global_position + flying_direction.normalized() * push_dist,
		global_position - flying_direction.normalized() * push_dist
	]

	for cand in candidates:
		if _is_position_free.call(cand):
			global_position = cand
			return true

	# se nada passou, faz um empurrão incremental ao longo da normal
	var max_push := 48.0
	var step := 4.0
	var d := push_dist
	while d <= max_push:
		var cand := contact_point - normal * d
		if _is_position_free.call(cand):
			global_position = cand
			return true
		d += step

	# fallback: tenta deslocar perpendicularmente (só para não ficar preso)
	d = push_dist
	while d <= max_push:
		var candx := contact_point + Vector2(sign(normal.y), 0) * d
		if _is_position_free.call(candx):
			global_position = candx
			return true
		var candy := contact_point + Vector2(0, sign(normal.x)) * d
		if _is_position_free.call(candy):
			global_position = candy
			return true
		d += step

	# não conseguiu achar posição livre
	return false


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

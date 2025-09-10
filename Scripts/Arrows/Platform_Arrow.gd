extends Arrow

@onready var plat_spawner = preload("res://Scenes/Interactibles/Objects/Platform.tscn")
@export var raycast: RayCast2D

var can_spawn : bool = true 

func _handle_collision(collision: KinematicCollision2D) -> void:
	if has_collided:
		return

	var body = collision.get_collider()
	var normal = collision.get_normal()
	var contact_point = collision.get_position()

	if not has_bounced and not body.is_in_group("Attachables"):
		bounce()
		return

	# cria plataforma
	if body.is_in_group("Attachables"):
		var platform = plat_spawner.instantiate()
		var local_pos = body.to_local(contact_point)
		body.add_child(platform)
		platform.position = local_pos
		
		if has_bounced or (flying_direction.y > 0) :
			platform.set_spawning_time(0.1)

		if abs(normal.y) > abs(normal.x):
			if normal.y < 0:
				platform.activate(0, false) # chão
			else:
				platform.activate(0, true)  # teto
		else:
			if normal.x > 0:
				platform.activate(-1, false) # parede direita
			else:
				platform.activate(1, false)  # parede esquerda

		has_collided = true
	queue_free()


func _on_hitbox_hit(target: Node2D) -> void:
	velocity = Vector2.ZERO
	bounce()

func try_make_platform(body : Node2D) -> bool:
	if not can_spawn:
		return false

	# atualiza o raycast
	if raycast:
		raycast.force_raycast_update()
	
	var contact_point: Vector2 = Vector2.ZERO
	var normal: Vector2 = Vector2.ZERO
	var ok := false

	# preferência: usar o RayCast2D da flecha
	if raycast and raycast.is_colliding():
		contact_point = raycast.get_collision_point()
		normal = raycast.get_collision_normal().normalized()
		ok = true
	else:
		# fallback: ray curto na direção do movimento (pega superfície próxima)
		var rc = RayCast2D.new()
		rc.target_position = flying_direction.normalized() * 12
		rc.collide_with_areas = false
		rc.collide_with_bodies = true
		add_child(rc)
		rc.force_raycast_update()
		if rc.is_colliding():
			contact_point = rc.get_collision_point()
			normal = rc.get_collision_normal().normalized()
			ok = true
		rc.queue_free()

	if not ok:
		return false

	# evita spawn múltiplo
	can_spawn = false

	# instancia plataforma e a parenta ao body no local correto
	var platform = plat_spawner.instantiate()
	var local_pos = body.to_local(contact_point) # posição relativa ao body
	body.call_deferred("add_child", platform)
	platform.set_deferred("position", local_pos)
	# decide orientação com base na normal
	if abs(normal.y) > abs(normal.x):
		# vertical (chão / teto)
		if normal.y < 0:
			# normal aponta para cima (chão)
			platform.call_deferred("activate", 0, false)
		else:
			# normal aponta para baixo (teto)
			platform.call_deferred("activate", 0, true)
	else:
		# horizontal (parede), escolhe lado de saída baseado no sinal de normal.x
		if normal.x > 0:
			# normal aponta para direita => colisão com parede direita => tira pra esquerda
			platform.call_deferred("activate", -1, false)
		else:
			platform.call_deferred("activate", 1, false)

	return true

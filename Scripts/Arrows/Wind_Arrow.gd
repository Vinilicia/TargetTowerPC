extends Arrow

@onready var push = $Actions/Push

func fly(is_charged : bool, player : CharacterBody2D) -> void:
	downward = false
	if is_charged:
		velocity = Vector2(direction * Flying_Speed * Charge_Multiplier, 0)
	else:
		velocity = Vector2(direction * Flying_Speed, 0)
	if player.has_method("receive_knockback"):
		player.receive_knockback(-1 * direction, 1)

func set_direction(dir : int) -> void:
	if direction != dir:
		$Collision.position.x *= -1
		$Push_Area.position.x *= -1
		flip_sprite()
		direction = dir


func fly_downward(player : CharacterBody2D) -> void:
	flip_children()
	downward = true
	velocity = Vector2(0, Flying_Speed * 1.2)
	if player.has_method("jump"):
		player.jump(1.25)

func _on_body_entered(body) -> void:
	get_frozen()
	despawn()


func _on_push_area_body_entered(body):
	#$Push_Area.set_deferred("monitoring", false)
	if !downward:
		push.handle_push(body, direction)

func flip_children() -> void:
	super.flip_children()
	var push_area = $Push_Area
	push_area.position = Vector2(0, -4)
	push_area.rotation = deg_to_rad(90)

func is_pushable(body : Node2D) -> bool:
	if body.has_node("Groups/Pushable"):
		return true
	else:
		return false

func despawn() -> void:
	queue_free()

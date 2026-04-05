extends Arrow

@export var coll_check_area : Area2D

var bodies_inside : int = 0
var phased_out : bool = true

func fly(is_charged: bool, _player: Player) -> void:
	await get_tree().process_frame
	AudioManager.play_song("ArrowShot")
	coll_check_area.set_deferred("monitoring", true)
	if is_charged:
		charged = true
		velocity = flying_direction.normalized() * Flying_Speed * Charge_Multiplier
	else:
		velocity = flying_direction.normalized() * Flying_Speed
	var collision := move_and_collide(velocity.normalized() * 2)
	if collision:
		global_position += collision.get_normal() * 5

func _on_coll_check_area_body_entered(_body: Node2D) -> void:
	bodies_inside += 1

func _on_coll_check_area_body_exited(_body: Node2D) -> void:
	bodies_inside -= 1
	hitbox.set_deferred("monitorable", true)
	if phased_out and bodies_inside == 0:
		phase_in()

func phase_in() -> void:
	phased_out = false
	_enable_collision()

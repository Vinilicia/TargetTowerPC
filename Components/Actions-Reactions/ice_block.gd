extends CharacterBody2D
class_name IceBlock

@export var coll : CollisionShape2D
@export var melts : bool = true
@export var freeze_duration : float = 5.0
@export var melting_timer : Timer
@export var hurtbox : Hurtbox
@export var child_container : Node2D

signal was_melt

func initialize(this_scale : Vector2i = Vector2i(1, 1), child : Node2D = null) -> void:
	var new_scale : Vector2 = Vector2( 16 * this_scale.x + 2, 16 * this_scale.y + 2)
	coll.set_deferred("scale", new_scale)
	hurtbox.set_deferred("scale", new_scale)
	if child:
		position = child.position
		child.call_deferred("add_sibling", self)
		child.call_deferred("reparent", child_container)
	if melts:
		call_deferred("start_melting_timer")
	$FireManager.call_deferred("update_hurtbox")

func start_melting_timer() -> void:
	melting_timer.start(freeze_duration)

func _physics_process(delta: float) -> void:
	if is_on_floor():
		velocity.y = 0
	else:
		velocity.y += get_gravity().y * delta
	move_and_slide()

func melt() -> void:
	was_melt.emit()
	if child_container.get_child_count() > 0:
		if child_container.get_child_count() > 1:
			push_error("BLOCO DE GELO COM MAIS DE UM CHILD")
		else:
			var child : Node2D = child_container.get_child(0)
			var parent := get_parent()
			child.call_deferred("reparent", parent)
	queue_free()

func _on_melting_timer_timeout() -> void:
	melt()

func _on_hurtbox_got_hit_by(_hitbox: Hitbox) -> void:
	if melting_timer.time_left - 2.0 > 0.0:
		melting_timer.start(melting_timer.time_left - 2.0)
	else:
		melting_timer.stop()
		melt()

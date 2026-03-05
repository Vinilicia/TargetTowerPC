extends CharacterBody2D
class_name IceBlock

@export var coll : CollisionShape2D
@export var melts : bool = true
@export var melting_timer : Timer
@export var hurtbox : Hurtbox
@export var child_container : Node2D

signal was_melt

func initialize(this_scale : Vector2 = Vector2(16, 16), child : Node2D = null, freeze_duration : float = 5.0) -> void:
	var new_scale : Vector2 = Vector2(this_scale.x + 7, this_scale.y + 7)
	coll.set_deferred("scale", new_scale)
	hurtbox.set_deferred("scale", new_scale)
	if child:
		position = child.position
		child.call_deferred("add_sibling", self)
		child.call_deferred("reparent", child_container)
	if melts:
		call_deferred("start_melting_timer", freeze_duration)
	$FireManager.call_deferred("update_hurtbox")

func start_melting_timer(freeze_duration) -> void:
	melting_timer.start(freeze_duration)

func _physics_process(delta: float) -> void:
	if is_on_floor():
		velocity = Vector2.ZERO
	else:
		velocity.y += get_gravity().y * delta
	move_and_slide()

func melt() -> void:
	if child_container.get_child_count() > 0:
		if child_container.get_child_count() > 1:
			push_error("BLOCO DE GELO COM MAIS DE UM CHILD")
		else:
			var child : Node2D = child_container.get_child(0)
			var parent := get_parent()
			child_container.call_deferred("remove_child", child)
			parent.call_deferred("add_child", child)
			child.position = position
	was_melt.emit()
	call_deferred("queue_free")

func _on_melting_timer_timeout() -> void:
	melt()

func _on_hurtbox_got_hit_by(_hitbox: Hitbox) -> void:
	if melting_timer.time_left - 2.0 > 0.0:
		melting_timer.start(melting_timer.time_left - 2.0)
	else:
		melting_timer.stop()
		melt()

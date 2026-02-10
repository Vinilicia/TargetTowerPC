extends Area2D
class_name Hurtbox

@export var parent : Node2D
@export var invincibility_timer : Timer
@export var invincibility_time : float = 1.0
@export var can_be_invincible : bool = true

var is_invincible : bool = false
var absorb_hits : bool

signal took_damage(amount : float)
signal got_hit_by(hitbox : Hitbox)
signal gained_invencibility
signal lost_invencibility
signal hit_while_invincible(hitbox : Hitbox)

func got_hit(hitbox : Hitbox) -> void:
	if hitbox.parent == parent:
		return
	if not is_invincible:
		got_hit_by.emit(hitbox)
		took_damage.emit(hitbox.Damage)
		hitbox.hit_something(parent)
		get_invincible_for()
	else:
		hit_while_invincible.emit(hitbox)

func get_invincible_for(duration_override : float = -1.0) -> void:
	if not can_be_invincible:
		return
	get_invincible()
	var duration = duration_override if duration_override > 0 else invincibility_time
	if duration <= 0:
		push_warning("Invincibility time inválido! Usando fallback de 0.2s")
		duration = 0.2
	invincibility_timer.start(duration)
	await invincibility_timer.timeout
	lose_invincible()

func get_invincible() -> void:
	is_invincible = true
	gained_invencibility.emit()

func lose_invincible() -> void:
	is_invincible = false
	set_deferred("monitoring", false)
	set_deferred("monitoring", true)
	lost_invencibility.emit()

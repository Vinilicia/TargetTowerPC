extends Area2D
class_name Hurtbox

@export var parent : Node2D
@export var invincibility_timer : Timer
@export var invincibility_time : float = 1.0
@export var can_be_invincible : bool = true

var absorb_hits : bool

signal took_damage(amount : float)
signal got_hit_by(hitbox : Hitbox)


func got_hit(area : Hitbox) -> void:
	got_hit_by.emit(area)
	took_damage.emit(area.Damage)
	area.hit_something(parent)
	get_invincible()


func get_invincible(duration_override : float = -1.0) -> void:
	if not can_be_invincible:
		return
	
	set_deferred("monitoring", false)

	var duration = duration_override if duration_override > 0 else invincibility_time
	if duration <= 0:
		push_warning("Invincibility time inválido! Usando fallback de 0.2s")
		duration = 0.2

	invincibility_timer.start(duration)
	await invincibility_timer.timeout
	set_deferred("monitoring", true)

extends Area2D
class_name Hurtbox

@export var parent : Node2D
@export var invincibility_timer : Timer
@export var invincibility_time : float

signal took_damage(amount : float)
signal got_knocked(knockback_vector : Vector2)

#Basicamente o Node que tiver isso como filho deve conectar esse sinal Took_Damage com alguma função, recebendo 
#esses dois floats como argumento.

func got_hit(area : Hitbox) -> void:
	var damage_amount : float = area.Damage
	var knockback_vector : Vector2 = area.get_knockback_vector()
	got_knocked.emit(knockback_vector)
	took_damage.emit(damage_amount)
	area.hit_something(parent)
	get_invincible()

func get_invincible() -> void:
	set_deferred("monitoring", false)
	invincibility_timer.start(invincibility_time)
	await invincibility_timer.timeout
	set_deferred("monitoring", true)

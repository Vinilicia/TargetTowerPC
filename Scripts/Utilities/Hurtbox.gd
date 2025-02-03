extends Area2D
class_name Hurtbox

signal took_damage(amount : float, knockback_multiplier : float)

#Basicamente o Node que tiver isso como filho deve conectar esse sinal Took_Damage com alguma função, recebendo 
#esses dois floats como argumento.

func got_hit(area : Hitbox) -> void:
	var damage_amount : float = area.Damage
	var knockback_multiplier : float = area.Knockback_force
	took_damage.emit(damage_amount, knockback_multiplier)

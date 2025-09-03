extends Area2D
class_name Hitbox

@export var parent : Node2D

@export var Damage : float
@export var Knockback_force : float
@export var Knockback_angle : float

signal hit(target : Node2D)

#Uma área usa esse script. Então se define o dano e as layers de colisão ( General, Enemy ou Player )
func get_knockback_vector() -> Vector2:
	var knockback_vector : Vector2
	knockback_vector = (Vector2(1, 0)).rotated(deg_to_rad(Knockback_angle))
	knockback_vector *= Knockback_force
	
	return knockback_vector

func hit_something(target : Node2D) -> void:
	hit.emit(target)

extends CharacterBody2D

class_name Enemy

func die() -> void:
	queue_free()
	
func took_damage(amount : float) -> void:
	pass
	
func run_out_of_health() -> void:
	die()

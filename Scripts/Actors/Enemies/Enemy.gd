extends CharacterBody2D

class_name Enemy

@export var v_component : VelocityComponent
@export var health_man : HealthManager

func die() -> void:
	queue_free()
	
func took_damage(_amount : float) -> void:
	pass
	
func run_out_of_health() -> void:
	die()

extends CharacterBody2D

class_name Enemy

@export var v_component : VelocityComponent
@export var health_man : HealthManager

signal died

func die() -> void:
	died.emit()
	queue_free()
	
func took_damage(_amount : float) -> void:
	pass
	
func run_out_of_health() -> void:
	die()

func apply_gravity(delta_time : float) -> void:
	v_component.set_proper_velocity(get_gravity().y, 2)

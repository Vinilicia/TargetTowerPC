extends Node
class_name HealthManager

@export var max_health : float

var health : float

signal lost_health(amount : float)
signal ran_out

func _ready() -> void:
	health = max_health

func gain_health(value : float) -> void:
	health = min(health + value, max_health)

func lose_health(value : float) -> void:
	lost_health.emit(value)
	health = max(0, health - value)
	check_if_alive()

func check_if_alive() -> void:
	if health == 0:
		ran_out.emit()


func _on_hurtbox_took_damage(_amount: float) -> void:
	pass # Replace with function body.

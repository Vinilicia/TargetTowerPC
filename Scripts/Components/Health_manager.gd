extends Node
class_name HealthManager

@export var max_health : float

const SECONDS_PER_TICK : float = 1.0

var health : float
enum status {NORMAL, BURNING, POISONED, ELECTRIFYED} 

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
	if is_zero_approx(health):
		ran_out.emit()

func start_burning(ticks : int, damage_value : float) -> void:
	for i in range(ticks):
		await get_tree().create_timer(SECONDS_PER_TICK).timeout
		lose_health(damage_value)

#func start_poisoned(ticks : int, damage_value : float) -> void:
	#pass
#
#func start_electrifyed(ticks : int, damage_value : float) -> void:
	#pass

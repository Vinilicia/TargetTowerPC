extends Node
class_name HealthManager

@export var max_health : float

@export var seconds_per_fire_tick : float = 1.0

var health : float
enum Status {
	NORMAL = 0,
	BURNING = 1 << 0,
	POISONED = 1 << 1,
	ELECTRIFYED = 1 << 2
} 

var status_mask : int = Status.NORMAL

signal lost_health(amount : float)
signal gained_health(amount : float)
signal ran_out

func _ready() -> void:
	health = max_health

func gain_health(value : float) -> void:
	var true_value : float = min(value, max_health - health)
	gained_health.emit(true_value)
	health += true_value

func lose_health(value : float) -> void:
	var true_value : float = min(value, health)
	lost_health.emit(true_value)
	health -= true_value
	check_if_alive()

func check_if_alive() -> void:
	if is_zero_approx(health):
		ran_out.emit()

func start_burning(damage_value : float) -> void:
	if (status_mask & Status.BURNING):
		return
	else:
		status_mask |= Status.BURNING 
		burning_loop(damage_value)

func stop_burning() -> void:
	status_mask &= ~Status.BURNING

func burning_loop(damage : float) -> void:
		while (status_mask & Status.BURNING):
			if !is_inside_tree():
				break
			await get_tree().create_timer(seconds_per_fire_tick).timeout
			lose_health(damage)

#func start_poisoned(ticks : int, damage_value : float) -> void:
	#pass
#
#func start_electrifyed(ticks : int, damage_value : float) -> void:
	#pass

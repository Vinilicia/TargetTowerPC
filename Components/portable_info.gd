extends Node
class_name PortableInfo

@export_enum("Light", "Medium", "Heavy", "Very heavy") var weight = "Light"
@export_group("Player Modifiers")
@export var medium_speed_multiplier : float = 0.9
@export var medium_jump_multiplier : float = 0.9
@export var heavy_speed_multiplier : float = 0.7
@export var heavy_jump_multiplier : float = 0.75
@export var v_heavy_speed_multiplier : float = 0.4
@export var v_heavy_jump_multiplier : float = 0.5

func get_weight_modifiers() -> Array[float]:
	match weight:
		"Light":
			return [1, 1]
		"Medium":
			return [medium_speed_multiplier, medium_jump_multiplier]
		"Heavy":
			return [heavy_speed_multiplier, heavy_jump_multiplier]
		"Very heavy":
			return [v_heavy_speed_multiplier, v_heavy_jump_multiplier]
	return [1, 1]

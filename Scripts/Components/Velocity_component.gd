extends Node
class_name VelocityComponent

var proper_velocity : Vector2
var knockback_velocity : Vector2
var ground_velocity : Vector2
var wind_velocity : Vector2

func set_proper_velocity(value, axis : int = -1) -> void:
	if value is Vector2:
		proper_velocity = value
	elif value is float:
		if axis == 1:
			proper_velocity.x = value
		elif axis == 2:
			proper_velocity.y = value

func set_knockback_velocity(value) -> void:
	if value is Vector2:
		knockback_velocity = value
	elif value is float:
		knockback_velocity *= value

func set_ground_velocity(value) -> void:
	if value is Vector2:
		ground_velocity = value
	elif value is float:
		ground_velocity *= value

func set_wind_velocity(value) -> void:
	if value is Vector2:
		wind_velocity = value
	elif value is float:
		wind_velocity *= value

func add_proper_velocity(value : Vector2) -> void:
	proper_velocity += value

func add_knockback_velocity(value : Vector2) -> void:
	knockback_velocity += value

func add_ground_velocity(value : Vector2) -> void:
	ground_velocity += value

func add_wind_velocity(value : Vector2) -> void:
	wind_velocity += value

func get_proper_velocity(axis : int = -1):
	if axis == 1:
		return proper_velocity.x as float
	elif axis == 2:
		return proper_velocity.y as float
	return proper_velocity as Vector2

func get_knockback_velocity(axis : int = -1):
	if axis == 1:
		return knockback_velocity.x as float
	elif axis == 2:
		return knockback_velocity.y as float
	return knockback_velocity as Vector2
	
func get_ground_velocity(axis : int = -1):
	if axis == 1:
		return ground_velocity.x as float
	elif axis == 2:
		return ground_velocity.y as float
	return ground_velocity as Vector2

func get_wind_velocity(axis : int = -1):
	if axis == 1:
		return wind_velocity.x as float
	elif axis == 2:
		return wind_velocity.y as float
	return wind_velocity as Vector2

func get_total_velocity() -> Vector2:
	return proper_velocity + knockback_velocity + ground_velocity + wind_velocity

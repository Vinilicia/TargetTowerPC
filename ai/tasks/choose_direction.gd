extends BTAction

@export var min_dist : int
@export var max_dist : int

@export var position_var : StringName = &"pos"
@export var direction_var : StringName = &"dir"

func _tick(_deslta : float) -> Status:
	var pos : Vector2
	var dir : int =  rando_dir()
	
	pos = rando_pos(dir)
	blackboard.set_var(position_var, pos)
	return SUCCESS


func rando_pos(direction : int) -> Vector2:
	var vector : Vector2
	var distance : int = randi_range(min_dist, max_dist) * direction
	vector = Vector2( agent.global_position.x + distance, agent.global_position.y)
	return vector

func rando_dir() -> int:
	var dir = randi_range(-2, 1)
	if abs(dir) != dir:
		dir = -1
	else:
		dir = 1
	blackboard.set_var(direction_var, dir)
	return dir

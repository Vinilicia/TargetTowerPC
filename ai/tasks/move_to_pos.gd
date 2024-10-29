extends BTAction

@export var target_position_var := &"pos"
@export var direction_var := &"dir"

@export var tolerance : int = 5

@export var agent_speed : int 

func _tick(_delta : float) -> Status:
	var target_position : Vector2 = blackboard.get_var(target_position_var, Vector2.ZERO)
	var direction : int = blackboard.get_var(direction_var)
	agent.direction = direction
	if abs(agent.global_position.x - target_position.x) < tolerance:
		if agent.is_on_floor():
			agent.speed = 0
			return SUCCESS
		return RUNNING
	else:
		agent.speed = agent_speed
		return RUNNING

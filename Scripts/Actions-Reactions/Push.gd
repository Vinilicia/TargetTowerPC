extends Node2D

@export var push_force : Vector2 = Vector2(500, 0)


func handle_push(body : Node2D, direction : int, push_multiplier : float = 1) -> void:
	if is_pushable(body):
		body.reactions.be_pushed(direction, push_force * push_multiplier)

func is_pushable(body : Node2D) -> bool:
	if body.has_node("Reactions"):
		return body.reactions.is_pushable
	else:
		return false

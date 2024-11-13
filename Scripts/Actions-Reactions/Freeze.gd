extends Node2D

func handle_freeze(body : Node2D) -> void:
	if is_freezable(body):
		body.reactions.get_hit_by_ice()

func is_freezable(body : Node2D) -> bool:
	if body.has_node("Reactions"):
		return body.reactions.is_freezable
	else:
		return false

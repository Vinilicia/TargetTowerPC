extends Node2D

func handle_freeze(body : Node2D) -> void:
	if is_freezable(body):
		body.reactions.be_frozen()

func is_freezable(body : Node2D) -> bool:
	if body.has_node("Reactions"):
		return body.reactions.is_freezable
	else:
		return false

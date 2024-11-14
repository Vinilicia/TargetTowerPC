extends Arrow

@export var Charge_Push_Mod : float = 1.3

@onready var push = $Actions/Push

func _on_body_entered(body) -> void:
	get_frozen()
	if !downward:
		if charged:
			push.handle_push(body, direction, Charge_Push_Mod)
		else:
			push.handle_push(body, direction)

	if body.is_in_group("Attachables"):
		bounce()

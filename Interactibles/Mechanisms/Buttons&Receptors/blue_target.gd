extends Activator

@export var duration_time : float = 5.0

func activate(_variable : Variant) -> void:
	if _variable is Hitbox:
		super.activate(_variable)
		get_tree().create_timer(duration_time).timeout.connect(deactivate.bind(_variable))

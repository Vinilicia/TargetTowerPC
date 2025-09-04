extends Hitbox

signal hit(body: Node2D)

func _on_body_entered(body: Node2D) -> void:
	hit.emit(body)

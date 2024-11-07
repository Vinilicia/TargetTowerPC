extends Arrow

@export var Freeze_Time : float = 5.0
@onready var freeze = $Actions/Freeze


func _on_body_entered(body) -> void:
	get_frozen()
	$Sprite.visible = false
	freeze.handle_freeze(body)

func get_frozen() -> void:
	queue_free()

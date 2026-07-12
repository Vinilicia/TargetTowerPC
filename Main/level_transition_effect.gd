extends CanvasLayer

@onready var animation : AnimationPlayer = $AnimationPlayer

func dissolve_effect() -> void:
	animation.play("DISSOLVE")
	
func reappear_effect() -> void:
	animation.play_backwards("DISSOLVE")

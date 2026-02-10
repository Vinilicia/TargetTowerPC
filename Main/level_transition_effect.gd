extends CanvasLayer

@onready var animation : AnimationPlayer = $AnimationPlayer

func dissolve_effect():
	animation.play("DISSOLVE")
	
func reappear_effect():
	animation.play_backwards("DISSOLVE")

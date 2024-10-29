extends RigidBody2D


func change_to(mode : String) -> void:
	if mode == "vertical":
		rotation = deg_to_rad(90)
		$Platform_Col.one_way_collision = false
		#flip_sprite()
	elif mode == "horizontal":
		rotation = deg_to_rad(0)
		#flip_sprite()

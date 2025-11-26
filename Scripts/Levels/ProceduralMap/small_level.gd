extends RandomLevel

func setup(entrance : Vector2i = Vector2i(0,0)) -> void:
	max_x = 32
	max_y = 1
	spaces_to_fill = 3
	super.setup(entrance)

extends RandomLevel

func setup(entrance : Vector2i = Vector2i(0,0)) -> void:
	max_x = 48
	max_y = 2
	spaces_to_fill = 5
	super.setup(entrance)

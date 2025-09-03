extends Sprite2D

var parent : Node2D

@export_enum("Red", "Green", "Blue") var Receptor_Color : String

func _ready() -> void:
	generate_sprite()

func generate_sprite() -> void:
	if Receptor_Color == "Red":
		texture = load("res://Assets/Home_bred/Mechanisms/Targets/RedReceptor.aseprite")
	elif Receptor_Color == "Green":
		pass
	elif Receptor_Color == "Blue":
		texture = load("res://Assets/Home_bred/Mechanisms/Targets/BlueReceptor.aseprite")
	

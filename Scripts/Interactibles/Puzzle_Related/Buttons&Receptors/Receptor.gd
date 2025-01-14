extends Node2D

var parent : Node2D

@export_enum("Red", "Green", "Blue") var Receptor_Color : String

func _ready() -> void:
	parent = get_parent()
	
	generate_sprite()

func on_button_pressed():
	parent.activate()

func on_button_unpressed():
	parent.deactivate()

func generate_sprite() -> void:
	var sprite = Sprite2D.new()
	if Receptor_Color == "Red":
		sprite.texture = load("res://Assets/Home_bred/Mechanisms/Buttons/Receptors/Red_Receptor.svg")
	elif Receptor_Color == "Green":
		sprite.texture = load("res://Assets/Home_bred/Mechanisms/Buttons/Receptors/Green_Receptor.svg")
	elif Receptor_Color == "Blue":
		sprite.texture = load("res://Assets/Home_bred/Mechanisms/Buttons/Receptors/Blue_Receptor.svg")
	add_child(sprite)
	

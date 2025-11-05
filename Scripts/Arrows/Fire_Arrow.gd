extends Arrow

@export var fire : Fire

func setup_hitbox(parent : Node2D) -> void:
	super.setup_hitbox(parent)
	var hitbox = fire.get_child(0)
	if hitbox is Hitbox:
		hitbox.parent = parent

func _ready() -> void:
	fire._activate()

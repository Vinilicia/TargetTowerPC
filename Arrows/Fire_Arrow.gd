extends Arrow

@export var fire : Fire

func setup_hitbox(parent : Node2D) -> void:
	super.setup_hitbox(parent)
	fire.parent = parent

func fly(is_charged: bool, _player: CharacterBody2D) -> void:
	fire._activate()
	super.fly(is_charged, _player)

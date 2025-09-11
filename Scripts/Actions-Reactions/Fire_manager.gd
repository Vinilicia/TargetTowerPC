extends Node
class_name FireManager

@export var instant : bool
@export var has_fire : bool = true
@export_group("Nodes")
@export var fire : Fire

signal caught_fire

func is_fire(hitbox: Hitbox) -> bool:
	return hitbox.get_collision_layer_value(13)

func _hurtbox_got_hit(hitbox: Hitbox) -> void:
	if is_fire(hitbox):
		caught_fire.emit()
		if has_fire:
			fire._activate()

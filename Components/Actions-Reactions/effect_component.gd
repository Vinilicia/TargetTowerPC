extends Node
class_name Component

@export var parent_health_man : HealthManager
@export_group("Nodes")
@export var hurtbox : Hurtbox

signal effect_started
signal effect_ended

func hurtbox_check(layer_name : String, hurtbox_property : String) -> void:
	if !hurtbox:
		assert(get_parent() is Hurtbox, "Component não é filho de hurtbox! Em " + get_parent().get_parent().name)
		hurtbox = get_parent()
	hurtbox.set(hurtbox_property, true)
	hurtbox.set_collision_mask_value(hurtbox.get(layer_name), true)

func start() -> void:
	effect_started.emit()

func end() -> void:
	effect_ended.emit()

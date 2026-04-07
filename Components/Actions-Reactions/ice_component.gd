extends Node
class_name IceComponent

@export var parent_health_man : HealthManager
@export var regular_behaviour : bool = true
@export var frozen_duration : float = 5.0
@export var can_stack : bool = false
@export_group("Nodes")
@export var hurtbox : Hurtbox
@export var ice_block_scene : PackedScene

var frozen : bool = false

signal froze
signal melt

func hurtbox_check() -> void:
	if !hurtbox:
		assert(get_parent() is Hurtbox, "IceComponent não é filho de hurtbox! Em " + get_parent().get_parent().name)
		hurtbox = get_parent()
	hurtbox.freezable = true
	hurtbox.set_collision_mask_value(hurtbox.ice_layer, true)

func _ready() -> void:
	hurtbox_check()
	hurtbox.ice_entered.connect(_hurtbox_got_hit)

func _hurtbox_got_hit(_hitbox: Hitbox) -> void:
	if frozen and !can_stack:
		return
	froze.emit()
	if regular_behaviour:
		assert(parent_health_man != null, "SEM parent_health_man EM ICE MANAGER DE " + hurtbox.parent.name)
		if parent_health_man.health > 0:
			hurtbox.parent.set_deferred("process_mode", PROCESS_MODE_DISABLED)
			freeze()

func regular_hit_behaviour() -> void:
	froze.emit()
	hurtbox.parent.set_deferred("process_mode", PROCESS_MODE_DISABLED)
	freeze()

func regular_melt_behaviour() -> void:
	hurtbox.parent.set_deferred("process_mode", PROCESS_MODE_INHERIT)

func freeze() -> void:
	frozen = true
	var ice_block : IceBlock = ice_block_scene.instantiate()
	ice_block.was_melt.connect(melt_away)
	ice_block.initialize(hurtbox.scale, hurtbox.parent, frozen_duration)

func melt_away() -> void:
	frozen = false
	melt.emit()
	if regular_behaviour:
		regular_melt_behaviour()

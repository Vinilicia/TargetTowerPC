extends Node2D
class_name IceManager

@export var parent : CharacterBody2D
@export var parent_health_man : HealthManager
@export var regular_behaviour : bool = true
@export var frozen_duration : float = 5.0
@export var can_stack : bool = false
@export_group("Nodes")
@export var hurtbox : Hurtbox
@export var ref_hurtbox : Hurtbox
@export var ice_block_scene : PackedScene

var frozen : bool = false

signal froze
signal melt

func _ready() -> void:
	if !ref_hurtbox:
		printerr("Falta de hurtbox de referencia em FireManager!!")
		return
	var new_coll : CollisionShape2D = ref_hurtbox.get_child(1).duplicate()
	hurtbox.call_deferred("add_child", new_coll)
	hurtbox.set_deferred("scale", ref_hurtbox.scale)

func update_hurtbox() -> void:
	hurtbox.scale = ref_hurtbox.scale
	hurtbox.position = ref_hurtbox.position

func _hurtbox_got_hit(_hitbox: Hitbox) -> void:
	if frozen and !can_stack:
		return
	froze.emit()
	if regular_behaviour:
		assert(parent_health_man != null, "SEM parent_health_man EM ICE MANAGER DE " + parent.name)
		if parent_health_man.health > 0:
			parent.set_deferred("process_mode", PROCESS_MODE_DISABLED)
			freeze()

func regular_hit_behaviour() -> void:
	froze.emit()
	parent.set_deferred("process_mode", PROCESS_MODE_DISABLED)
	freeze()

func regular_melt_behaviour() -> void:
	parent.set_deferred("process_mode", PROCESS_MODE_INHERIT)

func freeze() -> void:
	frozen = true
	var ice_block : IceBlock = ice_block_scene.instantiate()
	ice_block.was_melt.connect(melt_away)
	ice_block.initialize(ref_hurtbox.scale, parent, frozen_duration)

func melt_away() -> void:
	frozen = false
	melt.emit()
	if regular_behaviour:
		regular_melt_behaviour()

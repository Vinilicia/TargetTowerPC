extends Node2D
class_name IceManager

@export var parent : CharacterBody2D
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

func freeze() -> void:
	frozen = true
	var ice_block : IceBlock = ice_block_scene.instantiate()
	ice_block.was_melt.connect(melt_away)
	ice_block.initialize(ref_hurtbox.scale, parent, frozen_duration)

func melt_away() -> void:
	frozen = false
	melt.emit()

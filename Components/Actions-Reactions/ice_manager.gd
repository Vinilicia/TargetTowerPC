extends Node2D
class_name IceManager

@export var parent : Enemy
@export var frozen_duration : float = 4.0
@export var can_stack : bool = false
@export_group("Nodes")
@export var hurtbox : Hurtbox
@export var ref_hurtbox : Hurtbox
@export var ice_block_scene : PackedScene

var frozen : bool = false
var overlapping_fire_count : int = 0

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

func _hurtbox_got_hit(hitbox: Hitbox) -> void:
	overlapping_fire_count += 1
	if frozen and !can_stack:
		return
	if hitbox is Ice:
		freeze()

func freeze() -> void:
	frozen = true
	froze.emit()
	
	var ice_block : IceBlock = ice_block_scene.instantiate()
	ice_block.was_melt.connect(extinguish)
	ice_block.initialize(parent.enemy_scale, parent)

func extinguish() -> void:
	frozen = false
	melt.emit()

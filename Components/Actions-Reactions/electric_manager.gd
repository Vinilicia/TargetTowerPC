extends Node2D
class_name ElectricManager

@export var parent : CharacterBody2D
@export var can_stack : bool = false
@export_group("Nodes")
@export var hurtbox : Hurtbox
@export var ref_hurtbox : Hurtbox
@export var electric_area_scene : PackedScene

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

func extinguish() -> void:
	frozen = false
	melt.emit()

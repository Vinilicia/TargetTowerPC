extends Node2D
class_name FireManager

@export var has_fire : bool = true
@export var time_to_burn : float = 2.5
@export_group("Nodes")
@export var hurtbox : Hurtbox
@export var burning_timer : Timer
@export var fire : Fire
@export var ref_hurtbox : Hurtbox

var on_fire : bool = false
var overlapping_fire_count : int = 0

signal caught_fire

func _ready() -> void:
	if !ref_hurtbox:
		printerr("Falta de hurtbox de referencia em FireManager!!")
		return
	var new_coll : CollisionShape2D = ref_hurtbox.get_child(1).duplicate()
	hurtbox.call_deferred("add_child", new_coll)
	hurtbox.set_deferred("scale", ref_hurtbox.scale)

func is_fire(hitbox : Hitbox) -> bool:
	return hitbox.get_collision_layer_value(13)

func _hurtbox_got_hit(hitbox: Hitbox) -> void:
	if !is_fire(hitbox):
		return
	overlapping_fire_count += 1
	if on_fire:
		return
	on_fire = true
	var hitbox_parent = hitbox.get_parent()
	if hitbox_parent is Fire:
		if hitbox_parent.instant:
			if has_fire:
				fire._activate()
			caught_fire.emit()
		else:
			burning_timer.start(time_to_burn)

func _on_hurtbox_fire_exited(area: Area2D) -> void:
	overlapping_fire_count -= 1
	if overlapping_fire_count < 0:
		overlapping_fire_count = 0
	if overlapping_fire_count == 0:
		if !burning_timer.is_stopped():
			burning_timer.stop()

func _on_burning_timer_timeout() -> void:
	if has_fire:
		fire._activate()
	caught_fire.emit()

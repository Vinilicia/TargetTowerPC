extends Node2D
class_name Fire

@export var instant : bool = false
@export var scale_increase : float = 1.4
@export_group("Nodes")
@export var collision : CollisionShape2D

func _ready() -> void:
	var hitbox_coll : CollisionShape2D = $Hitbox/Coll
	hitbox_coll.set_deferred("shape", collision.shape)
	hitbox_coll.set_deferred("scale", collision.scale * scale_increase)
	$Hitbox.set_deferred("monitorable", false)
	$Hitbox.set_deferred("process_mode", PROCESS_MODE_DISABLED)
	$Hitbox.set_deferred("visible", false)

func _activate() -> void:
	$Hitbox.set_deferred("process_mode", PROCESS_MODE_INHERIT)
	$Hitbox.set_deferred("monitorable", true)
	$Hitbox.set_deferred("visible", true)

func _on_hitbox_hit(_target: Node2D) -> void:
	pass

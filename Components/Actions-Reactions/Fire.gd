extends Hitbox
class_name Fire

@export var instant : bool = false
@export var scale_increase : Vector2 = Vector2(1, 1)
@export_group("Nodes")

func _ready() -> void:
	_deactivate()

func set_collision(new_coll : CollisionShape2D) -> void:
	var coll := new_coll.duplicate()
	coll.scale.x *= scale_increase.x
	coll.scale.y *= scale_increase.y
	call_deferred("add_child", coll)

func _deactivate() -> void:
	set_deferred("monitorable", false)
	set_deferred("process_mode", PROCESS_MODE_DISABLED)
	set_deferred("visible", false)

func _activate() -> void:
	set_deferred("process_mode", PROCESS_MODE_INHERIT)
	set_deferred("monitorable", true)
	set_deferred("visible", true)

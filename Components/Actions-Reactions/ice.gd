extends Hitbox
class_name Ice

func _deactivate() -> void:
	$Hitbox.set_deferred("monitorable", false)
	$Hitbox.set_deferred("process_mode", PROCESS_MODE_DISABLED)
	$Hitbox.set_deferred("visible", false)

func _activate() -> void:
	$Hitbox.set_deferred("process_mode", PROCESS_MODE_INHERIT)
	$Hitbox.set_deferred("monitorable", true)
	$Hitbox.set_deferred("visible", true)

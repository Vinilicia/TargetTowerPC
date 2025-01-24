extends Node2D

@export var spawning_time : float

var platform_col
var dir : int
var down : bool

func activate(direction : int, downward : bool) -> void:
	platform_col = $Platform/Platform_Col
	platform_col.set_deferred("disabled", false)
	dir = direction
	down = downward
	$Timer.start(spawning_time)

func spawn() -> void:
	var tween = create_tween()
	if down:
		platform_col.set_deferred("one_way_collision", false)
		tween.tween_property(platform_col, "scale", Vector2(1.2, -0.2), 0.25)
	else:
		tween.tween_property(platform_col, "scale", Vector2(1.2, -0.2) * dir, 0.25)
	tween.parallel().tween_property($Platform, "position", Vector2(12 * -1, 0), 0.25)

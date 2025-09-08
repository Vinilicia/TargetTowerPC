extends Node2D

@export var spawning_time : float

var platform_col
var dir : int = 0
var vertical: bool = false
var down: bool = false

func activate(direction: int, downward: bool) -> void:
	platform_col = $Platform/Platform_Col
	platform_col.set_deferred("disabled", false)
	
	dir = direction
	down = downward
	vertical = (direction == 0)
	
	$Timer.start(spawning_time)

func spawn() -> void:
	var tween = create_tween()
	if vertical:
		platform_col.set_deferred("one_way_collision", false)
		if down: # vindo do teto
			tween.tween_property(platform_col, "scale", Vector2(4, 24), 0.25)
			tween.parallel().tween_property($Platform, "position", Vector2(0, 12), 0.25)
		else: # vindo do chão
			tween.tween_property(platform_col, "scale", Vector2(4, 24), 0.25)
			tween.parallel().tween_property($Platform, "position", Vector2(0, -12), 0.25)
	else:
		# horizontal
		tween.tween_property(platform_col, "scale", Vector2(24 * dir, -4), 0.25)
		tween.parallel().tween_property($Platform, "position", Vector2(12 * -dir, 0), 0.25)

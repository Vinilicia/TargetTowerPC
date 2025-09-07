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
	vertical = (direction == 0) # se direction = 0 → vertical, senão horizontal
	
	$Timer.start(spawning_time)
	spawn()

func spawn() -> void:
	var tween = create_tween()
	if vertical:
		if down: # vindo do teto
			platform_col.set_deferred("one_way_collision", false)
			tween.tween_property(platform_col, "scale", Vector2(1.2, -0.2), 0.25)
			tween.parallel().tween_property($Platform, "position", Vector2(0, 12), 0.25)
		else: # vindo do chão
			tween.tween_property(platform_col, "scale", Vector2(1.2, -0.2), 0.25)
			tween.parallel().tween_property($Platform, "position", Vector2(0, -12), 0.25)
	else:
		# horizontal
		tween.tween_property(platform_col, "scale", Vector2(1.2, -0.2) * dir, 0.25)
		tween.parallel().tween_property($Platform, "position", Vector2(12 * -dir, 0), 0.25)

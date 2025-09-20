extends Node2D

@export var spawning_time : float
@export var player_detec : Area2D
@export var platform_length : float = 24
@export var platform_width : float = 4
@export var time_to_pop_up : float = 0.25
@export var time_to_despawn : float = 10

const DESPAWN_CHECK_DELAY : float = 0.5
const TIME_TO_SHRINK : float = 0.15

var platform_col
var dir : int = 0
var vertical: bool = false
var down: bool = false
var player_on_top : bool = false

func set_spawning_time(duration : float) -> void:
	spawning_time = duration

func activate(direction: int, downward: bool) -> void:
	platform_col = $Platform/PlatformCol
	
	dir = direction
	down = downward
	vertical = (direction == 0)
	if !vertical:
		$Platform.scale.y = -1
	
	$Timer.start(spawning_time)

func spawn() -> void:
	var timer : Timer = $Timer as Timer
	timer.timeout.disconnect(spawn)
	timer.timeout.connect(despawn)
	timer.start(time_to_despawn)
	var tween = create_tween()
	platform_col.set_deferred("disabled", false)
	if vertical:
		platform_col.set_deferred("one_way_collision", false)
		if down: 
			tween.tween_property($Platform, "scale", Vector2(platform_width, platform_length), time_to_pop_up)
			tween.parallel().tween_property($Platform, "position", Vector2(0, 12), time_to_pop_up)
		else: 
			tween.tween_property($Platform, "scale", Vector2(platform_width, platform_length), time_to_pop_up)
			tween.parallel().tween_property($Platform, "position", Vector2(0, -12), time_to_pop_up)
	else:
		tween.tween_property($Platform, "scale", Vector2(platform_length * dir, -platform_width), time_to_pop_up)
		tween.parallel().tween_property($Platform, "position", Vector2(12 * -dir, 0), time_to_pop_up)
		tween.finished.connect(func():
			player_detec.position.y += 0.25
			player_detec.monitoring = true
			)

func shrink() -> void:
	var tween = create_tween()
	if vertical:
		if down:
			tween.tween_property($Platform, "scale", Vector2(1, 1), TIME_TO_SHRINK)
			tween.parallel().tween_property($Platform, "position", Vector2(0, 0), TIME_TO_SHRINK)
		else:
			tween.tween_property($Platform, "scale", Vector2(1, 1), TIME_TO_SHRINK)
			tween.parallel().tween_property($Platform, "position", Vector2(0, 0), TIME_TO_SHRINK)
	else:
		tween.tween_property($Platform, "scale", Vector2(1, 1), TIME_TO_SHRINK)
		tween.parallel().tween_property($Platform, "position", Vector2(0, 0), TIME_TO_SHRINK)
	await tween.finished
	queue_free()

func despawn() -> void:
	if vertical:
		shrink()
	else:
		if !player_on_top:
			shrink()
		else:
			$Timer.start(DESPAWN_CHECK_DELAY)

func _on_player_detector_area_body_entered(body: Node2D) -> void:
	player_on_top = true

func _on_player_detector_area_body_exited(body: Node2D) -> void:
	player_on_top = false

extends SlimeBlob

@export var player_detector : Area2D
@export var wall_detector : Area2D

var disabled := true
var is_inside_wall := false
var hit_ground_last_time := false

func _physics_process(_delta: float) -> void:
	if !disabled and !is_inside_wall:
		hit_ground_last_time = true

func explode() -> void:
	queue_free()
	pass

func _on_player_detector_body_entered(_body: Node2D) -> void:
	if linear_velocity.y > 0:
		disabled = false

func _on_wall_detector_body_entered(_body: Node2D) -> void:
	is_inside_wall = true
	if hit_ground_last_time:
		explode()

func _on_wall_detector_body_exited(_body: Node2D) -> void:
	is_inside_wall = false

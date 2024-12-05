extends Area2D

@export var Fire_Intensity : float
@export var Insta_Flame : bool
@export var Extinguishes : bool = true

var duration : float

var parent_node : Node2D
var coll : CollisionShape2D

func set_collision(collision_shape : Shape2D, collision_scale : float) -> void:
	coll = $Coll
	coll.call_deferred("set_shape", collision_shape)
	coll.call_deferred("set_scale", Vector2(1, 1) * collision_scale)
 
func handle_start_flame(body_or_area : Node2D) -> void:
	if is_heatable(body_or_area):
		body_or_area.reactions.get_hit_by_fire(Fire_Intensity, Insta_Flame)


func handle_stop_flame(body_or_area : Node2D) -> void:
	if is_heatable(body_or_area):
		if !Insta_Flame:
			if body_or_area.reactions.still_heating:
				body_or_area.reactions.stop_heating_timer()

func is_heatable(body_or_area : Node2D) -> bool:
	if body_or_area.has_node("Reactions") and body_or_area != parent_node:
		return body_or_area.reactions.is_heatable
	else:
		return false

func _on_body_or_area_entered(body_or_area) -> void:
	handle_start_flame(body_or_area)

func _on_body_or_area_exited(body_or_area) -> void:
	handle_stop_flame(body_or_area)

func _process(_delta: float) -> void:
	var overlapping_bodies : Array[Node2D]
	var overlapping_areas : Array[Area2D]
	if has_overlapping_bodies():
		overlapping_bodies = get_overlapping_bodies()
		for body in overlapping_bodies:
			handle_start_flame(body)
	if has_overlapping_areas():
		overlapping_areas = get_overlapping_areas()
		for area in overlapping_areas:
			handle_start_flame(area)

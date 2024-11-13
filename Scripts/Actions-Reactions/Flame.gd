extends Area2D

@export var Flame_Intensity : float
@export var Insta_Flame : bool

var heating_nodes : Array[Node]
var coll : CollisionShape2D
var parent_node : Node2D

func _ready():
	coll = $Coll

func set_collision(collision_shape : Shape2D, collision_scale : float) -> void:
	coll.shape = collision_shape
	coll.scale = Vector2(1, 1) * collision_scale
	
 
func handle_start_flame(body_or_area : Node2D) -> void:
	if is_heatable(body_or_area):
		body_or_area.reactions.get_hit_by_fire(Flame_Intensity, Insta_Flame)


func handle_stop_flame(body_or_area : Node2D) -> void:
	if is_heatable(body_or_area):
		if !Insta_Flame:
			if body_or_area.reactions.still_heating:
				body_or_area.reactions.stop_heating_loop()
	

func is_heatable(body : Node2D) -> bool:
	if body.has_node("Reactions2") and body != parent_node:
		return body.reactions.is_heatable
	else:
		return false

func _on_body_or_area_entered(body_or_area) -> void:
	handle_start_flame(body_or_area)

func _on_body_or_area_exited(body_or_area) -> void:
	handle_stop_flame(body_or_area)

func _process(delta: float) -> void:
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

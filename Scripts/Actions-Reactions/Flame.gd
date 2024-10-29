extends Area2D

@export var Max_Temp_Raise : float
@export var Flame_Intensity : float
@export var Insta_Flame : bool

var heating_bodies : Array[Node]
var coll : CollisionShape2D

func _ready():
	coll = $Coll

func in_heating_list(body : Node2D) -> bool:
	for element in heating_bodies:
		if body == element:
			return true
	return false


func set_collision(collision_shape : Shape2D, collision_scale : float) -> void:
	coll.shape = collision_shape
	coll.scale = Vector2(1, 1) * collision_scale
	
 
func handle_start_flame(body_or_area : Node2D, intensity_modifier : float = 1) -> void:
	#if get_parent().has_node("Reactions"):
		#heating_bodies = get_parent().reactions.get_heating_bodies_array()
	if is_heatable(body_or_area):
		#body_or_area.reactions.fire_source = get_parent()
		if body_or_area.reactions.start_heating(Flame_Intensity * intensity_modifier, Max_Temp_Raise, get_parent(),  Insta_Flame):
			heating_bodies.append(body_or_area)
		

func handle_stop_flame(body_or_area : Node2D) -> void:
	if !Insta_Flame:
		if body_or_area.reactions.still_heating:
			body_or_area.reactions.stop_heating_loop()

func is_heatable(body : Node2D) -> bool:
	if body.has_node("Reactions"):
		return body.reactions.is_heatable
	else:
		return false

func _on_body_or_area_entered(body_or_area) -> void:
	if body_or_area != get_parent().get_parent():
		handle_start_flame(body_or_area)

func _on_body_or_area_exited(body_or_area) -> void:
	handle_stop_flame(body_or_area)

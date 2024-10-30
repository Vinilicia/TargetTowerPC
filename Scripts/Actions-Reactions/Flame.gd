extends Area2D

@export var Max_Temp_Raise : float
@export var Flame_Intensity : float
@export var Insta_Flame : bool

var heating_nodes : Array[Node]
var coll : CollisionShape2D

func _ready():
	coll = $Coll

func set_collision(collision_shape : Shape2D, collision_scale : float) -> void:
	coll.shape = collision_shape
	coll.scale = Vector2(1, 1) * collision_scale
	
 
func handle_start_flame(body_or_area : Node2D, intensity_modifier : float = 1) -> void:
	if is_heatable(body_or_area):
		var total_flame = Flame_Intensity * intensity_modifier
		body_or_area.reactions.set_heating_values(total_flame, Max_Temp_Raise,  Insta_Flame)
		body_or_area.reactions.start_heating()

func handle_continue_flame(body_or_area : Node2D) -> void:
	if is_heatable(body_or_area):
		pass

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

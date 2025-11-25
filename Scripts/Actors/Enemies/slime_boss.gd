extends Boss

@export var jump_force : Vector2
@export var spinning_speed : float = 90
@export var raycast : RayCast2D
@export var markers_node : Node2D

@export_group("Behaviour")
@export var default_time : float
@export var default_timer_offset : float


var player : Player
var top_left_marker : Marker2D
var top_right_marker : Marker2D
var bottom_left_marker : Marker2D
var bottom_right_marker : Marker2D


func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	top_left_marker = markers_node.get_child(0)
	top_right_marker = markers_node.get_child(1)
	bottom_left_marker = markers_node.get_child(2)
	bottom_right_marker = markers_node.get_child(3)

func _physics_process(delta: float) -> void:
	if engaging:
		raycast.target_position = to_local(player.global_position)
	grounded_behaviour()

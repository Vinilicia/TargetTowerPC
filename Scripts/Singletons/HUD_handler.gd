extends Node

var hud : HUD

func _ready() -> void:
	hud = get_tree().get_first_node_in_group("HUD")

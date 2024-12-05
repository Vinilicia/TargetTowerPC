extends Node


var parent : Node2D

var auto_defrosts : bool
var defrosting_time : float

func initialize(new_parent: Node2D, freeze_properties: Dictionary) -> void:
	parent = new_parent
	
	auto_defrosts = freeze_properties.get("auto_defrosts")
	defrosting_time = freeze_properties.get("defrosting_time")

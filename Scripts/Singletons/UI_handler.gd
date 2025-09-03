extends Node

var equiped_arrow_index : int = 0

var passed_minutes : int = 0
var passed_seconds : int = 0

var available_arrows : int = 3

var arrow_switcher

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS

func set_swicther(switcher : Node) -> void:
	arrow_switcher = switcher

func _process(_delta : float) -> void:
	
	if Input.is_action_just_pressed("switch arrow"):
		arrow_switcher.open()
	
	if Input.is_action_just_released("switch arrow"):
		arrow_switcher.close()

extends Area2D

var reactions
var coll

var enter_burn_func : Callable = start_burning
var exit_burn_func : Callable = stop_burning
var update_burn_func : Callable = update_burning
 
func _ready():
	reactions = $Reactions
	coll = $Coll

func start_burning() -> void:
	coll.debug_color += Color(0, 1, 0, 1)

func update_burning() -> void:
	pass

func stop_burning() -> void:
	coll.debug_color -= Color(0, 1, 0, 1)

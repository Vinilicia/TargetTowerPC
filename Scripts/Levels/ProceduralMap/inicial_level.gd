extends Node2D

@onready var ground_tilemap : TileMapLayer = $Tilemaps/Ground

var level_exit : int
var x : int

func setup(exit : int = 0) -> void:
	level_exit = exit

func _ready() -> void:
	remove_barrier()
	
func remove_barrier() -> void:
	if level_exit == 0:
		x = 7
	else:
		x = -8
	ground_tilemap.erase_cell(Vector2i(x, -1))
	ground_tilemap.erase_cell(Vector2i(x, -2))
	ground_tilemap.erase_cell(Vector2i(x, -3))

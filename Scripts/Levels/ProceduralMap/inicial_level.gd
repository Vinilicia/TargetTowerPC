extends Node2D

@onready var ground_tilemap : TileMapLayer = $Tilemaps/Ground

var level_exit : int

func _init(exit : int = 0) -> void:
	level_exit = exit

func _ready() -> void:
	remove_barrier(level_exit)
	
func remove_barrier(exit : int) -> void:
	var x
	if exit == 0:
		x = 6
	else:
		x = -7
	ground_tilemap.erase_cell(Vector2i(x, -1))
	ground_tilemap.erase_cell(Vector2i(x, -2))
	ground_tilemap.erase_cell(Vector2i(x, -3))

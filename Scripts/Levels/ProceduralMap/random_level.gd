class_name RandomLevel
extends Node2D

@onready var ground_tilemap : TileMapLayer = $Tilemaps/Ground

var level_entrance : Vector2i = Vector2i(0,0)
var level_exit : Vector2i
var max_x : int
var max_y : int
var spaces_to_fill : int
var platform_last_position : int = -1
var platform_scene : PackedScene = preload("res://Scenes/Levels/ProceduralMap/ThingsToFill/platform_for_random.tscn")

func _ready() -> void:
	var r = randf_range(0, 1.0)
	if r < 0.2:
		level_exit.x = 1 - level_entrance.x
		level_exit.y = level_entrance.y
	else:
		level_exit.x = randi_range(level_entrance.y,max_y)
		level_exit.y = 1
	remove_barrier(level_entrance)
	remove_barrier(level_exit)
	set_platform_position()
	
func set_level_entrance(entrance : Vector2i) -> void:
	level_entrance = entrance
	
func remove_barrier(entrance : Vector2i) -> void:
	var x
	if entrance.x == 1:
		x = -max_x/2
	else:
		x = max_x/2 - 1
	var y = -entrance.y * 6
	ground_tilemap.erase_cell(Vector2i(x, y-1))
	ground_tilemap.erase_cell(Vector2i(x, y-2))
	ground_tilemap.erase_cell(Vector2i(x, y-3))
	
func set_platform_position() -> void:
	var r = randi_range(0, spaces_to_fill-1)
	while r == platform_last_position:
		r = randi_range(0, spaces_to_fill-1)
	platform_last_position = r
	
	var x = (max_x/2 - 6) - 8 * platform_last_position
	var y = -level_entrance.y * 6
	ground_tilemap.erase_cell(Vector2i(x-1, y-5))
	ground_tilemap.erase_cell(Vector2i(x-2, y-5))
	ground_tilemap.erase_cell(Vector2i(x-3, y-5))
	ground_tilemap.erase_cell(Vector2i(x-4, y-5))
	ground_tilemap.erase_cell(Vector2i(x-1, y-6))
	ground_tilemap.erase_cell(Vector2i(x-2, y-6))
	ground_tilemap.erase_cell(Vector2i(x-3, y-6))
	ground_tilemap.erase_cell(Vector2i(x-4, y-6))
	# Just trust bro, this works
	ground_tilemap.set_cells_terrain_connect([Vector2i(x-5, y-6)], 0, 0, false)
	ground_tilemap.set_cells_terrain_connect([Vector2i(x-5, y-6)], 0, 0, false)
	ground_tilemap.set_cells_terrain_connect([Vector2i(x, y-5)], 0, 0, false)
	ground_tilemap.set_cells_terrain_connect([Vector2i(x, y-5)], 0, 0, false)
	
	var platoform = platform_scene.instantiate()
	x = (x - 2) * 16
	y = (y - 3) * 16
	platoform.position = Vector2(x, y)
	add_child(platoform)
	
	
	

class_name RandomLevel
extends Node2D

@onready var ground_tilemap : TileMapLayer = $Tilemaps/Ground

var level_entrance : Vector2i
var level_exit : Vector2i
var max_x : int
var max_y : int
var spaces_to_fill : int
var platform_last_position : int = -1
var platform_position : int = -1
var actual_floor : int = 0
var platform_scene : PackedScene = preload("res://Scenes/Levels/ProceduralMap/ThingsToFill/platform_for_random.tscn")
var spider_scene : PackedScene = preload("res://Scenes/Actors/Enemies/Spider.tscn")
var slime_scene : PackedScene = preload("res://Scenes/Actors/Enemies/Slime.tscn")
var goblin_scene : PackedScene = preload("res://Scenes/Actors/Enemies/Common_Goblin.tscn")
var bat_scene : PackedScene = preload("res://Scenes/Actors/Enemies/Bat.tscn")

func _init(entrance : Vector2i = Vector2i(0,0)) -> void:
	level_entrance = entrance
	
func _ready() -> void:
	var r = randf_range(0, 1.0)
	if r < 0.2:
		level_exit.x = 1 - level_entrance.x
		level_exit.y = level_entrance.y
	else:
		level_exit.x = randi_range(0,1)
		level_exit.y = randi_range(level_entrance.y+1,max_y)
	remove_barrier(level_entrance)
	remove_barrier(level_exit)
	for i in range(max_y):
		set_platform_position()
		fill_enemies()
		platform_last_position = platform_position
		actual_floor += 1
	fill_enemies()
	
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
	platform_position = r
	
	var x = (max_x/2 - 6) - 8 * platform_position
	var y = -actual_floor * 6
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
	r = randf_range(0,1)
	if r < 0.4:
		var spider = spider_scene.instantiate()
		spider.position = Vector2(x,y-5)
		add_child(spider)
	
func fill_enemies() -> void:
	var x
	var y = -actual_floor * 6
	for i in range(spaces_to_fill):
		if i != platform_last_position and i != platform_position:
			x = (max_x/2 - 6) - 8 * i
			x = (x - 2)
			var r = randf() * 100.0
			if r < 25:
				var goblin = goblin_scene.instantiate()
				goblin.position = Vector2(x*16,y*16-2)
				add_child(goblin)
			elif r < 50:
				ground_tilemap.set_cells_terrain_connect([Vector2i(x, y-1)], 0, 0, false)
				ground_tilemap.set_cells_terrain_connect([Vector2i(x-1, y-1)], 0, 0, false)
				ground_tilemap.set_cells_terrain_connect([Vector2i(x, y-2)], 0, 0, false)
				ground_tilemap.set_cells_terrain_connect([Vector2i(x-1, y-2)], 0, 0, false)
				var slime = slime_scene.instantiate()
				slime.position = Vector2(x*16,(y-2)*16-2)
				add_child(slime)
			elif r < 75:
				var bat = bat_scene.instantiate()
				bat.position = Vector2(x*16,y*16-(4*16))
				add_child(bat)

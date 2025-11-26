extends Node2D

@export var initial_level_scene : PackedScene
@export var small_level_scene : PackedScene
@export var medium_level_scene : PackedScene
@export var corridor_scene : PackedScene
#@export var final_level_scene : PackedScene

@export var number_of_levels : int = 5

@onready var player : CharacterBody2D = $Player

var actual_x : int = 0
var actual_y : int = 0
var last_exit : int = 0
var same_last_exit : bool = false

func _ready():
	spaw_initial_level()
	for i in range(number_of_levels):
		spaw_next_level()

func spaw_initial_level() -> void:
	var initial_level = initial_level_scene.instantiate()
	initial_level.position = Vector2i(0, 0)
	var r = randi_range(0, 1)
	initial_level.setup(r)
	add_child(initial_level)
	player.position = Vector2i(0, -2)
	last_exit = r
	actual_x = initial_level.x * 16
	
func spaw_next_level() -> void:
	var level = random_level()
	level.setup(Vector2i(1 - last_exit, 0))
	if last_exit == 0:
		actual_x = actual_x + level.max_x/2 * 16
		level.position = Vector2i(actual_x, actual_y)
		actual_x = actual_x - level.max_x/2 * 16
	else:
		actual_x = actual_x - level.max_x/2 * 16
		level.position = Vector2i(actual_x, actual_y)
		actual_x = actual_x + level.max_x/2 * 16
	add_child(level)
	actual_y = actual_y - level.level_exit.y * 6 * 16
	if level.level_exit.x == last_exit:
		if level.level_exit.x == 0:
			actual_x = actual_x + level.max_x * 16
		else:
			actual_x = actual_x - level.max_x * 16
		
	var r = randf() * 100.0
	last_exit = level.level_exit.x
	if r < 50:
		spaw_corridors()
	
func random_level() -> Node2D:
	var r = randi() % 100
	if r < 70:
		return small_level_scene.instantiate()
	else:
		return medium_level_scene.instantiate()
	return null

func spaw_corridors() -> void:
	var number_of_corridors = randi_range(2, 3)
	var direction = -1
	if last_exit == 0:
		direction = 1
	for i in range(number_of_corridors):
		var corridor = corridor_scene.instantiate()
		actual_x = actual_x + direction * 4 * 16
		corridor.position = Vector2i(actual_x, actual_y)
		actual_x = actual_x + direction * 4 * 16
		add_child(corridor)

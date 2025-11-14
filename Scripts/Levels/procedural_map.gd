extends Node2D

@export var bat: PackedScene
@export var goblin: PackedScene
@export var slime: PackedScene
@export var spider: PackedScene
@export var spawn_interval := 2.0
@export var area_size := Vector2(600,120)

func _ready():
	#randomize()
	for i in range(5):
		spawn_enemy()

func spawn_enemy():
	var random_enemy = randi_range(1, 3)
	var enemy_scene : PackedScene = null
	match random_enemy:
		1:
			enemy_scene = bat
		2:
			enemy_scene = goblin
		3:
			enemy_scene = slime
		4:
			enemy_scene = spider
	
	var enemy = enemy_scene.instantiate()
	enemy.position = Vector2(
		randf_range(0, area_size.x),
		randf_range(0, area_size.y)
	)
	add_child(enemy)

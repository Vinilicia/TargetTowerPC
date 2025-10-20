extends Node2D
class_name Room

@export var enemies_node : Node2D

var is_enemy_alive : Array[bool] = []

func get_enemy_alive_array() -> Array[bool]:
	return is_enemy_alive

func set_enemy_as_dead(index : int) -> void:
	is_enemy_alive[index] = false

func _ready() -> void:
	var enemies : Array[Node] = enemies_node.get_children()
	var enemy_count : int = enemies.size()
	is_enemy_alive.resize(enemy_count)
	is_enemy_alive.fill(true)
	for i in range(enemy_count):
		if enemies[i] is Enemy:
			enemies[i].died.connect(set_enemy_as_dead.bind(i))

func kill_enemies(is_alive : Array[bool]) -> void:
	var enemies = enemies_node.get_children()
	for i in range(enemies.size()):
		if !is_alive[i]:
			enemies[i].die()

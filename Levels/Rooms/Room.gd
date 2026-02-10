extends Node2D
class_name Room

@export var enemies_node : Node2D
@export var bench : Node2D

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
	init_camera_one()

func init_camera_one() -> void:
	($Cameras/Camera1 as PhantomCamera2D).follow_target = get_tree().get_first_node_in_group("Player") 

func kill_enemies(is_alive : Array[bool]) -> void:
	var enemies = enemies_node.get_children()
	for i in range(enemies.size()):
		if !is_alive[i]:
			(enemies[i] as Enemy).money_amount = 0
			(enemies[i] as Enemy).die()
			
func get_bench_position() -> Vector2:
	if bench:
		return bench.global_position
	return Vector2(0, -10)

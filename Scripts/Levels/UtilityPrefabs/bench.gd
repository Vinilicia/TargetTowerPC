extends Node2D

@export var area: int = 0
@export var should_save : bool = true

var player: Player = null

@onready var bench_id : int = get_room_number()
@onready var save_id : int = get_tree().get_first_node_in_group("Game").save_id

func _physics_process(_delta: float) -> void:
	if player and Input.is_action_just_pressed("down"):
		heal_player()
		if should_save:
			bench_used()

func _on_player_entered(body: Node2D) -> void:
	if body is Player:
		player = body

func _on_player_exited(body: Node2D) -> void:
	if body is Player:
		player = null

func heal_player() -> void:
	player.heal_hp_on_bench()
	player.heal_mana_on_bench()

func bench_used() -> void:	
	print("merda")
	SaveManager.save_file_data.set_last_bench_id(bench_id)
	SaveManager.save_file_data.set_area_of_bench(area)
	SaveManager.save_file_data.set_available_arrows(player.available_arrows)
	SaveManager._save(save_id)
	
func get_room_number() -> int:
	var room_node = get_parent()
	if room_node:
		var room_name : String = room_node.name
		var regex = RegEx.new()
		regex.compile(r"\d+")
		var result = regex.search(room_name)
		if result:
			return int(result.get_string())
	return -1

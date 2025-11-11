class_name Game
extends Node2D

@export var blackout_rect: ColorRect

var current_level: Room
var save_id: int
var enemy_alive_persistence: Array[bool] = []
var last_room_name: String = ""
var tween: Tween

#func _ready() -> void:
	#Engine.time_scale = 0.5

func change_level(next_level: String, spawn_position: Vector2, area: LevelDatabase.Areas = LevelDatabase.Areas.AREA_1):
	blackout_fade_in()

	var old_level: Room = current_level

	# 🔹 Resolve o caminho pelo LevelDB autoload
	var scene_path: String = LevelDB.database.get_level_path(area, next_level)
	if scene_path == "":
		push_error("❌ Level '%s' não encontrado na área '%s'!" % [next_level, str(area)])
		return

	handle_next_level(scene_path, spawn_position)
	handle_last_level(old_level)

	await get_tree().create_timer(0.2).timeout
	blackout_fade_out()


func handle_last_level(old_level: Room) -> void:
	if old_level:
		enemy_alive_persistence = old_level.get_enemy_alive_array()
		print(enemy_alive_persistence)
		last_room_name = old_level.name
		call_deferred("remove_child", old_level)


func handle_next_level(scene_path: String, spawn_position: Vector2) -> void:
	print("Carregando level: ", scene_path)
	var new_level: Room = load(scene_path).instantiate()
	call_deferred("add_child", new_level)

	# Restaura inimigos se for a mesma sala
	if new_level.name == last_room_name:
		new_level.call_deferred("kill_enemies", enemy_alive_persistence)

	get_node("Player").global_position = spawn_position
	current_level = new_level


func spaw_player_on_bench() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	get_node("Player").global_position = current_level.get_bench_position()
	blackout_fade_in()
	await tween.finished
	visible = true
	await get_tree().create_timer(0.2).timeout
	blackout_fade_out()

func load_room(room_scene: PackedScene, save_load_manager: SaveLoadManager) -> void:
	get_node("Player").wake_up(save_load_manager)
	if current_level:
		remove_child(current_level)
	current_level = room_scene.instantiate()
	add_child(current_level)
	call_deferred("spaw_player_on_bench")


func blackout_fade_in() -> void:
	if blackout_rect:
		tween = get_tree().create_tween()
		tween.tween_property(blackout_rect, "modulate", Color(1, 1, 1, 1), 0.2)

func blackout_fade_out() -> void:
	if blackout_rect:
		tween.stop()
		tween = get_tree().create_tween()
		tween.tween_property(blackout_rect, "modulate", Color(1, 1, 1, 0), 0.5)

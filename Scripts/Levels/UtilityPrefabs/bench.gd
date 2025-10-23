extends Node2D

@export var bench_id: int = 0

var player: Player = null
var saveLoad : SaveLoadManager = SaveLoadManager.new()

func _physics_process(_delta: float) -> void:
	if player and Input.is_action_just_pressed("down"):
		bench_used()

func _on_player_entered(body: Node2D) -> void:
	if body is Player:
		player = body

func _on_player_exited(body: Node2D) -> void:
	if body is Player:
		player = null

func bench_used() -> void:
	print("Jogador sentou no banco ID:", bench_id)
	saveLoad.save_file_data.set_last_bench_id(bench_id)
	saveLoad._save(1)
	print("Jogo salvo com sucesso no banco", bench_id)

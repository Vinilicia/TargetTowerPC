extends Node2D

@export var bench_id: int = 0

var player: Player = null
var SaveLoad

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
	
	# Atualiza o ID do último banco usado
	SaveLoad.SaveFileData.set_last_bench_id(bench_id)
	
	# Aqui você pode atualizar outras coisas do jogador, se quiser
	# Ex: SaveLoad.SaveFileData.set_money(player.money)
	# Ex: SaveLoad.SaveFileData.set_max_health(player.max_health)
	
	# Salva o jogo no slot atual (por exemplo, 0)
	SaveLoad._save(0)
	
	print("Jogo salvo com sucesso no banco", bench_id)

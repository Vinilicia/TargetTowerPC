extends Node2D

var player : Player = null

func _physics_process(delta: float) -> void:
	if player:
		if Input.is_action_just_pressed("down"):
			bench_used()

func _on_player_entered(body: Node2D) -> void:
	if body is Player:
		player = body

func _on_player_exited(body: Node2D) -> void:
	if body is Player:
		player = null

func bench_used() -> void:
	print("I sit on the toilet")

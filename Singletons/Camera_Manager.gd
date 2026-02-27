extends Node

var camera : PhantomCamera2D = null
var player : CharacterBody2D = null

func setup_camera_work() -> void:
	if camera.follow_target != null:
		camera.follow_target = null
	camera.follow_target = player

func setup_camera(new_camera : PhantomCamera2D) -> void:
	camera = new_camera
	if player:
		setup_camera_work()

func setup_player(new_player : CharacterBody2D) -> void:
	player = new_player
	if camera:
		setup_camera_work()

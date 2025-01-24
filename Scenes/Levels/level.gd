extends Node2D

@export var camera : Camera2D
@export var tilemap : TileMapLayer

func get_camera() -> Camera2D:
	return camera

func _ready() -> void:
	tilemap.position = tilemap.position

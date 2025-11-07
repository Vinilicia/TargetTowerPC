@tool
extends Area2D

@onready var sprite : Sprite2D = $FireSprite
@onready var coll : CollisionShape2D = $Coll

@export var extinguishes : bool = true
@export var extinguish_time : float = 5.0

@export var width : int:
	set(new_width):
		width = new_width
		update_length(new_width)

func _ready() -> void:
	if extinguishes:
		await get_tree().create_timer(extinguish_time).timeout
		queue_free()

func update_length(new_width : int) -> void:
	if not is_node_ready():
		await ready
	sprite.region_rect = Rect2(0, 0, 13 * new_width, 24)
	coll.scale = Vector2(new_width * 13 - 2, 22)

extends Control
class_name HUD

@export var hearts_container : HBoxContainer
@onready var heart_rect : PackedScene = preload("res://Scenes/Menus&UI/Heart_TextRect.tscn")

var hearts : Array[HeartTexture] = []
var full_heart_amount : int

func init_hearts(amount : int = 3) -> void:
	for i in range(amount):
		var new_heart : HeartTexture = heart_rect.instantiate()
		hearts_container.call_deferred("add_child", new_heart)
		hearts.append(new_heart)
	full_heart_amount = amount

func _ready() -> void:
	pass

func lose_hearts(amount_lost : int) -> void:
	var index := full_heart_amount - 1
	for i in range(amount_lost):
		hearts[index].drain()
		index -= 1
	full_heart_amount -= amount_lost

func gain_hearts(amount_gained : int) -> void:
	var index := full_heart_amount
	for i in range(amount_gained):
		hearts[index].fill()
		index += 1
	full_heart_amount += amount_gained

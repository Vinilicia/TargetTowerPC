extends Control

@export var hearts_container : HBoxContainer
@export var heart_rect : PackedScene

var hearts : Array[HeartTexture] = []
var full_heart_amount : int

func init_hearts(amount : int = 3) -> void:
	for i in range(amount):
		var new_heart : HeartTexture = heart_rect.instantiate()
		hearts_container.call_deferred("add_child", new_heart)
		hearts.append(new_heart)
	full_heart_amount = amount

func _ready() -> void:
	init_hearts(7)
	await get_tree().create_timer(5.0).timeout
	lose_hearts(2)
	await get_tree().create_timer(3.0).timeout
	gain_hearts(1)
	await get_tree().create_timer(3.0).timeout
	lose_hearts(3)
	await get_tree().create_timer(3.0).timeout
	gain_hearts(1)
	await get_tree().create_timer(3.0).timeout
	gain_hearts(3)

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

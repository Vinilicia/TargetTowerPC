extends Node2D

const horizontal := false
const move_signal := -1
const move_duration := 0.01
const moving_distance := 30

@onready var the_block = $The_Block

var current_position := Vector2.ZERO
var final_position = Vector2.RIGHT * moving_distance * move_signal if horizontal else Vector2.UP * moving_distance * move_signal


func _physics_process(delta):
	the_block.position = the_block.position.lerp(current_position, 0.5)

func button_was_pressed():
	var block_tween = create_tween()
	block_tween.tween_property(self, "current_position", final_position, move_duration)
	print_debug(final_position)
	print_debug(current_position)


func button_was_unpressed():
	var block_tween = create_tween()
	block_tween.tween_property(self, "current_position", Vector2.ZERO, move_duration)
	print_debug(current_position)

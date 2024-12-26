extends AnimatableBody2D

@export var horizontal : bool = true
@export var move_signal : int = 1
@export var move_duration : float = 0.01
@export var moving_distance : int = 30

#@onready var the_block = $Sprite2D
@onready var the_block = $"."
@onready var initial_position = global_position
@onready var current_position : Vector2 = initial_position
@onready var final_position = Vector2.RIGHT * moving_distance * move_signal + initial_position if horizontal else Vector2.UP * moving_distance * move_signal + initial_position

func _ready():
	if !horizontal and move_signal == 1:
		the_block.rotation_degrees = 0
	elif !horizontal and move_signal == -1:
		the_block.rotation_degrees = 180
	elif horizontal:
		the_block.rotation_degrees = 90 * move_signal
	

func _physics_process(delta):
	the_block.position = the_block.position.lerp(current_position, 0.5)

func button_was_pressed():
	var block_tween = create_tween()
	block_tween.tween_property(self, "current_position", final_position, move_duration)


func button_was_unpressed():
	var block_tween = create_tween()
	block_tween.tween_property(self, "current_position", initial_position, move_duration)

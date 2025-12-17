extends Control
class_name HUD

@export var hearts_container : HBoxContainer
@export var money_label : Label
@export var mana_bar : TextureProgressBar
@export var mana_bar_textures : Array[Texture]
@onready var heart_rect : PackedScene = preload("res://Scenes/Menus&UI/Heart_TextRect.tscn")

var hearts : Array[HeartTexture] = []
var full_heart_amount : int
var current_money : int = 0
var tween : Tween
var target_money : int = 0

func init_hearts(amount : int = 3) -> void:
	hearts.clear()
	for child in hearts_container.get_children():
		child.queue_free()
	for i in range(amount):
		var new_heart : HeartTexture = heart_rect.instantiate()
		hearts_container.call_deferred("add_child", new_heart)
		hearts.append(new_heart)
	full_heart_amount = amount

func add_heart() -> void:
	var new_heart : HeartTexture = heart_rect.instantiate()
	hearts_container.call_deferred("add_child", new_heart)
	hearts.append(new_heart)
	new_heart.anim.play("Empty")

func init_mana(amount : int = 5) -> void:
	mana_bar.max_value = amount
	mana_bar.value = amount

func change_arrow(index : int) -> void:
	mana_bar.texture_over = mana_bar_textures[index]

func _ready() -> void:
	pass
	#await get_tree().create_timer(2.0).timeout
	#add_money(20)
	#await get_tree().create_timer(2.0).timeout
	#add_money(800)
	#await get_tree().create_timer(2.0).timeout
	#add_money(200)
	#await get_tree().create_timer(2.0).timeout
	#add_money(-400)
	#await get_tree().create_timer(2.0).timeout
	#add_money(-200)
	#await get_tree().create_timer(2.0).timeout
	#add_money(69000)

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

func gain_mana(amount_gained : int) -> void:
	mana_bar.value += amount_gained
	if mana_bar.value == mana_bar.max_value:
		mana_bar.tint_under = Color(1, 1, 1, 1)
		mana_bar.tint_progress = Color(1, 1, 1, 1)

func lose_mana(amount_lost : int ) -> void:
	mana_bar.value -= amount_lost
	if mana_bar.value == 0:
		mana_bar.tint_under = Color(1, 0, 0, 1)
		mana_bar.tint_progress = Color(1, 0, 1, 1)

func add_money(value: int) -> void:
	target_money = min(SaveManager.save_file_data.get_max_money(), target_money + value)
	
	var duration_offset : float = (abs(float(target_money) - float(current_money)) / 100.0)
	var duration : float = (min(round(duration_offset), 60) * 0.1) + 0.2 if duration_offset >= 0.1 else 0.05
	
	if tween == null or not tween.is_running():
		tween = get_tree().create_tween()
		tween.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

		tween.tween_method(
			_update_money_value,
			current_money,
			target_money,
			duration
		)

		tween.finished.connect(_on_tween_finished)
	else:
		tween.pause()

		tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
		tween.set_speed_scale(1.0)

		var start := current_money
		tween.kill()
		tween = get_tree().create_tween()

		tween.tween_method(
			_update_money_value,
			start,
			target_money,
			duration
		)

		tween.finished.connect(_on_tween_finished)

func _update_money_value(value : int) -> void:
	current_money = int(value)
	money_label.text = str(current_money)

func _on_tween_finished() -> void:
	current_money = target_money
	money_label.text = str(current_money)
	SaveManager.save_file_data.set_money(current_money)

func _on_money_label_visibility_changed() -> void:
	money_label.text = str(SaveManager.save_file_data.get_money())
	target_money = SaveManager.save_file_data.get_money()

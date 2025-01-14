extends HBoxContainer

@export var icons : Array[TextureButton]

@onready var anim_player: AnimationPlayer = $"../../../AnimationPlayer"
@onready var margin_texture: TextureRect = $"../TextureRect"

var current_index : int

func show_icon(index : int) -> void:
	icons[index].modulate = Color(1, 1, 1, 1)

func hide_icon(index : int) -> void:
	icons[index].modulate = Color(1, 1, 1, 0)

func _ready() -> void:
	for i in range(icons.size()):
		if UiHandler.equiped_arrow_index == i:
			show_icon(i)
		else:
			hide_icon(i)
	
	
	UiHandler.set_swicther(self)
	var avl_arrows : int = UiHandler.available_arrows
	var first_button
	for i in range(avl_arrows):
		if i == UiHandler.equiped_arrow_index:
			icons[i].modulate = Color(icons[i].modulate, 1)
		if i == 0:
			first_button = icons[i]
		if i == avl_arrows - 1:
			icons[i].focus_neighbor_right = first_button.get_path()
			first_button.focus_neighbor_left = icons[i].get_path()

func open() -> void:
	get_tree().paused = true
	icons[UiHandler.equiped_arrow_index].grab_focus()
	change_icons_modulate(Color(1, 1, 1, 1))
	anim_player.play("opening")

func change_margin_visibility() -> void:
	margin_texture.visible = !margin_texture.visible

func change_icons_modulate(modulate : Color) -> void:
	var tween = create_tween()
	tween.set_parallel()
	for i in range(icons.size()):
		if i != UiHandler.equiped_arrow_index:
			tween.tween_property(icons[i], "modulate", modulate, 0.1)


func close() -> void:
	get_tree().paused = false
	icons[UiHandler.equiped_arrow_index].release_focus()
	change_icons_modulate(Color(1, 1, 1, 0))
	anim_player.play("closing")

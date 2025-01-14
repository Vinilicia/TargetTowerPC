extends Control


#func _ready() -> void:
	#change_sprite(0)

#func _process(_delta: float) -> void:
	#if UiHandler.equiped_arrow_index != current_texture_index:
		#current_texture_index = UiHandler.equiped_arrow_index
		#change_sprite(UiHandler.equiped_arrow_index)

#func change_sprite(index : int) -> void:
	#for i in range(icons.size()):
		#if i == index:
			#icons[i].visible = true
			#icons[i].modulate = Color(1, 1, 1, 1)
		#else:
			#icons[i].visible = false

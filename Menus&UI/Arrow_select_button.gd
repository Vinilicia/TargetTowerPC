extends TextureButton

@export var value : int

func _on_focus_entered() -> void:
	UiHandler.equiped_arrow_index = value

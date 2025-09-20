extends Arrow

@onready var fire : Fire = $Fire

func _ready() -> void:
	fire._activate()

extends Arrow

@onready var fire : Fire = $Fire

func _ready():
	fire._activate()

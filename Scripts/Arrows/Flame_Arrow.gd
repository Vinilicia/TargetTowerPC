extends Arrow

@export var Charge_Inten_Mod : float = 2

@onready var fire = $Fire

func _ready():
	fire.parent_node = self
	if charged:
		fire.set_collision(coll.shape, 10)
		fire.Intensity *= 2
	else:
		fire.set_collision(coll.shape, 1.2)
 
func get_frozen() -> void:
	queue_free()

func _on_body_entered(_body) -> void:
	get_frozen()

func set_direction(dir) -> void:
	if direction != dir:
		super.set_direction(dir)
		fire = $Fire
		fire.position.x *= -1

func flip_children() -> void:
	super.flip_children()
	fire = $Fire
	fire.position = Vector2(fire.position.y, abs(fire.position.x))
	fire.rotation = deg_to_rad(90)

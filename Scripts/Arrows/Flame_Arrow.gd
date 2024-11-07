extends Arrow

@export var Charge_Inten_Mod : float = 2

@onready var flame = $Actions/Flame

func _ready():
	flame.parent_node = self
	if charged:
		flame.set_collision(coll.shape, 10)
		flame.Flame_Intensity *= 2
	else:
		flame.set_collision(coll.shape, 1)
 
func get_frozen() -> void:
	queue_free()

func _on_body_entered(_body) -> void:
	get_frozen()

func set_direction(dir) -> void:
	if direction != dir:
		super.set_direction(dir)
		flame = $Actions/Flame
		flame.position.x *= -1

func flip_children() -> void:
	super.flip_children()
	flame = $Actions/Flame
	flame.position = Vector2(flame.position.y, abs(flame.position.x))
	flame.rotation = deg_to_rad(90)

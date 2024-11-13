extends Arrow

@export var Time_Attached : float

@onready var shock = $Actions/Shock

func _ready():
	shock.parent_node = self
	shock.set_collision(coll.shape, 1)
 
func get_frozen() -> void:
	queue_free()

func _on_body_entered(body) -> void:
	super._on_body_entered(body)

func set_direction(dir) -> void:
	if direction != dir:
		super.set_direction(dir)
		shock = $Actions/Shock
		shock.position.x *= -1

func flip_children() -> void:
	super.flip_children()
	shock = $Actions/Shock
	shock.position = Vector2(shock.position.y, abs(shock.position.x))
	shock.rotation = deg_to_rad(90)

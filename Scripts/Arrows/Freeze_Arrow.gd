extends Arrow

@export var Freeze_Time : float = 5.0
@onready var freezer = $Actions/Freezer


func _ready() -> void:
	#super._ready()
	freezer.parent_node = self
	freezer.set_collision(coll.shape, 1.2)

func _on_body_entered(body) -> void:
	get_frozen()
	$Sprite.visible = false

func get_frozen() -> void:
	queue_free()

func set_direction(dir) -> void:
	if direction != dir:
		super.set_direction(dir)
		freezer = $Actions/Freezer
		freezer.position.x *= -1

func flip_children() -> void:
	super.flip_children()
	freezer = $Actions/Freezer
	freezer.position = Vector2(freezer.position.y, abs(freezer.position.x))
	freezer.rotation = deg_to_rad(90)

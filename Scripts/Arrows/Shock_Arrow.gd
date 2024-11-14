extends Arrow

@export var Charged_Time : float

@onready var shock = $Actions/Shock

var decharging_timer : Timer

func _ready():
	shock.parent_node = self
	shock.set_collision(coll.shape, 1)

func _on_body_entered(body) -> void:
	super._on_body_entered(body)

func start_decharging() -> void:
	if decharging_timer == null:
		decharging_timer = Timer.new()
		decharging_timer.autostart = false
		decharging_timer.timeout.connect(despawn_shock)
		decharging_timer.one_shot = true
		add_child(decharging_timer)
		decharging_timer.start(Charged_Time)

func despawn_shock() -> void:
	shock.queue_free()
	decharging_timer.queue_free()

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

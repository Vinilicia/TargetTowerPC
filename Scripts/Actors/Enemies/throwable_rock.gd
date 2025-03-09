extends RigidBody2D

@export var minimun_angle : int

var direction : int
var pos : float
var pos_thrower : float

func _physics_process(delta: float) -> void:
	await get_tree().create_timer(2).timeout
	queue_free()
	
func throw(position_target : Vector2) -> void:
	var x0 = position.x
	var y0 = position.y
	var xf = position_target.x
	var yf = position_target.y
	var g = 980
	var dx = abs(xf - x0)
	var dy = abs(yf - y0)
	# Com 20 pixels de erro
	var v0 = sqrt(((1960*dy+39200)+sqrt(3841600*dy*dy+153664000*dy+3841600*dx*dx+153664000*dx+3073280000))/2)
	var inside_sqrt = v0 * v0 * v0 * v0 - g * (g * dx * dx + 2 * dy * v0 * v0)
	var sqrt_term = sqrt(inside_sqrt)
	var theta = atan((v0 * v0 + sqrt_term) / (g * dx))
	var velocity_x = v0 * cos(theta)
	var velocity_y = -v0 * sin(theta)
	linear_velocity = Vector2(direction*velocity_x, velocity_y)
	
func _on_player_entered_damage_area(body: Node2D) -> void:
	queue_free()

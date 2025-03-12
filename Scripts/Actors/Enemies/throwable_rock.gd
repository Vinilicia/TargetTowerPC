extends RigidBody2D

@export var minimun_angle : int

var direction : int
var pos : float
var pos_thrower : float

func _physics_process(delta: float) -> void:
	await get_tree().create_timer(5).timeout
	queue_free()
	
func throw(position_target : Vector2) -> void:
	var x0 = position.x
	var y0 = position.y
	var xf = position_target.x
	var yf = position_target.y - 7
	var g = 980
	var yMax
	if round(yf - y0) == 3:
		yMax = y0 - 20
	elif yf < y0:
		yMax = yf - 20
	else:
		yMax = y0 - 30
	var vy = sqrt(2*g*abs(yMax))
	var t1 = vy/g
	var t2 = sqrt(2*(yf-yMax)/g)
	var vx = (xf-x0)/(t1+t2)
	linear_velocity = Vector2(vx, -vy)
	
func _on_player_entered_damage_area(body: Node2D) -> void:
	queue_free()

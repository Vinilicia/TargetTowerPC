extends CharacterBody2D
class_name SlimeBlob

@export var max_height : float = 30.0
@export var gravity : float = 588.0

func _ready() -> void:
	await get_tree().create_timer(5).timeout
	queue_free()

func throw(position_target : Vector2) -> void:
	var x0 = position.x
	var y0 = position.y
	var xf = position_target.x
	var yf = position_target.y - 7
	var g = gravity
	var yMax
	
	# Define a altura máxima do arco
	if round(yf - y0) == 3:
		yMax = y0 - max_height - 10
	elif yf < y0:
		yMax = yf - max_height
	else:
		yMax = y0 - max_height

	# Cálculo das velocidades iniciais (mesmo que no RigidBody)
	var vy = sqrt(2 * g * abs(yMax - y0))
	var t1 = vy / g
	var t2 = sqrt(2 * (yf - yMax) / g)
	var vx = (xf - x0) / (t1 + t2)

	# Define a velocidade inicial
	velocity = Vector2(vx, -vy)

func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta
	move_and_slide()

func _on_hit_something(_target: Node2D) -> void:
	queue_free()

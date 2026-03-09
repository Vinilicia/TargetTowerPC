extends CharacterBody2D
class_name SlimeBlob

@export var gravity : float = 980.0
@export var general_damage := true

var gravity_multiplier : float

func _ready() -> void:
	if not general_damage:
		($Hitbox as Hitbox).set_collision_layer_value(12, false)
	await get_tree().create_timer(0.1).timeout
	$Hitbox.monitorable = true
	
	await get_tree().create_timer(5).timeout
	queue_free()

func arc_throw(position_target : Vector2, max_height : float = 30, gravity_mult : float = 0.6) -> void:
	gravity_multiplier = gravity_mult
	var x0 = position.x
	var y0 = position.y
	var xf = position_target.x
	var yf = position_target.y - 7
	var g = gravity * gravity_multiplier
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

func straight_throw(position_target: Vector2, total_velocity : float = 280) -> void:
	gravity_multiplier = 0.0
	velocity = Vector2((position_target - position + Vector2(0, -10)).normalized() * total_velocity)

func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta * gravity_multiplier
	move_and_slide()

func _on_hit_something(_target: Node2D) -> void:
	queue_free()

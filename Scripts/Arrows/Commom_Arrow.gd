extends Node2D
class_name Arrow

@export var anim : AnimationPlayer
@export var sprite : Sprite2D
@export var trail : Trail
@export var hitbox : Hitbox

@export var Flying_Speed : float = 400
@export var Charge_Multiplier : float = 2
@export var Despawn_Time : float = 0
@export var Cost : int = 1

var flying_direction : Vector2 = Vector2(1, 0)
var facing_direction : int = 1
var charged : bool = false
var velocity := Vector2.ZERO 
var has_collided : bool = false

func _physics_process(delta):
	position += velocity * delta

func fly(is_charged: bool, _player: CharacterBody2D) -> void:
	set_deferred("monitoring", true)
	hitbox.set_deferred("monitorable", true)
	if is_charged:
		charged = true
		velocity = flying_direction.normalized() * Flying_Speed * Charge_Multiplier
	else:
		velocity = flying_direction.normalized() * Flying_Speed
	trail.set_deferred("process_mode", ProcessMode.PROCESS_MODE_INHERIT)

func flip_children() -> void:
	rotation = deg_to_rad(90)

func set_flying_direction(dir_vector: Vector2) -> void:
	rotation = dir_vector.angle()
	flying_direction = dir_vector.normalized()

func spawn_joint(body) -> void:
	var pos_relativa = global_position - body.global_position
	self.get_parent().call_deferred("remove_child", self)
	body.call_deferred("add_child", self)
	self.position = pos_relativa

func bounce() -> void:
	queue_free()

func despawn() -> void:
	await get_tree().create_timer(Despawn_Time).timeout
	queue_free()

func get_frozen() -> void:
	velocity = Vector2.ZERO

func _on_body_entered(body: Node2D) -> void:
	if has_collided:
		return
	has_collided = true
	get_frozen()
	if body.is_in_group("Attachables"):
		spawn_joint(body)
		despawn()
	else:
		bounce()

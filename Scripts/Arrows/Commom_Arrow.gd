extends CharacterBody2D
class_name Arrow

@onready var anim = $Anim_Player as AnimationPlayer
@onready var sprite = $Sprite as Sprite2D


@export var Flying_Speed : float = 50  
@export var Charge_Multiplier : float = 2
@export var Despawn_Time : float = 7

var direction : int = 1
var charged : bool = false
var downward : bool = false

func _physics_process(delta):
	move_and_slide()


func fly(is_charged : bool, _player : CharacterBody2D) -> void:
	if downward:
		flip_children()
		downward = false
	if is_charged:
		charged = true
		velocity = Vector2(direction * Flying_Speed * Charge_Multiplier, 0)
	else:
		velocity = Vector2(direction * Flying_Speed, 0)

func fly_downward(_player : CharacterBody2D) -> void:
	flip_children()
	downward = true
	velocity = Vector2(0, Flying_Speed * 1.2)

func flip_children() -> void:
	var collision = $Collision
	var coll = collision.get_child(0)
	
	if downward:
		$Sprite.rotation = deg_to_rad(0)
		collision.position = Vector2(collision.position.y, abs(collision.position.x))
		collision.rotation = deg_to_rad(0)
		
	else:
		if direction == 1:
			$Sprite.rotation = deg_to_rad(90)
		else:
			$Sprite.rotation = deg_to_rad(-90)
		collision.position = Vector2(collision.position.y, abs(collision.position.x))
		collision.rotation = deg_to_rad(90)


func set_direction(dir : int) -> void:
	if direction != dir:
		$Collision.position.x *= -1
		flip_sprite()
		direction = dir


func flip_sprite() -> void:
	if $Sprite.flip_h == true:
		$Sprite.flip_h = false
	else: 
		$Sprite.flip_h = true

func _on_body_entered(body):
	get_frozen()
	if body.is_in_group("Attachables"):
		spawn_joint(body)
		despawn()
	if !body.is_in_group("Attachables"):
		bounce()

func spawn_joint(body) -> void:
	#var joint = PinJoint2D.new()
	#joint.position = Vector2.ZERO
	#joint.node_b = body.get_path()
	#joint.node_a = self.get_path()
	#get_tree().current_scene.add_child(joint)
	var pos = global_position
	var pos_relativa = pos - body.global_position
	self.get_parent().remove_child(self)
	body.add_child(self)
	self.position = pos_relativa

func bounce() -> void:
	despawn()

func despawn() -> void:
	await get_tree().create_timer(Despawn_Time).timeout
	queue_free()

func get_frozen() -> void:
	velocity = Vector2.ZERO
	$Collision/Coll.disabled = true

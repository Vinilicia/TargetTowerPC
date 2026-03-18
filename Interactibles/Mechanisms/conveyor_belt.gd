@tool
extends Node2D

@onready var area : Area2D = $Belt
@onready var static_body : StaticBody2D = $StaticBody
@onready var sprite_nodes : Node2D = $SpriteNodes
@onready var left_sprite : Sprite2D = $SpriteNodes/LeftSprite
@onready var middle_sprite : Sprite2D = $SpriteNodes/MiddleSprite
@onready var right_sprite : Sprite2D = $SpriteNodes/RightSprite


enum BeltDir { LEFT, RIGHT }

@export var belt_dir: BeltDir = BeltDir.RIGHT:
	set(new_dir):
		belt_dir = new_dir
		_set_belt_direction_from_enum(new_dir)

var belt_direction: Vector2 = Vector2.RIGHT

@export_range(20, 120, 10, 'hide_slider') var belt_speed : float = 20:
	set(new_speed):
		if not is_node_ready():
			await ready
		
		var anim_modifier : int = max(new_speed / 30, 1)
		
		var anim_texture : AnimatedTexture = left_sprite.texture
		anim_texture.speed_scale = 0.5 * anim_modifier
		
		anim_texture = right_sprite.texture
		anim_texture.speed_scale = 0.5 * anim_modifier
		
		anim_texture = middle_sprite.texture
		anim_texture.speed_scale = 0.5 * anim_modifier
		
		belt_speed = new_speed


@export_group("Editor")

@export var length : int = 0:
	set(new_length):
		_update_length(new_length)
		length = new_length

var bodies_inside : Array[Node2D] = []

func _physics_process(_delta: float) -> void:
	if !Engine.is_editor_hint():
		apply_speed()

func apply_speed() -> void:
	for body in bodies_inside:
		var v_component : VelocityComponent = body.find_child("VelocityComponent")
		if v_component:
			if !body.is_on_floor():
				v_component.set_ground_velocity(Vector2.ZERO)
			else:
				v_component.set_ground_velocity(belt_direction * belt_speed)

func _set_belt_direction_from_enum(new_dir: int) -> void:
	match new_dir:
		BeltDir.LEFT:
			belt_direction = Vector2.LEFT
		BeltDir.RIGHT:
			belt_direction = Vector2.RIGHT

	_update_length(length)


func _update_length(new_length: int) -> void:
	if not is_node_ready():
		await ready
	
	left_sprite.region_rect = Rect2(0, 0, 0, 0)
	middle_sprite.region_rect = Rect2(0, 0, 0, 0)
	right_sprite.region_rect = Rect2(0, 0, 0, 0)

	sprite_nodes.rotation_degrees = 0
	sprite_nodes.scale = Vector2(1, 1)

	area.scale.x = new_length * 16 * -belt_direction.x
	area.position.x = new_length * 8 * -belt_direction.x

	static_body.scale.x = new_length * 16 * -belt_direction.x
	static_body.position.x = new_length * 8 * -belt_direction.x

	area.scale.y = 12
	area.position.y = -8

	static_body.scale.y = 12
	static_body.position.y = -6

	if new_length > 3:
		left_sprite.region_rect = Rect2(0, 0, 16, 12)
		left_sprite.position.x = 8 * -belt_direction.x
		left_sprite.scale.x = -belt_direction.x

		middle_sprite.region_rect = Rect2(0, 0, 16 * (new_length - 2), 12)
		middle_sprite.position.x = ((16 * float(new_length)) / 2) * -belt_direction.x
		middle_sprite.scale.x = -belt_direction.x

		right_sprite.region_rect = Rect2(0, 0, 16, 12)
		right_sprite.position.x = ((16 * new_length) - 8) * -belt_direction.x
		right_sprite.scale.x = -belt_direction.x


func reverse_direction() -> void:
	belt_direction *= -1

	if belt_direction == Vector2.LEFT:
		belt_dir = BeltDir.LEFT
	elif belt_direction == Vector2.RIGHT:
		belt_dir = BeltDir.RIGHT

	_set_belt_direction_from_enum(belt_dir)

	for body in bodies_inside:
		var v_component = body.find_child("VelocityComponent")
		if v_component:
			v_component.add_ground_velocity(belt_direction * belt_speed * 2)


func _on_belt_body_entered(body: Node2D) -> void:
	var v_component : VelocityComponent = body.find_child("VelocityComponent")
	if v_component:
		bodies_inside.append(body)

func _on_belt_body_exited(body: Node2D) -> void:
	if bodies_inside.has(body):
		bodies_inside.erase(body)
		var v_component : VelocityComponent = body.find_child("VelocityComponent")
		if v_component:
			v_component.set_ground_velocity(Vector2.ZERO)

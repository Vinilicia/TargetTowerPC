@tool
extends Node2D

@onready var area : Area2D = $Belt
@onready var static_body : StaticBody2D = $StaticBody
@onready var sprite_nodes : Node2D = $SpriteNodes
@onready var left_sprite : Sprite2D = $SpriteNodes/LeftSprite
@onready var middle_sprite : Sprite2D = $SpriteNodes/MiddleSprite
@onready var right_sprite : Sprite2D = $SpriteNodes/RightSprite

# --- Enum para direções ---
enum BeltDir { LEFT, RIGHT, UP, DOWN }

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


func _set_belt_direction_from_enum(new_dir: int) -> void:
	match new_dir:
		BeltDir.LEFT:
			belt_direction = Vector2.LEFT
		BeltDir.RIGHT:
			belt_direction = Vector2.RIGHT
		BeltDir.UP:
			belt_direction = Vector2.UP
		BeltDir.DOWN:
			belt_direction = Vector2.DOWN
	
	# vira o sprite conforme a direção
	if belt_direction.x != 0:
		pass
	elif belt_direction.y != 0:
		pass

	_update_length(length)

func _update_length(new_length: int) -> void:
	if not is_node_ready():
		await ready
	
	left_sprite.region_rect = Rect2(0, 0, 0, 0)
	middle_sprite.region_rect = Rect2(0, 0, 0, 0)
	right_sprite.region_rect = Rect2(0, 0, 0, 0)

	if belt_direction.x != 0: # Horizontal
		
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
			middle_sprite.position.x = ((16 * new_length) / 2) * -belt_direction.x
			middle_sprite.scale.x = -belt_direction.x
			
			right_sprite.region_rect = Rect2(0, 0, 16, 12)
			right_sprite.position.x = ((16 * new_length) - 8) * -belt_direction.x
			right_sprite.scale.x = -belt_direction.x

	elif belt_direction.y != 0: # Vertical
		
		sprite_nodes.rotation_degrees = -90
		sprite_nodes.scale = Vector2(-1, -1)
		
		area.scale.y = new_length * 16 * -belt_direction.y
		area.position.y = new_length * 8 * -belt_direction.y

		static_body.scale.y = new_length * 16 * -belt_direction.y
		static_body.position.y = new_length * 8 * -belt_direction.y
		
		static_body.scale.x = 12
		static_body.position.x = 4

		area.scale.x = 12
		area.position.x = 6
		
		if new_length > 3:
			left_sprite.region_rect = Rect2(0, 0, 16, 12)
			left_sprite.position.x = 8 * -belt_direction.y
			left_sprite.scale.x = -belt_direction.y
			
			middle_sprite.region_rect = Rect2(0, 0, 16 * (new_length - 2), 12)
			middle_sprite.position.x = ((16 * new_length) / 2) * -belt_direction.y
			middle_sprite.scale.x = -belt_direction.y
			
			right_sprite.region_rect = Rect2(0, 0, 16, 12)
			right_sprite.position.x = ((16 * new_length) - 8) * -belt_direction.y
			right_sprite.scale.x = -belt_direction.y

func reverse_direction() -> void:
	belt_direction *= -1
	# atualiza enum para refletir inversão
	if belt_direction == Vector2.LEFT:
		belt_dir = BeltDir.LEFT
	elif belt_direction == Vector2.RIGHT:
		belt_dir = BeltDir.RIGHT
	elif belt_direction == Vector2.UP:
		belt_dir = BeltDir.UP
	elif belt_direction == Vector2.DOWN:
		belt_dir = BeltDir.DOWN
	
	_set_belt_direction_from_enum(belt_dir)

	for body in bodies_inside:
		var v_component = body.find_child("VelocityComponent")
		if v_component:
			v_component.add_ground_velocity(belt_direction * belt_speed * 2)

func _on_belt_body_entered(body: Node2D) -> void:
	var v_component : VelocityComponent = body.find_child("VelocityComponent")
	if v_component:
		bodies_inside.append(body)
		v_component.add_ground_velocity(belt_direction * belt_speed)

func _on_belt_body_exited(body: Node2D) -> void:
	var v_component : VelocityComponent = body.find_child("VelocityComponent")
	if v_component:
		bodies_inside.erase(body)
		v_component.add_ground_velocity(belt_direction * -belt_speed)

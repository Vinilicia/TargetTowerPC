@tool
extends Area2D

@onready var sprite: Sprite2D = $FireSprite
@onready var coll: CollisionShape2D = $Coll

@export var extinguishes := true
@export var extinguish_time := 5.0
@export var width := 4
@export var spread_step := 13.0
@export var max_spread_distance := 50.0
@export var ground_check_distance := 200.0
@export var ground_layer := 1

var debug_rays : Array[Dictionary] = []

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	await get_tree().process_frame
	adjust_to_ground()
	if extinguishes:
		await get_tree().create_timer(extinguish_time).timeout
		queue_free()

func adjust_to_ground() -> void:
	debug_rays.clear()
	var space = get_world_2d().direct_space_state
	var origin = global_position
	var half_spread = max_spread_distance / 2.0

	var has_ground_at : Callable = func(x_offset: float) -> bool:
		var start = origin + Vector2(x_offset, 0)
		var end = start + Vector2(0, ground_check_distance)
		var query = PhysicsRayQueryParameters2D.create(start, end)
		query.collision_mask = self.collision_mask
		var result = space.intersect_ray(query)

		# Armazena pra visualização
		debug_rays.append({
			"from": start,
			"to": end,
			"hit": result != null
		})

		if result:
			print("✅ Ray at offset %.1f HIT ground at %s" % [x_offset, str(result.position)])
			return true
		else:
			print("❌ Ray at offset %.1f missed (no ground)" % x_offset)
			return false

	var right_dist := 0.0
	while right_dist < half_spread and has_ground_at.call(right_dist):
		right_dist += spread_step

	var left_dist := 0.0
	while left_dist < half_spread and has_ground_at.call(-left_dist):
		left_dist += spread_step

	print("--- Ground check summary ---")
	print("Left distance:  ", left_dist)
	print("Right distance: ", right_dist)
	print("Total width:    ", (left_dist - 13 + right_dist - 13) / 13.0)
	print("-----------------------------")

	var total_width = (left_dist - 13 + right_dist - 13) / 13.0
	width = int(clamp(total_width, 1, max_spread_distance / 10))
	update_length(width)

	position.x -= (left_dist - right_dist) * 0.5

func update_length(new_width: int) -> void:
	if not is_node_ready():
		await ready
	if sprite and coll:
		sprite.region_rect = Rect2(0, 0, 13 * new_width, 24)
		coll.scale = Vector2(new_width * 13 - 2, 22)

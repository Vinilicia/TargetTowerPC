extends Arrow

@export var surface_checker : PackedScene
@export var shock_hitbox : Hitbox
@export var area_length : float = 200

func _handle_collision(collision: KinematicCollision2D) -> void:
	super._handle_collision(collision)
	spawn_shock_area()

func spawn_shock_area() -> void:
	var surf_checker : Node2D = surface_checker.instantiate()
	add_child(surf_checker)
	assert(surf_checker.has_method("get_polygon"), "SURFACE CHECKER NÃO TEM MÉTODO GET_POLYGON")
	surf_checker.position = $Coll.position
	var area_polygon : CollisionPolygon2D = surf_checker.get_polygon(area_length)
	area_polygon.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
	shock_hitbox.position = $Coll.position
	await shock_hitbox.call_deferred("add_child", area_polygon)

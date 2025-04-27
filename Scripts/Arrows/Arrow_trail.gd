extends Line2D
class_name Trail

@export var max_points : int

var queue : Array[Vector2]

func _process(_delta: float) -> void:
	var pos : Vector2 = set_next_point()
	
	queue.push_front(pos)
	
	if queue.size() > max_points:
		queue.pop_back()
	
	clear_points()
	
	for point in queue:
		add_point(point)

func set_next_point() -> Vector2:
	var parent: Arrow = get_parent()
	return parent.global_position - parent.flying_direction.normalized() * 10

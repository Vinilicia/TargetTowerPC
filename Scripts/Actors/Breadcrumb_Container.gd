extends Node

@export var spawning_timer : Timer

@export var spawning_delay : float
@export var breadcrumb_max : int

@export var breadcrumb_path : String

var breadcrumbs : Array[Breadcrumb]
var breadcrumb_count : float = 0

var pursuer_count : int = 0

var spawning : bool = false

func add_pursuer() -> void:
	pursuer_count += 1

func _physics_process(delta: float) -> void:
	if pursuer_count > 0 and not spawning:
		spawning = true
		start_spawning()
	
	if pursuer_count == 0 and spawning:
		stop_spawning()
	
	manage_breadcrumbs()

func manage_breadcrumbs() -> void:
	if breadcrumb_count > breadcrumb_max:
		var oldest = breadcrumbs.pop_front()
		oldest.queue_free()
		breadcrumb_count -= 1

func stop_spawning() -> void:
	spawning_timer.stop()

func start_spawning() -> void:
	spawning_timer.start(spawning_delay)

func _spawn_breadcrumb() -> void:
	var breadcrumb : Breadcrumb = load(breadcrumb_path).instantiate()
	var pos = get_parent().global_position
	breadcrumb.global_position = pos
	breadcrumbs.push_back(breadcrumb)
	breadcrumb.array_pos = breadcrumbs.find(breadcrumb)
	get_parent().get_parent().call_deferred("add_child", breadcrumb)
	set_deferred("breadcrumb_count", breadcrumb_count + 1)

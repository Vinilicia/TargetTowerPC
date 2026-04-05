extends Arrow

@export var wind_force_air : float = 200.0
@export var wind_force_ground : float = 120.0
@export var wind_force_jump : float = 340.0
@export var wind_duration : float = 0.2

func _on_wind_area_body_entered(body: Node2D) -> void:
	add_velocity(body)

func add_velocity(body : Node2D) -> void:
	var v_comp : VelocityComponent = body.find_child("VelocityComponent")
	if v_comp:
		v_comp.add_ground_velocity(wind_force_ground * flying_direction)
		v_comp.add_wind_velocity(wind_force_air * flying_direction) 
	get_tree().create_timer(wind_duration).timeout.connect(sub_velocity.bind(body))

func sub_velocity(body: Node2D) -> void:
	var v_comp : VelocityComponent = body.find_child("VelocityComponent")
	if v_comp:
		v_comp.add_ground_velocity(-wind_force_ground * flying_direction)
		v_comp.add_wind_velocity(-wind_force_air * flying_direction) 

func _on_hitbox_hit(_target: Node2D) -> void:
	pass

func fly(is_charged: bool, _player: Player) -> void:
	super.fly(is_charged, _player)
	if flying_direction.angle_to(Vector2.RIGHT) < deg_to_rad(-70) and flying_direction.angle_to(Vector2.RIGHT) > deg_to_rad(-110):
		_player.v_comp.set_proper_velocity(-wind_force_jump, 2)

extends Enemy

@export_group("Nodes")
@export var ledge_detector : Detector
@export var wall_detector : Detector
@export var sight_area : Area2D
@export var attack_area : Area2D
@export var slam_hitbox : Hitbox
@export var idle_timer : Timer

@export_group("Variants")
@export var walk_speed : float = 60.0
@export var jump_velocity : Vector2 = Vector2(100, 200)
@export var slam_attack_duration : float = 0.3
@export var attack_recovery_time : float = 1.0
@export var attack_cooldown : float = 3.0
@export var initial_attack_delay : float = 1.0
@export var wake_up_delay : float = 0.4
@export var walking_time : float = 10.0

enum State {Idle, Walking, Attacking, Crumbled}

var state : State = State.Idle
var direction : int = 1

func _ready() -> void:
	super._ready()
	go_to_idle()

func go_to_walk_state() -> void:
	ledge_detector.enabled = true
	wall_detector.enabled = true
	var new_direction : int = 1 if randf_range(0, 1) > 0.5 else -1
	if direction != new_direction:
		turn()
	await get_tree().create_timer(wake_up_delay).timeout
	state = State.Walking
	idle_timer.start(walking_time)

func _physics_process(delta: float) -> void:
	if state == State.Walking:
		v_component.set_proper_velocity(Vector2(walk_speed * direction, 0))
	grounded_behaviour(delta)

func turn() -> void:
	direction = -direction
	$Reversables.scale.x = direction

func _on_ledge_detector_not_colliding() -> void:
	if state == State.Walking:
		turn()

func _on_wall_detector_colliding() -> void:
	if state == State.Walking:
		turn()

func go_to_attacking_state() -> void:
	idle_timer.stop()
	state = State.Attacking
	ledge_detector.enabled = false
	wall_detector.enabled = false
	attack_area.set_deferred("monitoring", false)
	attack()

func attack() -> void:
	v_component.set_proper_velocity(Vector2(jump_velocity.x * direction, jump_velocity.y))
	velocity = v_component.get_total_velocity()
	move_and_slide()
	get_tree().process_frame.connect(ground_check_for_attack)

func ground_check_for_attack() -> void:
	if is_on_floor():
		get_tree().process_frame.disconnect(ground_check_for_attack)
		slam()

func slam() -> void:
	hurtbox.lose_invincible()
	v_component.set_proper_velocity(Vector2.ZERO)
	slam_hitbox.set_deferred("monitorable", true)
	await get_tree().create_timer(slam_attack_duration).timeout
	slam_hitbox.set_deferred("monitorable", false)
	go_to_crumbled()

func go_to_crumbled() -> void:
	state = State.Crumbled
	await get_tree().create_timer(attack_recovery_time).timeout
	hurtbox.get_invincible()
	go_to_walk_state()
	get_tree().create_timer(attack_cooldown).timeout.connect(func() : 
		attack_area.set_deferred("monitoring", true))

func _on_sight_area_body_entered(_body: Node2D) -> void:
	if state == State.Idle:
		go_to_walk_state()
		get_tree().create_timer(initial_attack_delay + wake_up_delay).timeout.connect(func() :
			attack_area.set_deferred("monitoring", true))

func _on_attack_area_body_entered(body: Node2D) -> void:
	if state != State.Walking:
		return
	if sign(to_local(body.global_position).x) != direction:
		turn()
	go_to_attacking_state()

func _on_hurtbox_hit_while_invincible(hitbox : Hitbox) -> void:
	hitbox.hit_something(self)

func go_to_idle() -> void:
	v_component.set_proper_velocity(Vector2.ZERO)
	velocity = Vector2.ZERO
	state = State.Idle
	ledge_detector.enabled = false
	wall_detector.enabled = false
	hurtbox.get_invincible()
	attack_area.set_deferred("monitoring", false)

func _on_idle_timer_timeout() -> void:
	go_to_idle()

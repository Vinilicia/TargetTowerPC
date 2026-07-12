extends CharacterBody2D
class_name Enemy

@export var regret_scene : PackedScene
@export var fire_component_scene : PackedScene
@export var ice_component_scene : PackedScene
@export var electric_component_scene : PackedScene
@export_group("Nodes")
@export var v_component : VelocityComponent
@export var health_man : HealthManager
@export var hurtbox : Hurtbox
@export var material_anim : AnimationPlayer

@export_group("Variants")
@export var spawns_money := true
@export var money_amount : float = 1
@export_subgroup("Elements")
@export var regular_flammable : bool = true
@export var regular_freezable : bool = true
@export var regular_shockable : bool = true
@export var stunned_nodes : Array[Node]

var fire_comp : FireComponent = null
var ice_comp : IceComponent = null
var electric_comp : ElectricComponent = null

var stunned : bool = false

signal died

func _ready() -> void:
	if regular_flammable and fire_component_scene:
		fire_comp = fire_component_scene.instantiate()
		fire_comp.parent_health_man = health_man
		hurtbox.call_deferred("add_child", fire_comp)
		fire_comp.effect_started.connect(_on_fire_comp_effect_started)
	if regular_freezable and ice_component_scene:
		ice_comp = ice_component_scene.instantiate()
		ice_comp.parent_health_man = health_man
		ice_comp.regular_behaviour = true
		hurtbox.call_deferred("add_child", ice_comp)
	if regular_shockable and electric_component_scene:
		electric_comp = electric_component_scene.instantiate()
		electric_comp.parent_health_man = health_man
		hurtbox.call_deferred("add_child", electric_comp)
		electric_comp.effect_started.connect(_on_electric_comp_effect_started)

func die() -> void:
	died.emit()
	if spawns_money:
		spawn_money()
	queue_free()

func spawn_money() -> void:
	for i in range(money_amount):
		var new_regret : CharacterBody2D = regret_scene.instantiate()
		new_regret.position = position + Vector2(randf_range(-5, 5), randf_range(-4, 2))
		new_regret.v_comp.set_proper_velocity(Vector2(randf_range(-30, 30), randf_range(-70, -150)))
		get_parent().call_deferred("add_child", new_regret)

func took_damage(amount : float) -> void:
	if amount > 0:
		AudioManager.play_song("EnemyHit")
		material_anim.play("hitflash")

func run_out_of_health() -> void:
	die()

func apply_gravity(delta : float) -> void:
	v_component.add_gravity_velocity(Vector2(0, get_gravity().y * delta))

func grounded_behaviour(delta : float) -> void:
	if stunned:
		return
	if !is_on_floor() -> void:
		apply_gravity(delta)
	else:
		v_component.set_proper_velocity(0.0, 2)
		v_component.set_gravity_velocity(Vector2.ZERO)
	
	velocity = v_component.get_total_velocity()
	move_and_slide()

func _on_fire_comp_effect_started() -> void:
	if not fire_comp.effect_ended.is_connected(health_man.stop_burning):
		fire_comp.effect_ended.connect(health_man.stop_burning, CONNECT_ONE_SHOT)
		health_man.start_burning(0.5)

func _on_electric_comp_effect_started() -> void:
	if not electric_comp.effect_ended.is_connected(unstun):
		electric_comp.effect_ended.connect(unstun)
	stun()

func stun() -> void:
	stunned = true
	for node in stunned_nodes:
		node.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)

func unstun() -> void:
	stunned = false
	for node in stunned_nodes:
		node.set_deferred("process_mode", Node.PROCESS_MODE_INHERIT)

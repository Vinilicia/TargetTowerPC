extends CharacterBody2D

class_name Enemy

@export var v_component : VelocityComponent
@export var health_man : HealthManager

@export var spawns_money := true
@export var money_amount : float = 1

@onready var regret_scene : RigidBody2D = preload("res://Scenes/Items/Small_Regret.tscn").instantiate()

signal died

func die() -> void:
	died.emit()
	if spawns_money:
		spawn_money()
	queue_free()

func spawn_money() -> void:
	for i in range(money_amount):
		var new_regret : RigidBody2D = regret_scene.duplicate()
		new_regret.position = global_position + Vector2(randf_range(-5, 5), randf_range(-4, 0))
		new_regret.linear_velocity = Vector2(randf_range(-10, 10), randf_range(-20, -20))
		get_parent().call_deferred("add_child", new_regret)

func took_damage(_amount : float) -> void:
	pass
	
func run_out_of_health() -> void:
	die()

func apply_gravity(delta : float) -> void:
	v_component.add_proper_velocity(Vector2(0, get_gravity().y * delta))

func grounded_behaviour(delta : float) -> void:
	if !is_on_floor():
		apply_gravity(delta)
	else:
		pass
		#v_component.set_proper_velocity(0.0, 2)
	
	velocity = v_component.get_total_velocity()
	move_and_slide()

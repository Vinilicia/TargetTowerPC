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
		new_regret.position = position + Vector2(randf_range(-5, 5), randf_range(-4, 2))
		new_regret.linear_velocity = Vector2(randf_range(-30, 30), randf_range(-70, -150))
		get_parent().call_deferred("add_child", new_regret)

func took_damage(_amount : float) -> void:
	AudioManager.play_song("EnemyHit")
	
func run_out_of_health() -> void:
	die()

func apply_gravity() -> void:
	v_component.set_proper_velocity(get_gravity().y, 2)

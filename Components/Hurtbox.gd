extends Area2D
class_name Hurtbox

@export var parent : Node2D
@export var invincibility_timer : Timer
@export var invincibility_duration : float = 1.0:
	set(value):
		if value < 0.0:
			value = 1.0
		invincibility_duration = value
@export var can_be_invincible : bool = true

@export var flammable : bool = false
@export var freezable : bool = false
@export var shockable : bool = false

var is_invincible : bool = false
var absorb_hits : bool

signal took_damage(amount : float)
signal got_hit_by(hitbox : Hitbox)
signal gained_invencibility
signal lost_invencibility
signal hit_while_invincible(hitbox : Hitbox)

signal fire_entered(hitbox : Hitbox)
signal fire_exited(hitbox : Hitbox)
signal ice_entered(hitbox : Hitbox)
signal ice_exited(hitbox : Hitbox)
signal electric_entered(hitbox : Hitbox)
signal electric_exited(hitbox : Hitbox)

const fire_layer : int = 13
const electric_layer : int = 14
const ice_layer : int = 15
const player_dam_layer : int = 9
const enemy_dam_layer : int = 11
const general_dam_layer : int = 12

func _ready() -> void:
	assert(ProjectSettings.get_setting("layer_names/2d_physics/layer_" + str(fire_layer)) == "Fire")
	assert(ProjectSettings.get_setting("layer_names/2d_physics/layer_" + str(ice_layer)) == "Ice")
	assert(ProjectSettings.get_setting("layer_names/2d_physics/layer_" + str(electric_layer)) == "Electric")
	assert(ProjectSettings.get_setting("layer_names/2d_physics/layer_" + str(player_dam_layer)) == "Player Damage")
	assert(ProjectSettings.get_setting("layer_names/2d_physics/layer_" + str(enemy_dam_layer)) == "Enemy Damage")
	assert(ProjectSettings.get_setting("layer_names/2d_physics/layer_" + str(general_dam_layer)) == "General Damage")

func got_hit(hitbox : Area2D) -> void:
	assert(hitbox is Hitbox, "Hurtbox de " + parent.name + " detectou área que não era hitbox (entrando)!")
	hitbox = hitbox as Hitbox
	if hitbox.parent == parent:
		return
	if not is_invincible:
		handle_hit(hitbox)
	else:
		hit_while_invincible.emit(hitbox)

func handle_hit(hitbox : Hitbox) -> void:
	if hitbox.get_collision_layer_value(fire_layer) and flammable:
		fire_entered.emit(hitbox)
	elif hitbox.get_collision_layer_value(ice_layer) and freezable:
		ice_entered.emit(hitbox)
	elif hitbox.get_collision_layer_value(electric_layer) and shockable:
		electric_entered.emit(hitbox)

	if hitbox.get_collision_layer_value(player_dam_layer) or \
		hitbox.get_collision_layer_value(enemy_dam_layer) or \
		hitbox.get_collision_layer_value(general_dam_layer):
			got_hit_by.emit(hitbox)
			took_damage.emit(hitbox.Damage)
			hitbox.hit_something(parent)
			get_invincible_for()

func get_invincible_for(duration_override : float = -1.0) -> void:
	if not can_be_invincible:
		return
	get_invincible()
	var duration = duration_override if duration_override > 0 else invincibility_duration
	invincibility_timer.start(duration)
	await invincibility_timer.timeout
	lose_invincible()

func get_invincible() -> void:
	is_invincible = true
	gained_invencibility.emit()

func lose_invincible() -> void:
	is_invincible = false
	set_deferred("monitoring", false)
	set_deferred("monitoring", true)
	lost_invencibility.emit()

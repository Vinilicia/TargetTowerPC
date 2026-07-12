extends Component
class_name FireComponent

@export var extinguishing_timer : Timer
@export var burning_timer : Timer
@export var fire_sprite_scene : PackedScene
@export var fire_scene : PackedScene
@export_group("Variant values")
@export var has_basic_fire : bool = true
@export var burn_time : float = 2.5
@export var extinguish_time : float = 4.0
@export var can_stack : bool = false

var on_fire : bool = false
var overlapping_fire_count : int = 0
var fire_sprite_instance : Sprite2D = null
var fire_instance : Fire = null

func instantiate_fire() -> void:
	fire_instance = fire_scene.instantiate()
	var hurtbox_coll : CollisionShape2D = hurtbox.find_child("Coll", false)
	assert(hurtbox_coll, "Hurtbox de " + hurtbox.parent.name + " não tem 'Coll' como filho!")
	fire_instance.set_collision(hurtbox_coll, hurtbox.scale)
	effect_started.connect(fire_instance._activate)
	effect_ended.connect(fire_instance._deactivate)

func instantiate_fire_sprite() -> void:
	fire_sprite_instance = fire_sprite_scene.instantiate()
	fire_sprite_instance.visible = false
	if has_basic_fire:
		effect_started.connect(func() -> void: 
			fire_sprite_instance.visible = true
			)
		effect_ended.connect(func() -> void:
			fire_sprite_instance.visible = false)

func _ready() -> void:
	hurtbox_check("fire_layer", "flammable")
	
	hurtbox.fire_entered.connect(_got_hit)
	hurtbox.area_exited.connect(_hurtbox_exited)
	
	if has_basic_fire:
		instantiate_fire()
		hurtbox.parent.call_deferred("add_child", fire_instance)
		instantiate_fire_sprite()
		fire_instance.call_deferred("add_child", fire_sprite_instance)

func _got_hit(hitbox: Hitbox) -> void:
	overlapping_fire_count += 1
	if on_fire and !can_stack:
		return
	if hitbox.instant:
		start()
	else:
		burning_timer.start(burn_time)

func _hurtbox_exited(area: Area2D) -> void:
	assert(area is Hitbox, "Hitbox de " + hurtbox.parent.name + "detectou área que não era Hitbox (saindo)!")
	var hitbox : Hitbox = area as Hitbox
	if hitbox.get_collision_layer_value(hurtbox.fire_layer):
		overlapping_fire_count -= 1
		if overlapping_fire_count < 0:
			overlapping_fire_count = 0
		if overlapping_fire_count == 0 and !on_fire:
			if !burning_timer.is_stopped() -> void:
				burning_timer.stop()

func start() -> void:
	if !(overlapping_fire_count > 0):
		return
	on_fire = true
	effect_started.emit()
	
	var time_left : float = 0
	if can_stack and !extinguishing_timer.is_stopped() -> void:
		time_left = extinguishing_timer.time_left
	extinguishing_timer.start(extinguish_time + time_left)

func end() -> void:
	on_fire = false
	effect_ended.emit()

extends Component
class_name IceComponent

@export var regular_behaviour : bool = true
@export var frozen_duration : float = 5.0
@export var can_stack : bool = false
@export_group("Nodes")
@export var ice_block_scene : PackedScene

var frozen : bool = false

func _ready() -> void:
	hurtbox_check("ice_layer", "freezable")
	hurtbox.ice_entered.connect(_hurtbox_got_hit)

func _hurtbox_got_hit(_hitbox: Hitbox) -> void:
	if frozen and !can_stack:
		return
	effect_started.emit()
	if regular_behaviour:
		assert(parent_health_man != null, "SEM parent_health_man EM ICE MANAGER DE " + hurtbox.parent.name)
		await get_tree().process_frame
		if parent_health_man.health > 0:
			regular_hit_behaviour()

func regular_hit_behaviour() -> void:
	hurtbox.parent.set_deferred("process_mode", PROCESS_MODE_DISABLED)
	start()

func regular_melt_behaviour() -> void:
	hurtbox.parent.set_deferred("process_mode", PROCESS_MODE_INHERIT)

func start() -> void:
	frozen = true
	var ice_block : IceBlock = ice_block_scene.instantiate()
	ice_block.was_melt.connect(end)
	ice_block.initialize(hurtbox.scale, hurtbox.parent, frozen_duration)

func end() -> void:
	frozen = false
	effect_ended.emit()
	if regular_behaviour:
		regular_melt_behaviour()

extends Component
class_name ElectricComponent

var shocked : bool = false
var overlapping_electric_count : int = 0

func _ready() -> void:
	hurtbox_check("electric_layer", "shockable")
	hurtbox.electric_entered.connect(_hurtbox_got_hit)
	hurtbox.area_exited.connect(_hurtbox_area_exited)

func _hurtbox_got_hit(_hitbox: Hitbox) -> void:
	overlapping_electric_count += 1
	start()

func _hurtbox_area_exited(area : Area2D) -> void:
	assert(area is Hitbox, "Hitbox de " + hurtbox.parent.name + "detectou área que não era Hitbox (saindo)!")
	var hitbox : Hitbox = area as Hitbox
	if hitbox.get_collision_layer_value(hurtbox.electric_layer):
		overlapping_electric_count -= 1
		if overlapping_electric_count < 0:
			overlapping_electric_count = 0
		if overlapping_electric_count == 0:
			end()
 

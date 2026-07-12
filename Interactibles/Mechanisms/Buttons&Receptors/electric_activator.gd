extends Activator

enum ActivationMode {Eternal, DurationBased, ContactBased}

@export var activation_mode : ActivationMode = ActivationMode.Eternal
@export var duration : float = 0.5
@export var hurtbox : Hurtbox

func activate(_variable : Variant = null) -> void:
	super.activate()
	if activation_mode == ActivationMode.DurationBased:
		get_tree().create_timer(duration).timeout.connect(deactivate.bind(null))

func deactivate(_variable : Variant = null) -> void:
	if activation_mode == ActivationMode.Eternal:
		return
	elif _variable == null or activation_mode == ActivationMode.ContactBased:
		super.deactivate()

func turn_off() -> void:
	hurtbox.set_deferred("monitoring", false)
	await get_tree().process_frame
	hurtbox.set_deferred("monitoring", true)
	scale = Vector2.ONE

func turn_on() -> void:
	scale = 1.2 * Vector2.ONE

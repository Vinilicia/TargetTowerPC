extends Activator

@onready var anim = $Area/RedTargetSprite

func activate(_variable : Variant) -> void:
	if _variable is Hitbox:
		anim.play("Not Shining")
		super.activate(_variable)

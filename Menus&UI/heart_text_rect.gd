extends TextureRect
class_name HeartTexture

@export var anim: AnimationPlayer

var full : bool = true

func drain() -> void:
	anim.play("Breaking")
	anim.queue("Draining")
	anim.queue("Empty")

func fill() -> void:
	anim.play("Healing")
	anim.queue("Full")

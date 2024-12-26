extends Area2D

signal is_hit

var was_hit = false

func _process(delta):
	if was_hit:
		emit_signal("is_hit")
		was_hit = false

func _on_body_entered(body):
	was_hit = true

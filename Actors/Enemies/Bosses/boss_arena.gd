extends Area2D

@export var boss : Boss

func _ready() -> void:
	open()
	boss.died.connect(func() -> void:
		open()
		set_deferred("monitoring", false))

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		boss.engage()
		close()

func close() -> void:
	for door in get_children() -> void:
		if door is BossDoor:
			door.close()

func open() -> void:
	for door in get_children() -> void:
		if door is BossDoor:
			door.open()

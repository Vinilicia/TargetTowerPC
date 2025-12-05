extends Area2D

@export var boss : Boss
@export var doors : Node2D

func _ready() -> void:
	open()
	boss.died.connect(func():
		open()
		set_deferred("monitoring", false))

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		boss.engage()
		close()

func close() -> void:
	for door in doors.get_children():
		if door is BossDoor:
			door.close()

func open() -> void:
	for door in doors.get_children():
		if door is BossDoor:
			door.open()

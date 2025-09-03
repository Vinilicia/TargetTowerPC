extends Timer

var max_time : int = 3600

var passed_time : int = 0

func _ready() -> void:
	start(max_time)

func _process(delta: float) -> void:
	passed_time = int(max_time - time_left)
	UiHandler.passed_minutes = int(passed_time / 60)
	UiHandler.passed_seconds = passed_time % 60

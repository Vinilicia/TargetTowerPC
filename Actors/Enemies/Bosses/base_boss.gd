extends Enemy
class_name Boss

var engaging : bool = false
var player : Player

func engage() -> void:
	engaging = true

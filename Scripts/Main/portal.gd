@tool
extends Area2D
class_name Portal

@export var spawn_position: Vector2

# 🔹 Mantém o enum exportado normalmente
@export var area: LevelDatabase.Areas = LevelDatabase.Areas.AREA_1:
	set(value):
		if area != value:
			area = value
			_update_target_level_list() # atualiza o dropdown e o valor atual


var target_level_name: String = ""

const DB_PATH := "res://Data/LevelDB.tres"


# 🔹 Atualiza a lista de levels e define o primeiro como ativo
func _update_target_level_list():
	var database: LevelDatabase = null

	if Engine.is_editor_hint():
		database = load(DB_PATH) as LevelDatabase
	else:
		if Engine.has_singleton("LevelDB"):
			database = LevelDB.database as LevelDatabase

	if database:
		var level_names: Array = database.get_level_names(area)
		if level_names.size() > 0:
			target_level_name = level_names[0]  # 🟢 define o primeiro da lista como padrão
	notify_property_list_changed()


# 🔹 Só recria o dropdown do nome
func _get_property_list() -> Array:
	var props: Array = []
	var database: LevelDatabase = null

	if Engine.is_editor_hint():
		database = load(DB_PATH) as LevelDatabase
	else:
		if Engine.has_singleton("LevelDB"):
			database = LevelDB.database as LevelDatabase

	if database:
		var level_names: Array = database.get_level_names(area)
		props.append({
			"name": "target_level_name",
			"type": TYPE_STRING,
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": ",".join(level_names)
		})
	else:
		props.append({
			"name": "target_level_name",
			"type": TYPE_STRING,
			"usage": PROPERTY_USAGE_DEFAULT
		})

	return props


func _set(property, value):
	if property == "target_level_name":
		target_level_name = value
		return true
	return false


func _get(property):
	if property == "target_level_name":
		return target_level_name
	return null

func _on_body_entered(_body: Node2D) -> void:
	var game: Game = get_tree().get_first_node_in_group("Game")
	game.change_level(target_level_name, spawn_position)

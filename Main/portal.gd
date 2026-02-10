@tool
extends Area2D
class_name Portal

@export var spawn_position: Vector2

@export_enum("Left", "Right", "Up", "Down") var direction : int

@export var area: LevelDatabase.Areas = LevelDatabase.Areas.AREA_1:
	set(value):
		if area != value:
			area = value
			_update_target_level_list()

var target_level_name: String = ""

const DB_PATH := "res://Data/LevelDB.tres"

func _update_target_level_list() -> void:
	var database := _get_database()
	if database == null:
		push_warning("⚠️ LevelDatabase não encontrado ao tentar atualizar dropdown.")
		return

	var level_names: Array = database.get_level_names(area)
	if level_names.size() > 0:
		target_level_name = level_names[0] # 🟢 define o primeiro da lista como padrão
	else:
		target_level_name = ""
	
	# Atualiza a lista de propriedades no editor
	notify_property_list_changed()


# ------------------------------------------------------------
# 🔹 Constrói o dropdown de nomes no editor
# ------------------------------------------------------------
func _get_property_list() -> Array:
	var props: Array = []
	var database := _get_database()

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


# ------------------------------------------------------------
# 🔹 Getters e setters de propriedades
# ------------------------------------------------------------
func _set(property: StringName, value) -> bool:
	if property == "target_level_name":
		target_level_name = value
		return true
	return false


func _get(property: StringName):
	if property == "target_level_name":
		return target_level_name
	return null


# ------------------------------------------------------------
# 🔹 Helper: obtém o banco de dados de forma segura
# ------------------------------------------------------------
func _get_database() -> LevelDatabase:
	if Engine.is_editor_hint():
		return load(DB_PATH) as LevelDatabase
	elif Engine.has_singleton("LevelDB"):
		return LevelDB.database as LevelDatabase
	return null


# ------------------------------------------------------------
# 🔹 Lógica de entrada do jogador no portal
# ------------------------------------------------------------
func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.lose_control()
		var velocity := Vector2.ZERO
		match direction:
			0:
				velocity = Vector2(-body.move_speed, 0)
			1:
				velocity = Vector2(body.move_speed, 0)
			2:
				velocity = Vector2(body.jump_force, 0)
			3:
				velocity = Vector2(body.max_fall_speed, 0)
		body.v_component.set_proper_velocity(velocity)
		get_tree().create_timer(0.5).timeout.connect(func():
			body.v_component.set_proper_velocity(Vector2.ZERO)
			)
	else:
		return
	var game: Game = get_tree().get_first_node_in_group("Game")
	if game == null:
		push_error("❌ Nó 'Game' não encontrado na cena!")
		return
	
	game.change_level(target_level_name, spawn_position)

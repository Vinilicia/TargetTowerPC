@tool
extends Resource
class_name LevelDatabase

enum Areas { AREA_1, AREA_2 }

# Caminho base onde ficam as áreas
const BASE_PATH := "res://Levels/Areas/"

# Retorna o nome da área (string) com base no enum
func get_area_name(area: Areas) -> String:
	match area:
		Areas.AREA_1:
			return "Area1"
		Areas.AREA_2:
			return "Area2"
		_:
			return ""


# 🔹 Lista os nomes dos levels dentro da área
func get_level_names(area: Areas) -> Array[String]:
	var dir := DirAccess.open(BASE_PATH + get_area_name(area))
	if dir == null:
		return []
	var result: Array[String] = []
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.begins_with("Room"):
			result.append(file_name.get_basename())
		file_name = dir.get_next()
	dir.list_dir_end()
	return result


# 🔹 Retorna o caminho completo do level
func get_level_path(area: Areas, level_name: String) -> String:
	return "%s%s/%s.tscn" % [BASE_PATH, get_area_name(area), level_name]


# 🔹 Lista todas as áreas por nome (para o dropdown)
func get_area_names() -> Array[String]:
	return ["Area1", "Area2"]

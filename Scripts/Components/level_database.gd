@tool
extends Resource
class_name LevelDatabase

# ---------------------------------------------------------
# Dicionários separados por área
# ---------------------------------------------------------
@export var area_1_levels: Dictionary[String, String] = {}
@export var area_2_levels: Dictionary[String, String] = {}
@export var area_3_levels: Dictionary[String, String] = {}

# Enum para as áreas — usado no portal
enum Areas {
	AREA_1,
	AREA_2,
	AREA_3
}

# ---------------------------------------------------------
# Métodos utilitários
# ---------------------------------------------------------

func get_area_names() -> Array[String]:
	return ["AREA_1", "AREA_2", "AREA_3"]

func get_levels_for_area(area: Areas) -> Dictionary[String, String]:
	match area:
		Areas.AREA_1:
			return area_1_levels
		Areas.AREA_2:
			return area_2_levels
		Areas.AREA_3:
			return area_3_levels
		_:
			return {}

func get_level_names(area: Areas) -> Array[String]:
	return get_levels_for_area(area).keys()

func get_level_path(area: Areas, level_name: String) -> String:
	var levels = get_levels_for_area(area)
	if levels.has(level_name):
		return levels[level_name]
	push_warning("Level '%s' não encontrado na área %s" % [level_name, str(area)])
	return ""

extends Resource
#class_name SaveDataResource

@export var SaveVersion : int = 1

@export var HealthUpgrades: Array[bool] = [false, false, false, false]
@export var ManaUpgrades: Array[bool] = [false, false, false, false]
@export var AvailableArrows: Array[bool] = [true, false, false, false, false, false, false, false, false]

@export var LastBenchID: int = 1
@export var AreaOfBench: int = 1
@export var MaxHealth: int = 5
@export var MaxMana: int = 5
@export var Money: int = 0

# -----------------------------------
# Métodos de acesso
# -----------------------------------

func get_health_upgrade(index: int) -> bool:
	if index >= 0 and index < HealthUpgrades.size():
		return HealthUpgrades[index]
	print("Erro: Índice de HealthUpgrades fora do alcance.")
	return false

func set_health_upgrade(index: int):
	if index >= 0 and index < HealthUpgrades.size():
		HealthUpgrades[index] = true
	else:
		print("Erro: Índice de HealthUpgrades fora do alcance.")

func get_mana_upgrade(index: int) -> bool:
	if index >= 0 and index < ManaUpgrades.size():
		return ManaUpgrades[index]
	print("Erro: Índice de ManaUpgrades fora do alcance.")
	return false

func set_mana_upgrade(index: int):
	if index >= 0 and index < ManaUpgrades.size():
		ManaUpgrades[index] = true
	else:
		print("Erro: Índice de ManaUpgrades fora do alcance.")

func get_available_arrow(index: int) -> bool:
	if index >= 0 and index < AvailableArrows.size():
		return AvailableArrows[index]
	print("Erro: Índice de AvailableArrows fora do alcance.")
	return false

func set_available_arrow(index: int):
	if index >= 0 and index < AvailableArrows.size():
		AvailableArrows[index] = true
	else:
		print("Erro: Índice de AvailableArrows fora do alcance.")

func get_available_arrows() -> Array[bool]:
	return AvailableArrows

func set_available_arrows(arrows: Array[bool]) -> void:
	for i in range(AvailableArrows.size()):
		if arrows[i]:
			set_available_arrow(i)

func set_array(prop_name, array) -> void:
	if prop_name == "HealthUpgrades":
		HealthUpgrades = create_bool_array(array)
	elif prop_name == "ManaUpgrades":
		ManaUpgrades = create_bool_array(array)
	elif prop_name == "AvailableArrows":
		AvailableArrows = create_bool_array(array)
	
func get_last_bench_id() -> int:
	return LastBenchID

func set_last_bench_id(value: int):
	LastBenchID = value

func get_area_of_bench() -> int:
	return AreaOfBench

func set_area_of_bench(value: int):
	AreaOfBench = value
	
func get_max_health() -> int:
	return MaxHealth

func set_max_health(value: int):
	MaxHealth = value

func get_max_mana() -> int:
	return MaxMana

func set_max_mana(value: int):
	MaxMana = value

func get_money() -> int:
	return Money

func set_money(value: int):
	Money = value


func create_bool_array(array : Array) -> Array[bool]:
	var new_array : Array[bool] = []
	for value in array:
		new_array.append(value)
	return new_array

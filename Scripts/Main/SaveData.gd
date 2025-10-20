extends Resource
class_name SaveDataResource

@export var progress_bar_value: float = 0.0

@export var HealthUpgrades: Array[bool] = [false, false, false, false]
@export var ManaUpgrades: Array[bool] = [false, false, false, false]
@export var AvailableArrows: Array[bool] = [false, false, false, false]
@export var LastBenchID: int = 0
@export var MaxHealth: int = 100
@export var MaxMana: int = 100

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

func get_last_bench_id() -> int:
	return LastBenchID

func set_last_bench_id(value: int):
	LastBenchID = value

func get_max_health() -> int:
	return MaxHealth

func set_max_health(value: int):
	MaxHealth = value

func get_max_mana() -> int:
	return MaxMana

func set_max_mana(value: int):
	MaxMana = value

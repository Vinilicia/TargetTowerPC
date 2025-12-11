extends Resource
class_name SaveDataResource

@export var SaveVersion : int = 1

# --- DADOS DO JOGO ---
@export var HealthUpgrades: Array[bool] = [false, false, false, false]
@export var ManaUpgrades: Array[bool] = [false, false, false, false]
@export var AvailableArrows: Array[bool] = [true, false, false, false, false, false, false, false, false]

@export var LastBenchID: int = 1
@export var AreaOfBench: int = 1
@export var MaxHealth: int = 4
@export var MaxMana: int = 5
@export var Money: int = 0
@export var MoneyUpgrades: int = 0

# -----------------------------------
# Métodos de acesso / utilitários
# -----------------------------------

func get_health_upgrade(index: int) -> bool:
	if index >= 0 and index < HealthUpgrades.size():
		return HealthUpgrades[index]
	push_error("Erro: Índice de HealthUpgrades fora do alcance (%d)." % index)
	return false

func set_health_upgrade(index: int) -> void:
	if index >= 0 and index < HealthUpgrades.size():
		HealthUpgrades[index] = true
	else:
		push_error("Erro: Índice de HealthUpgrades fora do alcance (%d)." % index)

func get_mana_upgrade(index: int) -> bool:
	if index >= 0 and index < ManaUpgrades.size():
		return ManaUpgrades[index]
	push_error("Erro: Índice de ManaUpgrades fora do alcance (%d)." % index)
	return false

func set_mana_upgrade(index: int) -> void:
	if index >= 0 and index < ManaUpgrades.size():
		ManaUpgrades[index] = true
	else:
		push_error("Erro: Índice de ManaUpgrades fora do alcance (%d)." % index)

func get_available_arrow(index: int) -> bool:
	if index >= 0 and index < AvailableArrows.size():
		return AvailableArrows[index]
	push_error("Erro: Índice de AvailableArrows fora do alcance (%d)." % index)
	return false

func set_available_arrow(index: int) -> void:
	if index >= 0 and index < AvailableArrows.size():
		AvailableArrows[index] = true
	else:
		push_error("Erro: Índice de AvailableArrows fora do alcance (%d)." % index)

func get_available_arrows() -> Array[bool]:
	return AvailableArrows.duplicate(true)

func set_available_arrows(arrows: Array) -> void:
	# copia valores (respeita tamanho atual)
	for i in range(min(arrows.size(), AvailableArrows.size())):
		AvailableArrows[i] = bool(arrows[i])
	# se arrows for menor, mantém os restantes; se for maior, ignora extras

func set_array(prop_name: String, array: Array) -> void:
	# usado pelo SaveLoadManager durante migração/assign
	if prop_name == "HealthUpgrades":
		HealthUpgrades = create_bool_array(array)
	elif prop_name == "ManaUpgrades":
		ManaUpgrades = create_bool_array(array)
	elif prop_name == "AvailableArrows":
		AvailableArrows = create_bool_array(array)

func get_last_bench_id() -> int:
	return LastBenchID

func set_last_bench_id(value: int) -> void:
	LastBenchID = int(value)

func get_area_of_bench() -> int:
	return AreaOfBench

func set_area_of_bench(value: int) -> void:
	AreaOfBench = int(value)
	
func get_max_health() -> int:
	return MaxHealth

func set_max_health(value: int) -> void:
	MaxHealth = int(value)

func get_max_mana() -> int:
	return MaxMana

func set_max_mana(value: int) -> void:
	MaxMana = int(value)

func get_money() -> int:
	return Money

func set_money(value: int) -> void:
	Money = int(value)

func create_bool_array(array : Array) -> Array[bool]:
	var new_array : Array[bool] = []
	for value in array:
		new_array.append(bool(value))
	return new_array

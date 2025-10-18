extends Node

var SaveFileData: SaveDataResource = SaveDataResource.new()
var current_slot_index: int = 0

func _ready() -> void:
	test()

func get_save_path(slot_index: int) -> String:
	return "user://SaveFile_%d.json" % slot_index

func _save(slot_index: int):
	var save_path = get_save_path(slot_index)
	var file = FileAccess.open_encrypted_with_pass(save_path, FileAccess.WRITE, "1n1c19a436")
	
	var data_to_save = {
		"progress_bar_value": SaveFileData.progress_bar_value,
		"HealthUpgrades": SaveFileData.HealthUpgrades,
		"ManaUpgrades": SaveFileData.ManaUpgrades,
		"AvailableArrows": SaveFileData.AvailableArrows,
		"LastBenchID": SaveFileData.LastBenchID,
		"MaxHealth": SaveFileData.MaxHealth,
		"MaxMana": SaveFileData.MaxMana,
		"Money": SaveFileData.Money,
		"profile_name": SaveFileData.profile_name
	}
	
	var json_ver = JSON.stringify(data_to_save)
	file.store_string(json_ver)
	file.close()
	print("Jogo salvo no Slot ", slot_index)

func _load(slot_index: int):
	var save_path = get_save_path(slot_index)
	
	if FileAccess.file_exists(save_path):
		current_slot_index = slot_index
		
		var file = FileAccess.open_encrypted_with_pass(save_path, FileAccess.READ, "1n1c19a436")
		var data = JSON.parse_string(file.get_as_text())
		file.close()
		
		SaveFileData = SaveDataResource.new()
		SaveFileData.progress_bar_value = data.get("progress_bar_value", 0.0)
		
		var loaded_health = data.get("HealthUpgrades", [])
		SaveFileData.HealthUpgrades.assign(loaded_health)
		
		var loaded_mana = data.get("ManaUpgrades", [])
		SaveFileData.ManaUpgrades.assign(loaded_mana)
		
		var loaded_arrows = data.get("AvailableArrows", [])
		SaveFileData.AvailableArrows.assign(loaded_arrows)
		
		SaveFileData.LastBenchID = data.get("LastBenchID", 0)
		SaveFileData.MaxHealth = data.get("MaxHealth", 100)
		SaveFileData.MaxMana = data.get("MaxMana", 100)
		SaveFileData.Money = data.get("Money", 0)
		SaveFileData.profile_name = data.get("profile_name", "Profile %d" % (slot_index + 1))
		
		print("Jogo carregado do Slot ", slot_index)
		return true
	else:
		print("Nenhum save encontrado no Slot ", slot_index)
		return false
		
func copy_slot(source_slot: int, destination_slot: int):
	var source_path = get_save_path(source_slot)
	var dest_path = get_save_path(destination_slot)

	if not FileAccess.file_exists(source_path):
		print("Erro ao copiar: Slot de origem %d está vazio." % source_slot)
		return

	var dir = DirAccess.open("user://")
	var error = dir.copy(source_path, dest_path)
	if error == OK:
		print("Slot %d copiado com sucesso para o Slot %d." % [source_slot, destination_slot])
	else:
		print("Ocorreu um erro ao copiar o arquivo. Código do erro: %d" % error)

func delete_slot(slot_to_delete: int):
	var save_path = get_save_path(slot_to_delete)

	if not FileAccess.file_exists(save_path):
		print("Não há nada para deletar no Slot %d." % slot_to_delete)
		return
	
	var dir = DirAccess.open("user://")
	var error = dir.remove(save_path)
	if error == OK:
		print("Slot %d deletado com sucesso." % slot_to_delete)
	else:
		print("Ocorreu um erro ao deletar o arquivo. Código do erro: %d" % error)

func is_slot_used(slot_index: int) -> bool:
	var save_path = get_save_path(slot_index)
	return FileAccess.file_exists(save_path)
	
func test():
	SaveFileData.set_max_health(0)
	SaveFileData.set_money(500)
	SaveFileData.set_profile_name("Profile Teste")
	_save(0)
	SaveFileData.set_max_health(1)
	_save(1)
	SaveFileData.set_max_health(99)
	_load(0)
	print(SaveFileData.get_max_health(), SaveFileData.get_money(), SaveFileData.get_profile_name())
	copy_slot(1,0)
	_load(0)
	print(SaveFileData.get_max_health())
	delete_slot(0)
	print(SaveFileData.get_max_health())

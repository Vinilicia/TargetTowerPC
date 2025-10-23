extends Node
class_name SaveLoadManager

var save_file_data: SaveDataResource = SaveDataResource.new()
var current_slot_index: int = 0

func _ready() -> void:
	test()

func get_save_path(slot_index: int) -> String:
	return "user://SaveFile_%d.json" % slot_index

func _save(slot_index: int):
	var save_path = get_save_path(slot_index)
	var file = FileAccess.open_encrypted_with_pass(save_path, FileAccess.WRITE, "1n1c19a436")
	
	var data_to_save = {
		"progress_bar_value": save_file_data.progress_bar_value,
		"HealthUpgrades": save_file_data.HealthUpgrades,
		"ManaUpgrades": save_file_data.ManaUpgrades,
		"AvailableArrows": save_file_data.AvailableArrows,
		"LastBenchID": save_file_data.LastBenchID,
		"MaxHealth": save_file_data.MaxHealth,
		"MaxMana": save_file_data.MaxMana,
		"Money": save_file_data.Money,
		"profile_name": save_file_data.profile_name
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
		
		save_file_data = SaveDataResource.new()
		save_file_data.progress_bar_value = data.get("progress_bar_value", 0.0)
		
		var loaded_health = data.get("HealthUpgrades", [])
		save_file_data.HealthUpgrades.assign(loaded_health)
		
		var loaded_mana = data.get("ManaUpgrades", [])
		save_file_data.ManaUpgrades.assign(loaded_mana)
		
		var loaded_arrows = data.get("AvailableArrows", [])
		save_file_data.AvailableArrows.assign(loaded_arrows)
		
		save_file_data.LastBenchID = data.get("LastBenchID", 0)
		save_file_data.MaxHealth = data.get("MaxHealth", 100)
		save_file_data.MaxMana = data.get("MaxMana", 100)
		save_file_data.Money = data.get("Money", 0)
		save_file_data.profile_name = data.get("profile_name", "Profile %d" % (slot_index + 1))
		
		print("Jogo carregado do Slot ", slot_index)
		return true
	else:
		print("Nenhum save encontrado no Slot ", slot_index, " — criando novo save padrão...")
		
		save_file_data = SaveDataResource.new()
		
		_save(slot_index)
		
		print("Novo save criado e salvo no Slot ", slot_index)
		return true

		
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
	save_file_data.set_max_health(0)
	save_file_data.set_money(500)
	save_file_data.set_profile_name("Profile Teste")
	_save(0)
	save_file_data.set_max_health(1)
	_save(1)
	save_file_data.set_max_health(99)
	_load(0)
	print(save_file_data.get_max_health(), save_file_data.get_money(), save_file_data.get_profile_name())
	copy_slot(1,0)
	_load(0)
	print(save_file_data.get_max_health())
	delete_slot(0)
	print(save_file_data.get_max_health())

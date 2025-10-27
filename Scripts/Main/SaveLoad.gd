extends Node
class_name SaveLoadManager

var save_file_data: SaveDataResource = SaveDataResource.new()
var current_slot_index: int = 0

func get_save_path(slot_index: int) -> String:
	return "user://SaveFile_%d.json" % slot_index

func _save(slot_index: int):
	var save_path = get_save_path(slot_index)
	var file = FileAccess.open_encrypted_with_pass(save_path, FileAccess.WRITE, "1n1c19a436")

	var data_to_save: Dictionary = {}
	for prop_info in save_file_data.get_property_list():
		var prop_name = prop_info.name
		if prop_name.begins_with("_") or prop_name in ["resource_name", "resource_path"]:
			continue
		data_to_save[prop_name] = save_file_data.get(prop_name)

	var json_ver = JSON.stringify(data_to_save)
	file.store_string(json_ver)
	file.close()
	print("Jogo salvo no Slot ", slot_index)


func _load(slot_index: int):
	var save_path = get_save_path(slot_index)

	# Se não existe, cria novo
	if not FileAccess.file_exists(save_path):
		print("Nenhum save encontrado no Slot ", slot_index, " — criando novo save padrão...")
		save_file_data = SaveDataResource.new()
		_save(slot_index)
		return true

	current_slot_index = slot_index
	var file = FileAccess.open_encrypted_with_pass(save_path, FileAccess.READ, "1n1c19a436")
	var data = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(data) != TYPE_DICTIONARY:
		print("Erro: Arquivo de save inválido — recriando padrão.")
		save_file_data = SaveDataResource.new()
		_save(slot_index)
		return true

	# Cria recursos
	var default_data = SaveDataResource.new()
	var loaded_resource = SaveDataResource.new()
	var valid = true

	# Pega versões
	var saved_version = data.get("SaveVersion", 0)
	var current_version = default_data.SaveVersion

	# --- 🔹 CASO 1: SAVE FUTURO ---
	if saved_version > current_version:
		print("Save mais novo que a versão atual (%d > %d) — recriando do zero." % [saved_version, current_version])
		save_file_data = SaveDataResource.new()
		_save(slot_index)
		return true

	# --- 🔹 CASO 2: SAVE ANTIGO (migração) ---
	elif saved_version < current_version:
		print("Save mais antigo (%d < %d) — migrando dados..." % [saved_version, current_version])
		for prop_info in default_data.get_property_list():
			var prop_name = prop_info.name
			if prop_name.begins_with("_") or prop_name in ["resource_name", "resource_path"]:
				continue

			var default_value = default_data.get(prop_name)

			# Se o campo não existe no save antigo, mantém o valor padrão
			if not data.has(prop_name):
				loaded_resource.set(prop_name, default_value)
				continue

			var value = data[prop_name]

			# Se tipo diferente, mantém padrão
			if typeof(value) != typeof(default_value):
				loaded_resource.set(prop_name, default_value)
				continue

			if typeof(default_value) == TYPE_ARRAY:
				if typeof(value) != TYPE_ARRAY:
					valid = false
					break
				if default_value.size() > 0:
					var element_type = typeof(default_value[0])
					var new_array: Array = []
					for v in value:
						if element_type == TYPE_BOOL:
							new_array.append(bool(v))
						else:
							new_array.append(v)
					value = new_array

				if value.size() < default_value.size():
					for i in range(value.size(), default_value.size()):
						value.append(default_value[i])
				elif value.size() > default_value.size():
					value.resize(default_value.size())
			else:
				# Tipos simples — copia direto
				loaded_resource.set(prop_name, value)

		# Atualiza a versão do save e sobrescreve
		loaded_resource.SaveVersion = current_version
		save_file_data = loaded_resource
		_save(slot_index)
		print("Migração concluída. Save atualizado para versão ", current_version)
		return true

	# --- 🔹 CASO 3: MESMA VERSÃO (verificação padrão) ---
	else:
		for prop_info in default_data.get_property_list():
			var prop_name = prop_info.name
			if prop_name.begins_with("_") or prop_name in ["resource_name", "resource_path", "script"]:
				continue

			if not data.has(prop_name):
				print("Campo faltando:", prop_name)
				valid = false
				break
			
			var value = data[prop_name]
			var default_value = default_data.get(prop_name)

			if typeof(value) != typeof(default_value):
				# Permite int <-> float, já que o JSON mistura os dois
				if (typeof(value) in [TYPE_INT, TYPE_FLOAT]) and (typeof(default_value) in [TYPE_INT, TYPE_FLOAT]):
					pass
				else:
					print("Tipo incorreto em %s — recriando save." % prop_name)
					valid = false
					break

			if typeof(default_value) == TYPE_ARRAY:
				if typeof(value) != TYPE_ARRAY:
					valid = false
					break
				if default_value.size() > 0:
					var element_type = typeof(default_value[0])
					var new_array: Array = []
					for v in value:
						if element_type == TYPE_BOOL:
							new_array.append(bool(v))
						else:
							new_array.append(v)
					value = new_array
				if value.size() < default_value.size():
					for i in range(value.size(), default_value.size()):
						value.append(default_value[i])
				elif value.size() > default_value.size():
					value.resize(default_value.size())
					
				if(prop_name == "AvailableArrows" and typeof(value) == typeof(loaded_resource.AvailableArrows)):
					var array : Array[bool] = []
					for v in value:
						array.append(v)
					loaded_resource.set_available_arrows(array)
					print(loaded_resource.get(prop_name))
					print(loaded_resource.AvailableArrows)
					print("value " + str(value))
			loaded_resource.set(prop_name, value)

		if not valid:
			print("Save inválido — recriando arquivo padrão.")
			save_file_data = SaveDataResource.new()
			_save(slot_index)
			return true

		save_file_data = loaded_resource
		print("Jogo carregado com sucesso do Slot ", slot_index)
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
	print(save_file_data.get_available_arrows())

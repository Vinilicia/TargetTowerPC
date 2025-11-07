extends Node
class_name SaveLoadManager

var save_file_data: SaveDataResource = SaveDataResource.new()
var current_slot_index: int = 0

# ---------------------------------
# Caminhos
# ---------------------------------
func get_save_path(slot_index: int) -> String:
	return "user://SaveFile_%d.json" % slot_index

func get_controls_path(slot_index: int) -> String:
	return "user://Controls_%d.map" % slot_index


# ===============================================================
# === FUNÇÕES DE SUPORTE PARA SALVAR/CARREGAR CONTROLES (.map) ===
# ===============================================================

func save_controls(path: String) -> void:
	var controls_data: Dictionary = {}

	# Só salva ações personalizáveis (não as de UI internas)
	for action_name in InputMap.get_actions():
		if action_name.begins_with("ui_"):
			continue

		var events = []
		for e in InputMap.action_get_events(action_name):
			if e is InputEventKey:
				events.append({
					"type": "key",
					"keycode": e.keycode,
					"physical_keycode": e.physical_keycode,
					"pressed": e.pressed
				})
			elif e is InputEventMouseButton:
				events.append({
					"type": "mouse_button",
					"button_index": e.button_index
				})
			elif e is InputEventJoypadButton:
				events.append({
					"type": "joy_button",
					"button_index": e.button_index
				})
		controls_data[action_name] = events

	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(controls_data, "\t"))
	file.close()


func load_controls(path: String) -> void:
	if not FileAccess.file_exists(path):
		print("⚠ Nenhum arquivo de controle encontrado, mantendo padrão.")
		return

	var file = FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(data) != TYPE_DICTIONARY:
		print("⚠ Erro: arquivo de controle corrompido.")
		return

	# 🔸 Apenas limpa as ações salvas (nunca as 'ui_*')
	for action_name in data.keys():
		if InputMap.has_action(action_name):
			InputMap.action_erase_events(action_name)

	# 🔸 Restaura bindings
	for action_name in data.keys():
		if not InputMap.has_action(action_name):
			print("⚠ Ação '%s' não existe no projeto, ignorando." % action_name)
			continue

		for e_data in data[action_name]:
			var ev: InputEvent = null

			match e_data["type"]:
				"key":
					ev = InputEventKey.new()
					ev.keycode = e_data.get("keycode", 0)
					ev.physical_keycode = e_data.get("physical_keycode", ev.keycode)
					ev.pressed = true
				"mouse_button":
					ev = InputEventMouseButton.new()
					ev.button_index = e_data.get("button_index", 0)
				"joy_button":
					ev = InputEventJoypadButton.new()
					ev.button_index = e_data.get("button_index", 0)

			if ev:
				InputMap.action_add_event(action_name, ev)


func reset_default_controls():
	InputMap.load_from_project_settings()


# ===============================================================
# === SALVAMENTO E CARREGAMENTO DE JOGO ===
# ===============================================================

func _save(slot_index: int):
	var save_path = get_save_path(slot_index)
	var file = FileAccess.open_encrypted_with_pass(save_path, FileAccess.WRITE, "1n1c19a436")

	var data_to_save: Dictionary = {}
	for prop_info in save_file_data.get_property_list():
		var prop_name = prop_info.name
		if prop_name.begins_with("_") or prop_name in ["resource_name", "resource_path", "script"]:
			continue
		data_to_save[prop_name] = save_file_data.get(prop_name)

	var json_ver = JSON.stringify(data_to_save)
	file.store_string(json_ver)
	file.close()

	# salva controles
	save_controls(get_controls_path(slot_index))
	print("Jogo e controles salvos no Slot ", slot_index)


func _load(slot_index: int):
	var save_path = get_save_path(slot_index)

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

	var default_data = SaveDataResource.new()
	var loaded_resource = SaveDataResource.new()
	var valid = true
	var is_array = false
	var saved_version = data.get("SaveVersion", 0)
	var current_version = default_data.SaveVersion

	# SAVE MAIS NOVO
	if saved_version > current_version:
		print("Save mais novo (%d > %d) — recriando do zero." % [saved_version, current_version])
		save_file_data = SaveDataResource.new()
		_save(slot_index)
		return true

	# SAVE ANTIGO (migração)
	elif saved_version < current_version:
		print("Save antigo (%d < %d) — migrando..." % [saved_version, current_version])
		for prop_info in default_data.get_property_list():
			var prop_name = prop_info.name
			if prop_name.begins_with("_") or prop_name in ["resource_name", "resource_path", "script"]:
				continue

			var default_value = default_data.get(prop_name)
			if not data.has(prop_name):
				loaded_resource.set(prop_name, default_value)
				continue

			var value = data[prop_name]
			if typeof(value) != typeof(default_value):
				if (typeof(value) in [TYPE_INT, TYPE_FLOAT]) and (typeof(default_value) in [TYPE_INT, TYPE_FLOAT]):
					pass
				else:
					loaded_resource.set(prop_name, default_value)
					continue

			if typeof(default_value) == TYPE_ARRAY:
				var new_array: Array = []
				for v in value:
					new_array.append(v)
				loaded_resource.set_array(prop_name, new_array)
			else:
				loaded_resource.set(prop_name, value)

		loaded_resource.SaveVersion = current_version
		save_file_data = loaded_resource
		_save(slot_index)
		print("Migração concluída para versão ", current_version)
		return true

	# MESMA VERSÃO
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
				if (typeof(value) in [TYPE_INT, TYPE_FLOAT]) and (typeof(default_value) in [TYPE_INT, TYPE_FLOAT]):
					pass
				else:
					valid = false
					break

			if typeof(default_value) == TYPE_ARRAY:
				var new_array: Array = []
				for v in value:
					new_array.append(v)
				loaded_resource.set_array(prop_name, new_array)
			else:
				loaded_resource.set(prop_name, value)

		if not valid:
			print("Save inválido — recriando.")
			save_file_data = SaveDataResource.new()
			_save(slot_index)
			return true

		save_file_data = loaded_resource
		print("Jogo carregado com sucesso do Slot ", slot_index)

	# carregar controles
	var controls_path = get_controls_path(slot_index)
	if FileAccess.file_exists(controls_path):
		load_controls(controls_path)
	else:
		reset_default_controls()

	apply_settings()
	return true


# ===============================================================
# === APLICAÇÃO DE CONFIGURAÇÕES ===
# ===============================================================
func apply_settings():
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(save_file_data.master_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(save_file_data.music_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(save_file_data.sfx_volume))

	var mode = DisplayServer.WINDOW_MODE_FULLSCREEN
	match save_file_data.display_mode:
		0, 2: mode = DisplayServer.WINDOW_MODE_WINDOWED
		4: mode = DisplayServer.WINDOW_MODE_FULLSCREEN
	DisplayServer.window_set_mode(mode)


# ===============================================================
# === GERENCIAMENTO DE SLOTS ===
# ===============================================================
func copy_slot(source_slot: int, destination_slot: int):
	var source_path = get_save_path(source_slot)
	var dest_path = get_save_path(destination_slot)

	if not FileAccess.file_exists(source_path):
		print("Erro ao copiar: Slot origem %d vazio." % source_slot)
		return

	var dir = DirAccess.open("user://")
	var error = dir.copy(source_path, dest_path)
	if error == OK:
		print("Slot %d copiado para Slot %d." % [source_slot, destination_slot])
	else:
		print("Erro ao copiar arquivo. Código %d" % error)

	var src_controls = get_controls_path(source_slot)
	var dst_controls = get_controls_path(destination_slot)
	if FileAccess.file_exists(src_controls):
		dir.copy(src_controls, dst_controls)

func delete_slot(slot_to_delete: int):
	var save_path = get_save_path(slot_to_delete)
	var dir = DirAccess.open("user://")

	if FileAccess.file_exists(save_path):
		dir.remove(save_path)
	if FileAccess.file_exists(get_controls_path(slot_to_delete)):
		dir.remove(get_controls_path(slot_to_delete))
	print("Slot %d (save e controles) deletado." % slot_to_delete)

func is_slot_used(slot_index: int) -> bool:
	return FileAccess.file_exists(get_save_path(slot_index))

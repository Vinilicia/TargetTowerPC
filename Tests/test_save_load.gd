extends Node
class_name TestSaveLoadManager

const TEST_SLOT := 7
const TEST_SLOT_COPY := 8
const TEST_SETTINGS_PATH := "user://settings.json"
const TEST_CONTROL_PATH := "user://Controls_%d.map" % TEST_SLOT

var save_manager: SaveLoadManager

# --- SISTEMA DE ASSERTS (Mantido) ---
func assert_true(cond: bool, msg: String = "") -> void:
	if not cond:
		printerr("FALHA: ", msg)
		print("________________________________")
	assert(cond, "assert_true failed: " + msg)

func assert_false(cond: bool, msg: String = "") -> void:
	if cond:
		printerr("FALHA: ", msg)
		print("________________________________")
	assert(not cond, "assert_false failed: " + msg)

func assert_eq(a, b, msg: String = "") -> void:
	var ok : bool = (str(a) == str(b)) # Convertendo para string para comparar deep structures se necessario
	if not ok:
		printerr("FALHA: %s != %s. %s" % [str(a), str(b), msg])
		print("________________________________")
	assert(ok, "assert_eq failed: %s != %s. %s" % [str(a), str(b), msg])

# --- CICLO DE VIDA DO TESTE ---
func _ready():
	print("\n█▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█")
	print("█      INICIANDO BATERIA DE TESTES        █")
	print("█▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█\n")

	# Testes Originais (Happy Path)
	_run(test_create_new_save_if_missing)
	_run(test_save_and_load_roundtrip)
	_run(test_save_migration)
	_run(test_settings_save_and_load)
	_run(test_settings_migration)
	_run(test_controls_save_and_load)
	_run(test_copy_slot)
	_run(test_delete_slot)
	
	print("\n--- INICIANDO TESTES DE ESTRESSE E FALHA ---\n")
	
	# Testes Novos (Unhappy Path / Edge Cases)
	_run(test_corrupted_save_file)      # Testa arquivo lixo
	_run(test_controls_complex_inputs)  # Testa Joystick/Mouse
	_run(test_migration_bad_types)      # Testa JSON com tipos errados (String no lugar de Int)

	print("\n█▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█")
	print("█      TODOS OS TESTES FINALIZADOS        █")
	print("█▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█")

func _run(test_func: Callable):
	print("► Executando: ", test_func.get_method())
	before_each()
	test_func.call()
	
	# O Amostrador roda após cada teste para garantir que o sistema ficou estável
	verify_system_integrity(test_func.get_method())
	
	after_each()
	print("✔ PASSOU: ", test_func.get_method(), "\n")

func before_each():
	save_manager = SaveLoadManager.new()
	# Limpeza brutal para garantir isolamento
	var dir = DirAccess.open("user://")
	if dir:
		var files = dir.get_files()
		for f in files:
			if f.begins_with("SaveFile_") or f.begins_with("Controls_") or f == "settings.json":
				dir.remove("user://" + f)

func after_each():
	# Pode ser usado para liberar memória explícita se necessário
	if save_manager:
		save_manager.free()

# --- AMOSTRADOR DE SOBREVIVÊNCIA ---
func verify_system_integrity(context: String):
	# Este é o seu "Monitor Cardíaco". Se o teste quebrou o objeto, isso aqui falha.
	if save_manager == null:
		printerr("CRÍTICO: O SaveManager foi destruído ou é nulo após " + context)
		assert(false, "System Crash: SaveManager is null")
		
	if save_manager.save_file_data == null:
		printerr("CRÍTICO: Dados de Save (Resource) são nulos após " + context)
		assert(false, "System Crash: save_file_data is null")
		
	# Verifica se valores vitais ainda são coerentes (ex: vida não é negativa ou nula onde não deve)
	# Assumindo que MaxHealth nunca deve ser null.
	if typeof(save_manager.save_file_data.MaxHealth) == TYPE_NIL:
		printerr("CRÍTICO: Corrupção de Memória. MaxHealth é NIL após " + context)
		assert(false, "Data Corruption detected")

# ==========================================
# TESTES ORIGINAIS (Mantidos para Regressão)
# ==========================================

func test_create_new_save_if_missing():
	assert_false(FileAccess.file_exists(save_manager.get_save_path(TEST_SLOT)), "Arquivo não deveria existir")
	var result = save_manager._load(TEST_SLOT)
	assert_true(result, "Load deve retornar true ao criar novo")
	assert_true(FileAccess.file_exists(save_manager.get_save_path(TEST_SLOT)), "Arquivo deve ter sido criado")
	assert_eq(save_manager.save_file_data.MaxHealth, 4)

func test_save_and_load_roundtrip():
	save_manager._load(TEST_SLOT)
	save_manager.save_file_data.set_money(123)
	save_manager.save_file_data.set_max_health(9)
	save_manager._save(TEST_SLOT)

	var new_manager := SaveLoadManager.new()
	new_manager._load(TEST_SLOT)
	assert_eq(new_manager.save_file_data.Money, 123)
	assert_eq(new_manager.save_file_data.MaxHealth, 9)
	new_manager.free()

func test_save_migration():
	# Simula versão antiga v0
	var path = save_manager.get_save_path(TEST_SLOT)
	var file = FileAccess.open_encrypted_with_pass(path, FileAccess.WRITE, "1n1c19a436")
	file.store_string(JSON.stringify({
		"SaveVersion": 0,
		"LastBenchID": 9,
		"Money": 777,
		"MaxHealth": 2 # Valor antigo
	}))
	file.close()

	var result = save_manager._load(TEST_SLOT)
	assert_true(result, "Migração deve ocorrer com sucesso")
	assert_eq(save_manager.save_file_data.LastBenchID, 9)
	assert_eq(save_manager.save_file_data.Money, 777)
	# Verifica se atualizou a versão
	assert_true(save_manager.save_file_data.SaveVersion > 0, "Versão do save deve ter subido")

func test_settings_save_and_load():
	save_manager.settings_data["master_volume"] = 0.33
	save_manager.save_settings()
	var new := SaveLoadManager.new()
	new.load_settings()
	assert_eq(new.settings_data["master_volume"], 0.33)
	new.free()

func test_settings_migration():
	var file = FileAccess.open(TEST_SETTINGS_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({
		"SettingsVersion": 0,
		"master_volume": 0.1,
		"locale": "es"
	}))
	file.close()
	save_manager.load_settings()
	assert_eq(save_manager.settings_data["master_volume"], 0.1)
	assert_eq(save_manager.settings_data["locale"], "es")

func test_controls_save_and_load():
	InputMap.add_action("attack")
	var ev := InputEventKey.new()
	ev.keycode = KEY_K
	InputMap.action_add_event("attack", ev)
	save_manager.save_controls_for_slot(TEST_SLOT)
	
	InputMap.erase_action("attack")
	InputMap.add_action("attack")
	save_manager.load_controls_for_slot(TEST_SLOT)
	
	var events = InputMap.action_get_events("attack")
	assert_eq(events.size(), 1)
	if events.size() > 0:
		assert_eq(events[0].keycode, KEY_K)

func test_copy_slot():
	save_manager._load(TEST_SLOT)
	save_manager.save_file_data.set_money(500)
	save_manager._save(TEST_SLOT)
	save_manager.copy_slot(TEST_SLOT, TEST_SLOT_COPY)
	
	var m2 := SaveLoadManager.new()
	m2._load(TEST_SLOT_COPY)
	assert_eq(m2.save_file_data.Money, 500)
	m2.free()

func test_delete_slot():
	save_manager._load(TEST_SLOT)
	save_manager._save(TEST_SLOT)
	assert_true(FileAccess.file_exists(save_manager.get_save_path(TEST_SLOT)))
	save_manager.delete_slot(TEST_SLOT)
	assert_false(FileAccess.file_exists(save_manager.get_save_path(TEST_SLOT)))

# ==========================================
# NOVOS TESTES DE ESTRESSE E ROBUSTEZ
# ==========================================

func test_corrupted_save_file():
	# 1. Cria um arquivo totalmente corrompido (Lixo binário ou texto aleatório)
	var path = save_manager.get_save_path(TEST_SLOT)
	var file = FileAccess.open(path, FileAccess.WRITE) # Sem criptografia para estragar propositalmente
	file.store_string("ARQUIVO_CORROMPIDO_@#$!@#%!@#_SEM_JSON_VALIDO")
	file.close()
	
	# 2. Tenta carregar. 
	# EXPECTATIVA: O jogo NÃO deve crashar. Deve retornar false ou criar um novo save.
	# Ajuste conforme a lógica do seu jogo. Geralmente retorna false.
	print("   [Log] Tentando carregar arquivo corrompido...")
	var result = save_manager._load(TEST_SLOT)
	
	# Se seu sistema cria um novo save ao falhar, mude para assert_true.
	# Se seu sistema retorna erro, use assert_false. Vou assumir assert_false (erro seguro).
	assert_false(result, "Load deve falhar graciosamente com arquivo corrompido")
	
	# Amostrador: O objeto data ainda existe?
	assert_true(save_manager.save_file_data != null, "Resource de dados não deve ser destruído no erro")

func test_controls_complex_inputs():
	# Testa Joystick e Mouse (que costumam dar erro de serialização JSON)
	var action_name = "complex_jump"
	if InputMap.has_action(action_name): InputMap.erase_action(action_name)
	InputMap.add_action(action_name)
	
	# Adiciona botão de Controle (Xbox A / PS X)
	var joy_ev := InputEventJoypadButton.new()
	joy_ev.button_index = JOY_BUTTON_A
	InputMap.action_add_event(action_name, joy_ev)
	
	# Adiciona clique do Mouse
	var mouse_ev := InputEventMouseButton.new()
	mouse_ev.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event(action_name, mouse_ev)
	
	# Salva
	save_manager.save_controls_for_slot(TEST_SLOT)
	
	# Limpa
	InputMap.erase_action(action_name)
	InputMap.add_action(action_name)
	
	# Carrega
	save_manager.load_controls_for_slot(TEST_SLOT)
	
	var events = InputMap.action_get_events(action_name)
	assert_eq(events.size(), 2, "Deve recuperar 2 eventos (Joy + Mouse)")
	
	var recovered_joy = false
	var recovered_mouse = false
	
	for e in events:
		if e is InputEventJoypadButton: recovered_joy = true
		if e is InputEventMouseButton: recovered_mouse = true
	
	assert_true(recovered_joy, "Deve recuperar evento de Joystick")
	assert_true(recovered_mouse, "Deve recuperar evento de Mouse")

func test_migration_bad_types():
	# Simula um save antigo onde 'Money' foi salvo como String errada, 
	# para ver se o jogo crasha ao tentar somar Int com String.
	var path = save_manager.get_save_path(TEST_SLOT)
	var file = FileAccess.open_encrypted_with_pass(path, FileAccess.WRITE, "1n1c19a436")
	file.store_string(JSON.stringify({
		"SaveVersion": 0,
		"Money": "MUITO DINHEIRO", # Tipo errado! O jogo espera int.
		"MaxHealth": 5
	}))
	file.close()
	
	print("   [Log] Carregando save com Tipagem Incorreta...")
	var result = save_manager._load(TEST_SLOT)
	
	# O teste passa se o jogo NÃO crashar e conseguir carregar o resto
	assert_true(result, "Deve conseguir carregar mesmo com campos sujos")
	
	# O ideal: O sistema sanitizou e resetou o Money para 0 ou manteve o que deu.
	# Verifica se Money é um número válido (mesmo que 0) e não a string "MUITO DINHEIRO"
	var is_money_number = (typeof(save_manager.save_file_data.Money) == TYPE_INT)
	assert_true(is_money_number, "A variável Money deve ter sido sanitizada para INT")

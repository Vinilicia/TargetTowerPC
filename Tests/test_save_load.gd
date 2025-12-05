extends Node
class_name TestSaveLoadManager

const TEST_SLOT := 7
const TEST_SLOT_COPY := 8
const TEST_SETTINGS_PATH := "user://settings.json"
const TEST_CONTROL_PATH := "user://Controls_%d.map" % TEST_SLOT

var save_manager: SaveLoadManager

func assert_true(cond: bool) -> void:
	print("________________________________")
	assert(cond, "assert_true failed: condição é falsa")

func assert_false(cond: bool) -> void:
	print("________________________________")
	assert(not cond, "assert_false failed: condição é verdadeira")

func assert_eq(a, b) -> void:
	var ok : bool = (a == b)
	print("________________________________")
	assert(ok, "assert_eq failed: %s != %s" % [str(a), str(b)])

func _ready():
	print("====================")
	print("RODANDO TESTES...")
	print("====================")

	_run(test_create_new_save_if_missing)
	_run(test_save_and_load_roundtrip)
	_run(test_save_migration)
	_run(test_settings_save_and_load)
	_run(test_settings_migration)
	_run(test_controls_save_and_load)
	_run(test_copy_slot)
	_run(test_delete_slot)

	print("====================")
	print("TODOS TESTES FINALIZADOS")
	print("====================")

func _run(test_func: Callable):
	print("Executando:", test_func.get_method())
	before_each()
	test_func.call()
	after_each()
	print("✔ OK:", test_func.get_method())

func before_each():
	save_manager = SaveLoadManager.new()

	var dir = DirAccess.open("user://")
	var files = dir.get_files()
	for f in files:
		if f.begins_with("SaveFile_") or f.begins_with("Controls_") or f == "settings.json":
			dir.remove("user://" + f)

func after_each():
	pass

func test_create_new_save_if_missing():
	assert_false(FileAccess.file_exists(save_manager.get_save_path(TEST_SLOT)))

	var result = save_manager._load(TEST_SLOT)

	assert_true(result)
	assert_true(FileAccess.file_exists(save_manager.get_save_path(TEST_SLOT)))

	assert_eq(save_manager.save_file_data.MaxHealth, 5)
	assert_eq(save_manager.save_file_data.Money, 0)

func test_save_and_load_roundtrip():
	save_manager._load(TEST_SLOT)

	save_manager.save_file_data.set_money(123)
	save_manager.save_file_data.set_max_health(9)

	save_manager._save(TEST_SLOT)

	var new_manager := SaveLoadManager.new()
	new_manager._load(TEST_SLOT)

	assert_eq(new_manager.save_file_data.Money, 123)
	assert_eq(new_manager.save_file_data.MaxHealth, 9)

func test_save_migration():
	var path = save_manager.get_save_path(TEST_SLOT)
	var file = FileAccess.open_encrypted_with_pass(path, FileAccess.WRITE, "1n1c19a436")
	file.store_string(JSON.stringify({
		"SaveVersion": 0,
		"HealthUpgrades": [true, false, false, false],
		"ManaUpgrades": [false, true, false, false],
		"AvailableArrows": [true, true],
		"LastBenchID": 9,
		"AreaOfBench": 99,
		"MaxHealth": 2,
		"MaxMana": 2,
		"Money": 777,
		"MoneyUpgrades": 1
	}))
	file.close()

	var result = save_manager._load(TEST_SLOT)

	assert_true(result)
	assert_eq(save_manager.save_file_data.LastBenchID, 9)
	assert_eq(save_manager.save_file_data.Money, 777)
	assert_eq(save_manager.save_file_data.SaveVersion, SaveDataResource.new().SaveVersion)

func test_settings_save_and_load():
	save_manager.settings_data["master_volume"] = 0.33
	save_manager.settings_data["locale"] = "pt"

	save_manager.save_settings()

	var new := SaveLoadManager.new()
	new.load_settings()

	assert_eq(new.settings_data["master_volume"], 0.33)
	assert_eq(new.settings_data["locale"], "pt")

func test_settings_migration():
	var file = FileAccess.open(TEST_SETTINGS_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({
		"SettingsVersion": 0,
		"master_volume": 0.1,
		"music_volume": 0.2,
		"sfx_volume": 0.3,
		"display_mode": 0,
		"resolution_index": 1,
		"brightness_value": 0.9,
		"locale": "es"
	}))
	file.close()

	save_manager.load_settings()

	assert_eq(save_manager.settings_data["master_volume"], 0.1)
	assert_eq(save_manager.settings_data["locale"], "es")
	assert_eq(save_manager.settings_data["SettingsVersion"], SaveLoadManager.SETTINGS_VERSION)

func test_controls_save_and_load():
	InputMap.add_action("attack")
	var ev := InputEventKey.new()
	ev.keycode = KEY_K
	InputMap.action_add_event("attack", ev)

	save_manager.save_controls_for_slot(TEST_SLOT)
	assert_true(FileAccess.file_exists(TEST_CONTROL_PATH))

	InputMap.erase_action("attack")
	InputMap.add_action("attack")

	save_manager.load_controls_for_slot(TEST_SLOT)

	var events = InputMap.action_get_events("attack")
	assert_eq(events.size(), 1)
	assert_eq(events[0].keycode, KEY_K)

func test_copy_slot():
	save_manager._load(TEST_SLOT)
	save_manager.save_file_data.set_money(500)
	save_manager._save(TEST_SLOT)

	save_manager.copy_slot(TEST_SLOT, TEST_SLOT_COPY)

	var m2 := SaveLoadManager.new()
	m2._load(TEST_SLOT_COPY)

	assert_eq(m2.save_file_data.Money, 500)

func test_delete_slot():
	save_manager._load(TEST_SLOT)
	save_manager._save(TEST_SLOT)

	assert_true(FileAccess.file_exists(save_manager.get_save_path(TEST_SLOT)))

	save_manager.delete_slot(TEST_SLOT)

	assert_false(FileAccess.file_exists(save_manager.get_save_path(TEST_SLOT)))

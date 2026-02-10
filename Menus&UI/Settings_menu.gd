extends Control

@export var Menus_Container : MarginContainer
@export var Buttons_Container : MarginContainer

@export_group("Menus")
@export var Controls_menu : Control
@export var Audio_menu : Control
@export var Video_menu : Control

@export_group("Buttons")
@export var Controls_button : Button
@export var Audio_button : Button
@export var Video_button : Button

@export var language_button : OptionButton

var last_button_pressed : Button

# lista de idiomas — índice = ID do item no OptionButton (0..16)
var languages := [
	"en", # 0 English
	"fr", # 1 Français
	"it", # 2 Italiano
	"de", # 3 Deutsch
	"es", # 4 Español
	"pt", # 5 Português
	"da", # 6 Dansk
	"sv", # 7 Svenska
	"no", # 8 Norsk
	"is", # 9 Íslenska
	"hu", # 10 Magyar
	"pl", # 11 Polski
	"tr", # 12 Türkçe
	"ru", # 13 Русский
	"uk", # 14 Українська
	"cs", # 15 Čeština
	"sk"  # 16 Slovenčina
]

func _ready() -> void:
	last_button_pressed = Controls_button
	sync_language_button_with_locale()

func give_focus() -> void:
	Controls_button.grab_focus()

func setup_menu() -> void:
	Menus_Container.visible = true
	Buttons_Container.visible = false
	for menu in Menus_Container.get_children():
		if menu is not ColorRect:
			menu.visible = false

func setup_buttons() -> void:
	Menus_Container.visible = false
	Buttons_Container.visible = true
	for menu in Menus_Container.get_children():
		if menu is not ColorRect:
			menu.visible = false
	last_button_pressed.grab_focus()

func _on_controls_button_pressed() -> void:
	last_button_pressed = Controls_button
	setup_menu()
	Controls_menu.visible = true
	var menu_back_button : Button = Controls_menu.find_child("BackButton", true)
	if menu_back_button:
		menu_back_button.grab_focus()

func _on_audio_button_pressed() -> void:
	last_button_pressed = Audio_button
	setup_menu()
	Audio_menu.visible = true
	var menu_back_button : Button = Audio_menu.find_child("BackButton", true)
	if menu_back_button:
		menu_back_button.grab_focus()

func _on_video_button_pressed() -> void:
	last_button_pressed = Video_button
	setup_menu()
	Video_menu.visible = true
	var menu_back_button : Button = Video_menu.find_child("BackButton", true)
	if menu_back_button:
		menu_back_button.grab_focus()

# ---------------------------------------------------------
#  SINCRONIZAR OptionButton COM O LOCALE ATUAL
# ---------------------------------------------------------
func sync_language_button_with_locale() -> void:
	if language_button == null:
		return

	var current_locale := TranslationServer.get_locale()

	# 1) tenta match exato usando os IDs (0..16)
	for id in range(languages.size()):
		if languages[id] == current_locale:
			var idx := language_button.get_item_index(id) # -> index no OptionButton (pula separadores)
			if idx != -1:
				language_button.select(idx)
				return

	# 2) tenta match por prefixo (ex: "pt_BR" -> "pt")
	var prefix := current_locale.split("_")[0]
	if prefix != current_locale:
		for id in range(languages.size()):
			if languages[id] == prefix:
				var idx := language_button.get_item_index(id)
				if idx != -1:
					language_button.select(idx)
					return

	# 3) fallback para English (id 0) caso nada bata
	var fallback_idx := language_button.get_item_index(0)
	if fallback_idx != -1:
		language_button.select(fallback_idx)

# Godot chama isso quando o locale muda
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		sync_language_button_with_locale()

# ---------------------------------------------------------
#  QUANDO O JOGADOR MUDA A LÍNGUA NO OptionButton
# ---------------------------------------------------------
func _on_language_button_item_selected(index: int) -> void:
	if language_button == null:
		return

	# index é o índice do item no OptionButton (conta separadores).
	# precisamos do id (0..16) para mapear ao array languages
	var item_id := language_button.get_item_id(index)
	if item_id < 0 or item_id >= languages.size():
		return

	var chosen_locale : String = languages[item_id]

	SaveManager.call("set_locale_and_save", chosen_locale)
	sync_language_button_with_locale()

class_name MainMenu
extends Control

signal new_game_requested(character_name: String)
signal load_game_requested(file_name: String)
signal join_game_requested(address: String)
signal connection_cancelled

@onready var _new_game: MainMenuCard = $BrowserWindow/Browser/Layout/Website/Layout/Cards/NewGame
@onready var _load: MainMenuCard = $BrowserWindow/Browser/Layout/Website/Layout/Cards/Load
@onready var _join: MainMenuCard = $BrowserWindow/Browser/Layout/Website/Layout/Cards/Join
@onready var _close: Button = $BrowserWindow/Browser/Layout/TitleBar/Row/Close
@onready var _language: OptionButton = $BrowserWindow/Browser/Layout/Website/Layout/Brand/Language
@onready var _overlay: ColorRect = $ModalOverlay
@onready var _pages: VBoxContainer = $ModalOverlay/Center/Frame/Layout/Body/Pages
@onready var _modal_close: Button = $ModalOverlay/Center/Frame/Layout/TitleBar/Row/Close
@onready var _address: LineEdit = $ModalOverlay/Center/Frame/Layout/Body/Pages/Join/Address
@onready var _address_error: Label = $ModalOverlay/Center/Frame/Layout/Body/Pages/Join/Error
@onready var _character_name: LineEdit = _pages.get_node("NewGame/Card/Layout/Details/Holder/NameInput")
@onready var _buy: Button = _pages.get_node("NewGame/Checkout/Actions/Buy")
@onready var _navigation: Array[Control] = [_new_game, _load, _join, _language, _close]

var _locale_codes := PackedStringArray()
var _previous_focus: Control
var _busy := false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_focus_loop(_navigation)
	_sync_language_selector()
	_language.item_selected.connect(func(index: int): L10n.set_locale(_locale_codes[index]))
	_new_game.pressed.connect(_show_new_game)
	_load.pressed.connect(_show_saves)
	_join.pressed.connect(_show_join)
	_close.pressed.connect(_show_quit)
	_modal_close.pressed.connect(_close_modal)
	for path in ["NewGame/Checkout/Actions/Back", "Load/Back", "Join/Actions/Back", "Quit/Actions/Back", "Status/Back"]:
		_pages.get_node(path).pressed.connect(_close_modal)
	_update_purchase_button(_character_name.text)
	_buy.pressed.connect(_submit_purchase)
	_character_name.text_changed.connect(_update_purchase_button)
	_character_name.text_submitted.connect(func(_value: String): _submit_purchase())
	_pages.get_node("Join/Actions/Buy").pressed.connect(_submit_address)
	_address.text_submitted.connect(func(_text: String): _submit_address())
	_address.text_changed.connect(func(_text: String): _address_error.hide())
	_pages.get_node("Quit/Actions/Exit").pressed.connect(get_tree().quit)
	_new_game.grab_focus.call_deferred()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is not InputEventKey or not event.pressed or event.is_echo():
		return
	if event.keycode == KEY_ESCAPE:
		if _overlay.visible:
			_close_modal()
		else:
			_show_quit()
		get_viewport().set_input_as_handled()
	elif not _overlay.visible and event.physical_keycode in [KEY_W, KEY_A, KEY_S, KEY_D]:
		var index := _navigation.find(get_viewport().gui_get_focus_owner())
		var step := -1 if event.physical_keycode in [KEY_W, KEY_A] else 1
		_navigation[posmod(index + step, _navigation.size())].grab_focus()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_sync_language_selector()

func _sync_language_selector() -> void:
	var locales := L10n.available_locales()
	if locales != _locale_codes:
		_locale_codes = locales
		_language.clear()
		for locale in locales:
			_language.add_item(L10n.locale_name(locale))
	var index := _locale_codes.find(L10n.get_locale())
	if index >= 0:
		_language.select(index)

func _focus_loop(controls: Array[Control]) -> void:
	for i in controls.size():
		var current := controls[i]
		var previous := current.get_path_to(controls[posmod(i - 1, controls.size())])
		var following := current.get_path_to(controls[(i + 1) % controls.size()])
		current.focus_previous = previous
		current.focus_next = following
		current.focus_neighbor_left = previous
		current.focus_neighbor_top = previous
		current.focus_neighbor_right = following
		current.focus_neighbor_bottom = following

func _show_page(page_name: String, controls: Array[Control]) -> void:
	if not _overlay.visible:
		_previous_focus = get_viewport().gui_get_focus_owner()
	for page: Control in _pages.get_children():
		page.visible = page.name == page_name
	_overlay.show()
	var focus_targets: Array[Control] = [_modal_close]
	focus_targets.append_array(controls)
	_focus_loop(focus_targets)
	controls[0].grab_focus.call_deferred()

func _close_modal() -> void:
	if _busy:
		_busy = false
		connection_cancelled.emit()
	_overlay.hide()
	if is_instance_valid(_previous_focus):
		_previous_focus.grab_focus()
	else:
		_new_game.grab_focus()

func _show_new_game() -> void:
	var amount := _new_game.price
	L10n.bind(_pages.get_node("NewGame/Checkout/Price/Value"), L10n.message(&"ui.menu.new_game.price", {
		"amount": amount, "currency": L10n.message(&"common.currency.maren", {}, amount),
	}))
	_show_page("NewGame", [_character_name, _buy, _pages.get_node("NewGame/Checkout/Actions/Back")])

func _update_purchase_button(value: String) -> void:
	_buy.disabled = value.strip_edges().is_empty()
	_buy.focus_mode = Control.FOCUS_NONE if _buy.disabled else Control.FOCUS_ALL

func _submit_purchase() -> void:
	var character_name := _character_name.text.strip_edges()
	if not character_name.is_empty():
		new_game_requested.emit(character_name)

func _show_saves() -> void:
	var list: VBoxContainer = _pages.get_node("Load/Scroll/Saves")
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()
	var seen_campaigns := {}
	var controls: Array[Control] = []
	for save in SaveManager.list_saves():
		var error: LocalizedText = save.get("error_text")
		var campaign := String(save.get("campaign_id", ""))
		if error == null and seen_campaigns.has(campaign):
			continue
		var item := Button.new()
		item.alignment = HORIZONTAL_ALIGNMENT_LEFT
		item.custom_minimum_size.y = 45
		if error != null:
			item.text = "ui.menu.load.corrupt"
			L10n.bind(item, error, &"tooltip_text")
			item.disabled = true
		else:
			seen_campaigns[campaign] = true
			L10n.bind(item, L10n.message(&"ui.menu.load.entry", {
				"date": L10n.date_time(int(save.saved_at / 1000000)),
			}))
			item.pressed.connect(load_game_requested.emit.bind(save.file_name))
			controls.append(item)
		list.add_child(item)
	var count := list.get_child_count()
	_pages.get_node("Load/Empty").visible = count == 0
	var scroll: ScrollContainer = _pages.get_node("Load/Scroll")
	scroll.visible = count > 0
	scroll.custom_minimum_size.y = mini(count * 53, 260)
	controls.append(_pages.get_node("Load/Back"))
	_show_page("Load", controls)

func _show_join() -> void:
	_address_error.hide()
	_show_page("Join", [_address, _pages.get_node("Join/Actions/Buy"), _pages.get_node("Join/Actions/Back")])

func _submit_address() -> void:
	var address := _address.text.strip_edges()
	if not address.is_valid_ip_address():
		_address_error.show()
		_address.grab_focus()
		return
	join_game_requested.emit(address)

func _show_quit() -> void:
	_show_page("Quit", [_pages.get_node("Quit/Actions/Exit"), _pages.get_node("Quit/Actions/Back")])

func show_connecting() -> void:
	_busy = true
	_pages.get_node("Status/Title").text = "ui.menu.status.connecting"
	L10n.bind(_pages.get_node("Status/Message"), null)
	_show_page("Status", [_pages.get_node("Status/Back")])

func show_error(message: LocalizedText) -> void:
	_busy = false
	_pages.get_node("Status/Title").text = "ui.menu.status.error"
	L10n.bind(_pages.get_node("Status/Message"), message if message != null else L10n.message(&"error.unknown"))
	_show_page("Status", [_pages.get_node("Status/Back")])

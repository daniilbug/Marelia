extends Node

const WORLD := preload("res://scenes/levels/main.tscn")
const MENU := preload("res://scenes/ui/main/menu.tscn")
const CHARACTER_CREATION := preload("res://scenes/ui/main/character-creation.tscn")
const LUGGAGE := preload("res://scenes/ui/main/luggage.tscn")
@onready var session: NetworkSession = $NetworkSession
var _world: Main
var _menu: MainMenu
var _character_creation: CharacterCreation
var _luggage: Luggage
var _port := 7777
var _direct_launch := false

func _ready() -> void:
	session.started.connect(_open_world)
	session.failed.connect(func(error: Error): _fail(L10n.message(&"error.connection.failed", {"code": error})))
	session.disconnected.connect(_on_disconnected)
	var options := {}
	for argument in OS.get_cmdline_user_args():
		var pair := argument.split("=", true, 1)
		options[pair[0]] = pair[1] if pair.size() == 2 else ""
	Player.local_setup = {"name": options.get("--name", "Player")}
	_port = int(options.get("--port", "7777"))
	_direct_launch = options.has("--join") or options.has("--host") or options.has("--load")
	if not _direct_launch:
		_show_menu()
		return
	if not options.has("--join"):
		if options.has("--load"):
			if not SaveManager.prepare_load(options["--load"]):
				_fail(SaveManager.last_error_text)
				return
		else:
			SaveManager.new_game()
	if options.has("--join"):
		session.join(options["--join"] if not options["--join"].is_empty() else "127.0.0.1", _port)
	elif options.has("--host"):
		session.host(_port)
	else:
		session.start_local()

func _show_menu() -> void:
	_menu = MENU.instantiate() as MainMenu
	_menu.property_purchased.connect(_open_character_creation)
	_menu.load_game_requested.connect(_load_game)
	_menu.join_game_requested.connect(_join_game)
	_menu.connection_cancelled.connect(session.close)
	_menu.status_closed.connect(_resume_luggage)
	add_child(_menu)

func _open_character_creation(character_name: String) -> void:
	if is_instance_valid(_character_creation):
		return
	_character_creation = CHARACTER_CREATION.instantiate() as CharacterCreation
	_character_creation.character_name = character_name
	_character_creation.back_requested.connect(_return_to_purchase)
	_character_creation.luggage_requested.connect(_open_luggage)
	_menu.hide()
	add_child(_character_creation)

func _open_luggage() -> void:
	_character_creation.hide()
	if _luggage == null:
		_luggage = LUGGAGE.instantiate() as Luggage
		_luggage.back_requested.connect(_return_to_character_creation)
		_luggage.boarding_requested.connect(_start_new_game)
		add_child(_luggage)
	else:
		_luggage.show()
	_luggage.focus_items()

func _return_to_character_creation() -> void:
	_luggage.hide()
	_character_creation.show()
	_character_creation.focus_continue()

func _resume_luggage() -> void:
	if _luggage == null:
		return
	_menu.hide()
	_luggage.show()
	_luggage.focus_boarding()

func _clear_new_game_setup() -> void:
	if _luggage != null:
		_luggage.hide()
		_luggage.queue_free()
		_luggage = null
	if _character_creation != null:
		_character_creation.hide()
		_character_creation.queue_free()
		_character_creation = null

func _return_to_purchase() -> void:
	_clear_new_game_setup()
	_menu.show()
	_menu.resume_purchase()

func _start_new_game() -> void:
	Player.local_setup = {
		"name": _character_creation.character_name,
		"appearance": _character_creation.get_appearance(),
	}
	_luggage.hide()
	_menu.show()
	SaveManager.new_game()
	_menu.show_connecting()
	session.host(_port)

func _load_game(file_name: String) -> void:
	if not SaveManager.prepare_load(file_name):
		_menu.show_error(SaveManager.last_error_text)
		return
	_menu.show_connecting()
	session.host(_port)

func _join_game(address: String) -> void:
	# Discard a pending host snapshot if an earlier load attempt failed.
	SaveManager.take_pending_snapshot()
	_menu.show_connecting()
	session.join(address, _port)

func _open_world() -> void:
	_world = WORLD.instantiate() as Main
	_world.load_failed.connect(_fail)
	add_child(_world)
	# A failed world can clear this reference during _ready().
	if _world == null:
		return
	_clear_new_game_setup()
	if is_instance_valid(_menu):
		_menu.queue_free()
		_menu = null

func _on_disconnected() -> void:
	if _direct_launch:
		get_tree().quit()
	else:
		_fail(L10n.message(&"error.connection.disconnected"))

func _unhandled_input(event: InputEvent) -> void:
	if _world == null or _world.local_player == null or _world.local_player.is_world_input_blocked:
		return
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_F5:
			_world.world_save.request_save()
		elif event.keycode == KEY_ESCAPE:
			session.close()
			get_tree().quit()

func _fail(message: LocalizedText) -> void:
	if _direct_launch:
		push_error(message.resolve())
		get_tree().quit(1)
		return
	session.close()
	if is_instance_valid(_world):
		_world.queue_free()
		_world = null
	# A world can fail inside _ready(), while add_child() is still in progress.
	_recover_menu.call_deferred(message)

func _recover_menu(message: LocalizedText) -> void:
	if not is_instance_valid(_menu):
		_show_menu()
	_menu.show_error(message)

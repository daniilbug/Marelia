extends Node

const WORLD := preload("res://scenes/levels/main.tscn")
const MENU := preload("res://scenes/ui/main/menu.tscn")
@onready var session: NetworkSession = $NetworkSession
var _world: Main
var _menu: MainMenu
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
	_menu.new_game_requested.connect(_start_new_game)
	_menu.load_game_requested.connect(_load_game)
	_menu.join_game_requested.connect(_join_game)
	_menu.connection_cancelled.connect(session.close)
	add_child(_menu)

func _start_new_game(character_name: String) -> void:
	Player.local_setup["name"] = character_name
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
	if is_instance_valid(_menu):
		_menu.queue_free()
		_menu = null
	_world = WORLD.instantiate() as Main
	_world.load_failed.connect(_fail)
	add_child(_world)

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

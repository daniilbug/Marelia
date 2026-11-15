extends Node

## Minimal executable bootstrap. Game menus and save policies belong to the game.
const WORLD := preload("res://scenes/levels/main.tscn")
@onready var session: NetworkSession = $NetworkSession
var _world: Main

func _ready() -> void:
	session.started.connect(_open_world)
	session.failed.connect(func(error: Error): _fail("Ошибка подключения: %d" % error))
	session.disconnected.connect(func(): get_tree().quit())
	var options := {}
	for argument in OS.get_cmdline_user_args():
		var pair := argument.split("=", true, 1)
		options[pair[0]] = pair[1] if pair.size() == 2 else ""
	Player.local_setup = {"name": options.get("--name", "Player")}
	var port := int(options.get("--port", "7777"))
	if not options.has("--join"):
		if options.has("--load"):
			if not SaveManager.prepare_load(options["--load"]):
				_fail(SaveManager.last_error)
				return
		else:
			SaveManager.new_game()
	if options.has("--join"):
		session.join(options["--join"] if not options["--join"].is_empty() else "127.0.0.1", port)
	elif options.has("--host"):
		session.host(port)
	else:
		session.start_local()

func _open_world() -> void:
	_world = WORLD.instantiate() as Main
	_world.load_failed.connect(_fail)
	add_child(_world)

func _unhandled_input(event: InputEvent) -> void:
	if _world == null or _world.local_player == null or _world.local_player.is_world_input_blocked:
		return
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_F5:
			_world.world_save.request_save()
		elif event.keycode == KEY_ESCAPE:
			session.close()
			get_tree().quit()

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)

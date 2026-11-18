extends Node

## Only the host writes saves. Files contain values, never serialized Objects.
const FORMAT_VERSION := 1
const MAX_FILE_BYTES := 8 * 1024 * 1024

var save_directory := "user://saves"
var campaign_id := ""
var last_error_text: LocalizedText
var last_error: String:
	get:
		return last_error_text.resolve() if last_error_text != null else ""
var _pending_snapshot: Dictionary = {}

func new_game() -> void:
	campaign_id = "%d_%d" % [int(Time.get_unix_time_from_system()), randi()]
	_pending_snapshot.clear()
	last_error_text = null

func take_pending_snapshot() -> Dictionary:
	var snapshot := _pending_snapshot
	_pending_snapshot = {}
	return snapshot

func prepare_load(file_name: String) -> bool:
	var save := _read(file_name)
	if save.is_empty():
		return false
	campaign_id = save.campaign_id
	_pending_snapshot = save.snapshot
	return true

func write_snapshot(snapshot: Dictionary) -> bool:
	if not multiplayer.is_server():
		return false
	if not WorldSave.is_valid_snapshot(snapshot):
		return _fail(&"error.save.invalid_snapshot", ERR_INVALID_DATA)
	if campaign_id.is_empty():
		new_game()
	last_error_text = null
	var error := DirAccess.make_dir_recursive_absolute(save_directory)
	if error != OK:
		return _fail(&"error.save.create_directory", error)
	var stamp := int(Time.get_unix_time_from_system() * 1000000)
	# Persist ordering independently of wall-clock corrections, including restarts.
	var revision := 1
	for checkpoint in list_saves():
		revision = maxi(revision, checkpoint.get("revision", 0) + 1)
	var file_name := "%s_%d_%d.save" % [campaign_id, stamp, Time.get_ticks_usec()]
	var path := save_directory.path_join(file_name)
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return _fail(&"error.save.open_file", FileAccess.get_open_error())
	var save := {
		"version": FORMAT_VERSION, "campaign_id": campaign_id,
		"saved_at": stamp, "revision": revision, "snapshot": snapshot,
	}
	var stored := file.store_var(save, false)
	file.flush()
	error = file.get_error()
	file.close()
	if not stored or error != OK:
		DirAccess.remove_absolute(temporary)
		return _fail(&"error.save.write", error)
	if _read(file_name + ".tmp") != save:
		DirAccess.remove_absolute(temporary)
		return _fail(&"error.save.verify", ERR_FILE_CORRUPT)
	# Publish only a verified checkpoint; older files remain backups.
	error = DirAccess.rename_absolute(temporary, path)
	if error != OK:
		return _fail(&"error.save.finalize", error)
	last_error_text = null
	return true

func list_saves() -> Array[Dictionary]:
	var saves: Array[Dictionary] = []
	if not DirAccess.dir_exists_absolute(save_directory):
		return saves
	for file_name in DirAccess.get_files_at(save_directory):
		if file_name.get_extension() != "save":
			continue
		var save := _read(file_name)
		if save.is_empty():
			saves.append({"file_name": file_name, "saved_at": 0, "error_text": last_error_text})
			continue
		var player: Dictionary = save.snapshot.player
		saves.append({
			"file_name": file_name, "saved_at": save.saved_at,
			"campaign_id": save.campaign_id,
			"revision": save.get("revision", 0),
			"name": player.player_name, "level": player.level_id,
		})
	saves.sort_custom(func(a: Dictionary, b: Dictionary):
		return a.get("revision", 0) > b.get("revision", 0) if a.get("revision", 0) != b.get("revision", 0) else a.saved_at > b.saved_at
	)
	last_error_text = null
	return saves

func _read(file_name: String) -> Dictionary:
	last_error_text = L10n.message(&"error.save.corrupt")
	if file_name != file_name.get_file():
		return {}
	var file := FileAccess.open(save_directory.path_join(file_name), FileAccess.READ)
	if file == null or file.get_length() < 4 or file.get_length() > MAX_FILE_BYTES:
		return {}
	var bytes := file.get_buffer(file.get_length())
	if bytes.size() < 4 or bytes.decode_u32(0) != bytes.size() - 4:
		return {}
	var value: Variant = bytes_to_var(bytes.slice(4))
	if value is not Dictionary or not value.get("snapshot") is Dictionary \
		or not value.get("campaign_id") is String or not value.get("saved_at") is int:
		return {}
	if value.get("version", 0) != FORMAT_VERSION:
		last_error_text = L10n.message(&"error.save.unsupported_version")
		return {}
	if not value.get("revision", 0) is int or value.get("revision", 0) < 0:
		return {}
	if not value.campaign_id.is_valid_filename() or not WorldSave.is_valid_snapshot(value.snapshot):
		last_error_text = L10n.message(&"error.save.invalid_data")
		return {}
	last_error_text = null
	return value

func _fail(message_key: StringName, error: Error) -> bool:
	last_error_text = L10n.message(&"error.with_code", {"message": L10n.message(message_key), "code": error})
	return false

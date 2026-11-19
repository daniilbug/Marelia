class_name WorldSave
extends Node

signal restored(player: Player)
signal saved(success: bool)


## Coordinates host checkpoints. Levels and objects own their saved fields.
@onready var _world: Main = get_parent()
var _requested := false

func request_save() -> void:
	if multiplayer.is_server():
		_requested = true

func _process(_delta: float) -> void:
	if not multiplayer.is_server():
		return
	if not _requested or not is_instance_valid(_world.local_player):
		return
	_requested = false
	var success := SaveManager.write_snapshot(capture())
	saved.emit(success)
	if not success:
		push_warning(SaveManager.last_error)

func capture() -> Dictionary:
	var levels := {}
	for level in _world.get_levels():
		levels[level.level_id] = level.get_save_data()
	return {
		"player": _world.local_player.get_save_data(), "levels": levels,
		"clock": _world.world_time.get_save_data(),
	}

func restore_world(snapshot: Dictionary) -> void:
	_world.world_time.apply_save_data(snapshot.clock)
	# Build every level first, then restore fields and references between objects.
	# Levels introduced after this checkpoint keep their scene's initial state.
	for id in snapshot.levels:
		_world.get_level(id).prepare_save_restore(snapshot.levels[id])
	for id in snapshot.levels:
		_world.get_level(id).apply_save_data(snapshot.levels[id])
	restored.emit(_world.local_player)

func can_restore(snapshot: Dictionary) -> bool:
	for id in snapshot.levels:
		var level := _world.get_level(id)
		if level == null or not level.can_restore_save_data(snapshot.levels[id]):
			return false
	var platform_path: NodePath = snapshot.player.get("platform_path", NodePath())
	if not platform_path.is_empty() and _world.get_level(snapshot.player.level_id).get_node_or_null(platform_path) is not WalkablePlatform:
		return false
	return true

static func is_valid_snapshot(snapshot: Dictionary) -> bool:
	if not SaveGraph.matches(snapshot, {
		"player": Player.SAVE_SCHEMA, "clock": WorldTime.SAVE_SCHEMA,
		"levels": {},
	}):
		return false
	if snapshot.player.level_id not in snapshot.levels:
		return false
	var appearance: Dictionary = snapshot.player.appearance
	if not SaveGraph.matches(appearance.get("gender", Player.Gender.MALE), [Player.Gender.MALE, Player.Gender.FEMALE]):
		return false
	# Version 1 saves before character creation use the original skin tone.
	var skin_tone: Variant = appearance.get("skin_tone_id", CharacterSprite.DEFAULT_SKIN_TONE)
	if not SaveGraph.matches(skin_tone, Vector2i(0, CharacterSprite.SKIN_TONES.size() - 1)):
		return false
	if snapshot.player.has("platform_path"):
		if snapshot.player.platform_path is not NodePath or (not snapshot.player.platform_path.is_empty() and not SaveGraph.safe_path(snapshot.player.platform_path)):
			return false
	# Optional in version 1: older saves receive a starter wardrobe once on load.
	if snapshot.player.has("wardrobe"):
		if not Player.is_valid_wardrobe(snapshot.player.wardrobe):
			return false
		if Vector2i(appearance.top_id, appearance.top_color_id) not in snapshot.player.wardrobe.tops \
			or Vector2i(appearance.pants_id, appearance.pants_color_id) not in snapshot.player.wardrobe.bottoms:
			return false
	for id in snapshot.levels:
		if not id is String or id.is_empty() or not SaveGraph.is_valid_level(snapshot.levels[id]):
			return false
	return true

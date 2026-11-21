@tool
class_name DecorationGroup
extends Node2D

@export var included_pieces: Dictionary[NodePath, bool] = {}:
	set(value):
		included_pieces = value
		_apply_included_pieces()

@export var style: DecorationStyle:
	set(value):
		if style == value:
			return
		if style != null and style.changed.is_connected(refresh):
			style.changed.disconnect(refresh)
		style = value
		if style != null:
			style.changed.connect(refresh)
		refresh()

@export var style_variants: DecorationVariants
@export_tool_button("Randomize decorations") var randomize_action: Callable = randomize

var _piece_visibility_defaults: Dictionary[NodePath, bool] = {}

func _ready() -> void:
	for piece in get_pieces():
		piece.visibility_changed.connect(_update_piece_processing.bind(piece))
		_update_piece_processing(piece)
	refresh()

func get_pieces() -> Array[StaticBody2D]:
	var pieces: Array[StaticBody2D] = []
	pieces.assign(find_children("*", "StaticBody2D", true, false))
	return pieces

func _update_piece_processing(piece: StaticBody2D) -> void:
	piece.process_mode = Node.PROCESS_MODE_INHERIT if piece.visible else Node.PROCESS_MODE_DISABLED

func _apply_included_pieces() -> void:
	if not is_node_ready():
		return
	for piece in get_pieces():
		var path := get_path_to(piece)
		if included_pieces.has(path):
			if not _piece_visibility_defaults.has(path):
				_piece_visibility_defaults[path] = piece.visible
			piece.visible = included_pieces[path]
		else:
			var fallback: bool = _piece_visibility_defaults.get(path, piece.visible)
			_piece_visibility_defaults.erase(path)
			piece.visible = _get_piece_visibility(piece, fallback)

func _get_piece_visibility(_piece: StaticBody2D, fallback: bool) -> bool:
	return fallback

func apply_placement_style(profile: DecorationStyle) -> void:
	if profile != null:
		style = profile

func randomize() -> void:
	if style_variants != null:
		apply_placement_style(style_variants.choose_style())

func refresh() -> void:
	if not is_node_ready():
		return
	if style != null:
		for piece in get_pieces():
			style.apply_to(piece)
	_apply_included_pieces()

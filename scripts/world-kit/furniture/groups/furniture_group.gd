@tool
class_name HouseFurnitureGroup
extends Node2D

@export var included_pieces: Dictionary[NodePath, bool] = {}:
	set(value):
		included_pieces = value
		_apply_included_pieces()

@export var style: HouseFurnitureStyle:
	set(value):
		if style == value:
			return
		if style != null and style.changed.is_connected(refresh):
			style.changed.disconnect(refresh)
		style = value
		if style != null:
			style.changed.connect(refresh)
		refresh()

func _ready() -> void:
	for piece in get_pieces():
		piece.visibility_changed.connect(_update_visibility.bind(piece))
		_update_visibility(piece)
	_apply_included_pieces()
	refresh()

func get_pieces() -> Array[FurniturePiece]:
	var pieces: Array[FurniturePiece] = []
	for node in find_children("*", "StaticBody2D", true, false):
		if node is FurniturePiece:
			pieces.append(node)
	return pieces

func _update_visibility(piece: FurniturePiece) -> void:
	piece.process_mode = Node.PROCESS_MODE_INHERIT if piece.visible else Node.PROCESS_MODE_DISABLED

func _apply_included_pieces() -> void:
	if not is_node_ready():
		return
	for path in included_pieces:
		var piece := get_node_or_null(path) as FurniturePiece
		if piece != null:
			piece.visible = included_pieces[path]

func apply_placement_style(profile: Resource) -> void:
	if profile is HouseFurnitureStyle:
		style = profile

func refresh() -> void:
	if not is_node_ready() or style == null:
		return
	for piece in get_pieces():
		piece.apply_group_style(style)

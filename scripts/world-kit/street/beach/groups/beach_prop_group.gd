@tool
class_name BeachPropGroup
extends Node2D

@export var included_pieces: Dictionary[NodePath, bool] = {}:
	set(value):
		var previous := included_pieces
		included_pieces = value
		if is_node_ready():
			for path in previous:
				if not included_pieces.has(path):
					_set_piece_included(path, true)
			_apply_included_pieces()

func _ready() -> void:
	_apply_included_pieces()

func _apply_included_pieces() -> void:
	for path in included_pieces:
		_set_piece_included(path, included_pieces[path])

func _set_piece_included(path: NodePath, included: bool) -> void:
	var piece := get_node_or_null(path) as StreetProp
	if piece != null and piece.get_parent() == self:
		piece.visible = included
		piece.process_mode = Node.PROCESS_MODE_INHERIT if included else Node.PROCESS_MODE_DISABLED

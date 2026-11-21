@tool
class_name BeachSandcastleStyle
extends DecorationStyle

@export var style: BeachSandcastle.Style = BeachSandcastle.Style.TURRETS:
	set(value):
		style = value
		emit_changed()

func apply_to(piece: StaticBody2D) -> void:
	if piece is BeachSandcastle:
		piece.set_appearance(style)

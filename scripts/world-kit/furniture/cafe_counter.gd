@tool
class_name CafeCounter
extends FurniturePiece

enum Style { WALNUT, OAK, CERAMIC }

signal style_changed(design: int)

@export_group("Design")
@export var style: Style = Style.WALNUT:
	set(value):
		if style == value:
			return
		style = value
		_refresh_appearance()
		style_changed.emit(style)

func _ready() -> void:
	super._ready()
	var area := $TransparencyArea as TransparencyArea
	var targets := area.targets.duplicate()
	for child in get_children():
		if child is CountertopProp:
			style_changed.connect(child.set_style)
			child.set_style(style)
			if child not in targets:
				targets.append(child)
	area.targets = targets

func _get_design_index() -> int:
	return style

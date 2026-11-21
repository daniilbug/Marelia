@tool
class_name CountertopProp
extends Sprite2D

@export var variants: Dictionary[int, Texture2D] = {}:
	set(value):
		variants = value
		set_style(_style)

var _style := 0

func _ready() -> void:
	set_style(_style)

func set_style(style: int) -> void:
	_style = style
	var selected := variants.get(style, variants.get(0)) as Texture2D
	if selected == null:
		return
	texture = selected
	offset = Vector2(-floorf(texture.get_width() / 2.0), -texture.get_height())

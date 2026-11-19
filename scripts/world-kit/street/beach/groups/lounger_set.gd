@tool
class_name BeachLoungerSet
extends BeachPropGroup

@export var style: BeachLoungerSetStyle:
	set(value):
		if style == value:
			return
		if style != null:
			style.changed.disconnect(_refresh_appearance)
		style = value
		if style != null:
			style.changed.connect(_refresh_appearance)
		_refresh_appearance()

@onready var _lounger: BeachLounger = $Lounger
@onready var _umbrella: BeachUmbrella = $Umbrella

func _ready() -> void:
	super._ready()
	_refresh_appearance()

func apply_placement_style(profile: Resource) -> void:
	if profile is BeachLoungerSetStyle:
		style = profile

func _refresh_appearance() -> void:
	if not is_node_ready() or style == null:
		return
	_lounger.set_appearance(style.lounger_style, style.fabric_color, style.lounger_frame_color)
	_umbrella.set_appearance(style.umbrella_style, style.fabric_color, style.trim_color)

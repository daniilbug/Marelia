@tool
class_name BeachLifeguardStation
extends BeachPropGroup

@export var style: BeachLifeguardStationStyle:
	set(value):
		if style == value:
			return
		if style != null:
			style.changed.disconnect(_refresh_appearance)
		style = value
		if style != null:
			style.changed.connect(_refresh_appearance)
		_refresh_appearance()

@onready var _tower: BeachLifeguardTower = $Tower
@onready var _stand: BeachLifebuoyStand = $LifebuoyStand

func _ready() -> void:
	super._ready()
	_refresh_appearance()

func apply_placement_style(profile: Resource) -> void:
	if profile is BeachLifeguardStationStyle:
		style = profile

func _refresh_appearance() -> void:
	if not is_node_ready() or style == null:
		return
	_tower.set_appearance(style.tower_style, style.tower_color, style.lifebuoy_color)
	_stand.set_appearance(style.stand_style, style.stand_color, style.lifebuoy_color)

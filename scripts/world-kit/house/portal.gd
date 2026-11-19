@tool
class_name HousePortal
extends LevelTransition

const DEFAULT_VARIANTS := preload("res://assets/world-kit/house/door-variants/exterior.tres")

@export var door_variants: HouseDoorVariants = DEFAULT_VARIANTS
var style := HouseDoorStyle.new()

var _opening_wall: HouseWall

func _ready() -> void:
	_refresh_art()

func choose_style(seed_value: int) -> HouseDoorStyle:
	return door_variants.choose_style(seed_value) if door_variants != null else null

func set_appearance(profile: HouseDoorStyle, seed_value := -1, override_variants: HouseDoorVariants = null) -> void:
	style = profile
	if seed_value >= 0:
		var art := HouseDoorVariants.choose_design([override_variants, door_variants, DEFAULT_VARIANTS], seed_value, profile.style)
		if art != null:
			style = HouseDoorStyle.create(profile.style, profile.color, art)
	_refresh_art()

func set_opening_wall(wall: HouseWall) -> void:
	_opening_wall = wall
	_refresh_art()

func get_opening_rect(bottom_center: Vector2) -> Vector4:
	var size := style.get_design().get_opening_size()
	return Vector4(bottom_center.x - size.x / 2.0, bottom_center.y - size.y, size.x, size.y)

func _refresh_art() -> void:
	if is_node_ready():
		style.apply_art($Sprite)
		if is_instance_valid(_opening_wall):
			_opening_wall.opening_size = style.get_design().get_opening_size()

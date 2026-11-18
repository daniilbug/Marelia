@tool
class_name StreetDrinkingFountain
extends StreetProp

enum Style { CLASSIC }

@export_group("Design")
@export var style: Style = Style.CLASSIC:
	set(value):
		style = value
		_refresh_appearance()

@export_group("Material colors")
@export_color_no_alpha var tap_color: Color:
	get:
		return support_color
	set(value):
		support_color = value

@export_group("Water")
@export_range(0.0, 4.0, 0.1) var animation_speed := 1.0:
	set(value):
		animation_speed = clampf(value, 0.0, 4.0)

var _elapsed := 0.0

func _validate_property(property: Dictionary) -> void:
	super._validate_property(property)
	# The second material is exposed and saved as Tap Color for this prop.
	if property.name == "support_color":
		property.usage = PROPERTY_USAGE_NONE

func _get_design_index() -> int:
	return style

func _refresh_appearance() -> void:
	super._refresh_appearance()
	if not is_node_ready():
		return
	var design := get_current_design() as StreetFountainDesign
	var sprite := $Sprite as Sprite2D
	sprite.hframes = maxi(design.frames, 1) if design != null else 1
	sprite.vframes = 1
	sprite.frame = 0
	_elapsed = 0.0

func _process(delta: float) -> void:
	var design := get_current_design() as StreetFountainDesign
	if design == null or design.frames <= 1 or design.fps <= 0.0:
		return
	_elapsed = fposmod(_elapsed + delta * animation_speed, design.frames / design.fps)
	$Sprite.frame = int(floor(_elapsed * design.fps + 0.00001)) % design.frames

func _get_configuration_warnings() -> PackedStringArray:
	var warnings := super._get_configuration_warnings()
	for design in designs:
		if not design is StreetFountainDesign:
			warnings.append("Assign a fountain design with animation frames and FPS.")
		elif design.texture != null and (design.frames < 1 or design.texture.get_width() % maxi(design.frames, 1) != 0):
			warnings.append("The fountain texture must contain equally sized horizontal frames.")
	return warnings

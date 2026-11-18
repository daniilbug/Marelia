@tool
class_name StreetPropDesign
extends Resource

@export var texture: Texture2D
## Red channel: 0 fixed details, 1 body, 2 metal support.
@export var material_mask: Texture2D
@export_color_no_alpha var source_body_color := Color.WHITE
@export_color_no_alpha var source_support_color := Color.WHITE
@export var origin := Vector2.ZERO
@export var footprint := Vector2.ZERO
## Optional authored shape; an empty field uses a rectangle of Footprint size.
@export var footprint_shape: Shape2D
@export_range(-180.0, 180.0, 0.1, "radians_as_degrees") var footprint_rotation := 0.0
@export var occlusion_rect := Rect2()

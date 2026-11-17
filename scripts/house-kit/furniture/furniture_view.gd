@tool
class_name FurnitureView
extends Resource

## One approved view. Textures are shared; instance colors and shapes are not.
@export var albedo: Texture2D
@export var material_mask: Texture2D
## Approved full-color artwork for previews.
@export var approved_preview: Texture2D
@export var origin := Vector2.ZERO
@export var footprint := Vector2.ZERO
@export_range(1, 64) var frames := 1
@export_range(0.0, 60.0) var fps := 0.0

func get_frame_size() -> Vector2:
	return Vector2(albedo.get_width() / float(frames), albedo.get_height()) if albedo else Vector2.ZERO

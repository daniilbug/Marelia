@tool
class_name HouseFacadeFloor
extends Node2D

## The opening is (x, y, width, height) relative to the wall's top-left corner.
func set_appearance(profile: HouseFacadeStyle, size: Vector2, opening: Vector4) -> void:
	var wall := $Wall as Sprite2D
	var material := HouseArt.apply(wall, HouseArt.FACADES[profile.facade_style], {"plaster_color": profile.facade_color, "stone_color": profile.facade_color}, true)
	wall.position = Vector2(-size.x / 2.0, -size.y)
	wall.region_enabled = true
	wall.region_rect = Rect2(Vector2.ZERO, size)
	HouseArt.set_parameter(material, &"opening_a", opening)
	var window_art: String = ["window_louvered", "window_panelled", "window_arched"][profile.window_style] + ("_closed" if profile.shutters_closed else "_open")
	var window_colors := {"wood_color": profile.frame_color, "paint_color": profile.shutter_color}
	for side in 2:
		var window := get_node(["LeftWindow", "RightWindow"][side]) as Sprite2D
		HouseArt.apply(window, window_art, window_colors)
		window.position = Vector2(size.x * [-0.28, 0.28][side] - window.texture.get_width() / 2.0, -size.y + 5)

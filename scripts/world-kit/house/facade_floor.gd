@tool
class_name HouseFacadeFloor
extends Node2D

func apply_style(facade: HouseFacade, index: int) -> void:
	var width := facade.house_width
	var height := facade.wall_height
	position = Vector2(0, -height * index)
	var wall := $Wall as Sprite2D
	var material := HouseArt.apply(wall, ["facade_plaster", "facade_fieldstone", "facade_limestone"][facade.facade_style], {"plaster_color": facade.facade_color, "stone_color": facade.facade_color}, true)
	wall.position = Vector2(-width / 2.0, -height)
	wall.region_enabled = true
	wall.region_rect = Rect2(0, 0, width, height)
	var has_balcony := index > 0 and facade.floors[index].balcony
	var door_y: float = facade.get_node("Entrance").position.y if index == 0 else 0.0
	HouseArt.set_parameter(material, &"opening_a", Vector4(width / 2.0 - 12, height + door_y - 28, 24, 28) if index == 0 or has_balcony else Vector4.ZERO)
	for side in 2:
		var window := get_node(["LeftWindow", "RightWindow"][side]) as Sprite2D
		HouseArt.apply(window, ["window_louvered", "window_panelled", "window_arched"][facade.window_style] + ("_closed" if facade.shutters_closed else "_open"), {"wood_color": facade.frame_color, "paint_color": facade.shutter_color})
		window.position = Vector2(width * [-0.28, 0.28][side] - window.texture.get_width() / 2.0, -height + 5)

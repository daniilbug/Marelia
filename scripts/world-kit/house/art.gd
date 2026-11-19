@tool
class_name HouseArt
extends RefCounted

const SHADER = preload("res://assets/world-kit/house/shaders/house_palette.gdshader")
const ROOT := "res://assets/world-kit/house/sprites/"
const FACADES := ["facade_plaster", "facade_fieldstone", "facade_limestone", "facade_plaster_vine", "facade_fieldstone_vine"]
const FLOORS := ["floor_wood", "floor_terracotta", "floor_ornament", "floor_wood_narrow", "floor_wood_chevron", "floor_wood_basket", "floor_tile_checker", "floor_tile_octagon", "floor_tile_maiolica", "plinth_stone"]
const WALLS := ["facade_plaster", "wallpaper_striped", "wallpaper_botanical", "facade_fieldstone", "facade_limestone"]

static func apply(target: CanvasItem, stem: String, colors: Dictionary = {}, tiled := false) -> ShaderMaterial:
	var texture := load(ROOT + stem + "_albedo.png") as Texture2D
	var mask := load(ROOT + stem + "_materials.png") as Texture2D
	return apply_textures(target, texture, mask, colors, tiled)

static func apply_textures(target: CanvasItem, texture: Texture2D, mask: Texture2D, colors: Dictionary, tiled := false) -> ShaderMaterial:
	if target is Sprite2D:
		target.texture = texture
		target.centered = false
	elif target is Polygon2D:
		target.texture = texture
	target.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	target.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED if tiled else CanvasItem.TEXTURE_REPEAT_DISABLED
	var material := target.material as ShaderMaterial
	if material == null or material.shader != SHADER:
		material = ShaderMaterial.new()
		material.shader = SHADER
		material.resource_local_to_scene = true
		target.material = material
	set_parameter(material, &"material_mask", mask)
	for key in colors:
		set_parameter(material, key, colors[key])
	return material

static func set_parameter(material: ShaderMaterial, name: StringName, value: Variant) -> void:
	if material.get_shader_parameter(name) != value:
		material.set_shader_parameter(name, value)

static func floor_colors(style: HouseRoomStyle) -> Dictionary:
	return {"wood_color": style.floor_color, "stone_color": style.floor_color, "roof_color": style.floor_color if style.floor_material == HouseRoomStyle.Floor.TERRACOTTA else Color("b8764e"), "paint_color": style.accent_color}

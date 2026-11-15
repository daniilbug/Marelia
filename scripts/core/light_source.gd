class_name LightSource
extends Node2D

@export var lighting_enabled := true:
	set(value):
		lighting_enabled = value
		if is_node_ready():
			_apply_light_state()

@export var is_turned_on := true:
	set(value):
		is_turned_on = value
		if is_node_ready():
			_apply_light_state()

@export var light_sources: Array[Light2D] = []
@export var glow_sprites: Array[CanvasItem] = []
@export_range(0.0, 1.0) var unlit_brightness := 0.35

var _base_enabled: Array[bool] = []
var _glow_colors: Array[Color] = []

func _enter_tree() -> void:
	set_multiplayer_authority(1, true)
	add_to_group("saveable")

func _ready() -> void:
	for light in light_sources:
		_base_enabled.append(light.enabled if light != null else false)
	for glow in glow_sprites:
		_glow_colors.append(glow.self_modulate if glow != null else Color.WHITE)
	_apply_light_state()

func is_light_active() -> bool:
	return lighting_enabled and is_turned_on

func _apply_light_state() -> void:
	var active := is_light_active()
	for index in light_sources.size():
		var light := light_sources[index]
		if is_instance_valid(light):
			light.visible = active
			light.enabled = _base_enabled[index] and active
	for index in glow_sprites.size():
		if is_instance_valid(glow_sprites[index]):
			var brightness := 1.0 if active else unlit_brightness
			glow_sprites[index].self_modulate = _glow_colors[index] * Color(brightness, brightness, brightness, 1)

func get_save_data() -> Dictionary:
	return {"is_turned_on": is_turned_on, "lighting_enabled": lighting_enabled}

func apply_save_data(data: Dictionary) -> void:
	SaveGraph.apply_fields(self, get_save_data().keys(), data)

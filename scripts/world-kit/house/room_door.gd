@tool
class_name HouseRoomDoor
extends "res://scripts/core/door.gd"

const DEFAULT_VARIANTS := preload("res://assets/world-kit/house/door-variants/interior.tres")

## An empty override uses the fallback catalogue.
@export var door_variants: HouseDoorVariants:
	set(value):
		door_variants = value
		_refresh_art()

var _fallback_variants: HouseDoorVariants
var _appearance := HouseDoorStyle.new()
var _variant_seed := 0

func _ready() -> void:
	state_changed.connect(_show_state)
	_refresh_art()
	super._ready()
	# Initial state travels with the lazy level. Only later changes use RPCs,
	# so a late peer never receives a synchronizer path before the level exists.
	if not Engine.is_editor_hint():
		state_changed.connect(_broadcast_state)

func set_fallback_variants(variants: HouseDoorVariants) -> void:
	_fallback_variants = variants
	_refresh_art()

func set_appearance(profile: HouseDoorStyle, seed_value := 0) -> void:
	_appearance.style = profile.style
	_appearance.color = profile.color
	_variant_seed = seed_value
	_refresh_art()

func _refresh_art() -> void:
	if not is_node_ready():
		return
	var art := HouseDoorVariants.choose_design([door_variants, _fallback_variants, DEFAULT_VARIANTS], _variant_seed, _appearance.style, true)
	_appearance.design = art if art != null else HouseDoorStyle.SINGLE_DESIGNS[_appearance.style]
	_appearance.apply_art($Closed)
	_appearance.apply_art($Open, true)

func _broadcast_state(open: bool) -> void:
	if multiplayer.is_server():
		_receive_state.rpc(open)

@rpc("authority", "reliable")
func _receive_state(open: bool) -> void:
	is_open = open

func _show_state(open: bool) -> void:
	$Closed.visible = not open
	$Open.visible = open
	$TransparencyArea/Shape.set_deferred("disabled", open)
	$TransparencyArea/OpenLeaf.set_deferred("disabled", not open)

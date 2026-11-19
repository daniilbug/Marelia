class_name CharacterSprite
extends Sprite2D

const SWIM_PHASE_COUNT := 4
const DEFAULT_SKIN_TONE := 1
const SKIN_TONES: Array[Color] = [
	Color("f4d3af"), Color("ecc295"), Color("d79b6f"),
	Color("b9754c"), Color("885233"), Color("633d2c"),
]

# Every texture uses the same 4 x 10 atlas and the same 12 x 20 frame origin.
const HAIR_TEXTURES = [
	preload("res://assets/sprites/characters/hair_0.png"),
	preload("res://assets/sprites/characters/hair_1.png"),
	preload("res://assets/sprites/characters/hair_2.png"),
	preload("res://assets/sprites/characters/hair_3.png"),
	preload("res://assets/sprites/characters/hair_4.png"),
	preload("res://assets/sprites/characters/hair_5.png"),
	preload("res://assets/sprites/characters/hair_6.png"),
	preload("res://assets/sprites/characters/hair_7.png"),
	preload("res://assets/sprites/characters/hair_8.png"),
	preload("res://assets/sprites/characters/hair_9.png"),
	preload("res://assets/sprites/characters/hair_10.png"),
	preload("res://assets/sprites/characters/hair_11.png"),
	preload("res://assets/sprites/characters/hair_12.png"),
	preload("res://assets/sprites/characters/hair_13.png"),
	preload("res://assets/sprites/characters/hair_14.png"),
	preload("res://assets/sprites/characters/hair_15.png"),
	preload("res://assets/sprites/characters/hair_16.png"),
	preload("res://assets/sprites/characters/hair_17.png"),
	preload("res://assets/sprites/characters/hair_18.png"),
	preload("res://assets/sprites/characters/hair_19.png"),
]
const HAIR_COLORS: Array[Color] = [
	Color("302b30"), # Soft black.
	Color("493428"), # Dark brown.
	Color("785039"), # Brown.
	Color("955c40"), # Chestnut.
	Color("9d4d32"), # Auburn.
	Color("bd753c"), # Copper.
	Color("a48250"), # Dark blonde.
	Color("c7a368"), # Golden blonde.
	Color("dec58f"), # Light blonde.
	Color("aaa28d"), # Ash blonde.
	Color("969594"), # Gray.
	Color("d0cdcb"), # Silver.
]
const TOP_TEXTURES = [
	preload("res://assets/sprites/characters/top_0.png"),
	preload("res://assets/sprites/characters/top_1.png"),
	preload("res://assets/sprites/characters/top_2.png"),
	preload("res://assets/sprites/characters/top_3.png"),
	preload("res://assets/sprites/characters/top_4.png"),
	preload("res://assets/sprites/characters/top_5.png"),
	preload("res://assets/sprites/characters/top_6.png"),
	preload("res://assets/sprites/characters/top_7.png"),
	preload("res://assets/sprites/characters/top_8.png"),
	preload("res://assets/sprites/characters/top_9.png"),
	preload("res://assets/sprites/characters/top_10.png"),
	preload("res://assets/sprites/characters/top_11.png"),
	preload("res://assets/sprites/characters/top_12.png"),
	preload("res://assets/sprites/characters/top_13.png"),
	preload("res://assets/sprites/characters/top_14.png"),
	preload("res://assets/sprites/characters/top_15.png"),
	preload("res://assets/sprites/characters/top_16.png"),
	preload("res://assets/sprites/characters/top_17.png"),
	preload("res://assets/sprites/characters/top_18.png"),
	preload("res://assets/sprites/characters/top_19.png"),
]
const PANTS_TEXTURES = [
	preload("res://assets/sprites/characters/pants_0.png"),
	preload("res://assets/sprites/characters/pants_1.png"),
	preload("res://assets/sprites/characters/pants_2.png"),
	preload("res://assets/sprites/characters/pants_3.png"),
	preload("res://assets/sprites/characters/pants_4.png"),
	preload("res://assets/sprites/characters/pants_5.png"),
	preload("res://assets/sprites/characters/pants_6.png"),
	preload("res://assets/sprites/characters/pants_7.png"),
	preload("res://assets/sprites/characters/pants_8.png"),
	preload("res://assets/sprites/characters/pants_9.png"),
	preload("res://assets/sprites/characters/pants_10.png"),
	preload("res://assets/sprites/characters/pants_11.png"),
	preload("res://assets/sprites/characters/pants_12.png"),
	preload("res://assets/sprites/characters/pants_13.png"),
	preload("res://assets/sprites/characters/pants_14.png"),
	preload("res://assets/sprites/characters/pants_15.png"),
	preload("res://assets/sprites/characters/pants_16.png"),
	preload("res://assets/sprites/characters/pants_17.png"),
	preload("res://assets/sprites/characters/pants_18.png"),
	preload("res://assets/sprites/characters/pants_19.png"),
]

# Shared fabric colors; each garment has its own independent shader material.
const CLOTHING_COLORS: Array[Color] = [
	Color("e6dfcd"), # Off-white.
	Color("2d3038"), # Black.
	Color("555964"), # Graphite.
	Color("33435f"), # Navy.
	Color("466c9a"), # Denim blue.
	Color("47644d"), # Forest green.
	Color("7a7b4d"), # Olive.
	Color("bca77f"), # Sand.
	Color("ab8054"), # Camel.
	Color("aa624c"), # Rust.
	Color("7f3d4d"), # Burgundy.
	Color("b45252"), # Brick red.
	Color("bd889c"), # Muted pink.
	Color("9784ae"), # Lavender.
	Color("4f8886"), # Teal.
	Color("86a9be"), # Light blue.
	Color("c8bba2"), # Cream.
	Color("adb3ba"), # Silver gray.
]

@export_group("Swimming")
@export var swim_sprite: Sprite2D
@export var swim_hair: Sprite2D
@export var swimsuit_atlas: Texture2D

@onready var _hair: Sprite2D = $Hair
@onready var _top: Sprite2D = $Top
@onready var _pants: Sprite2D = $Pants
@onready var _bare_torso_atlas: Texture2D = swim_sprite.texture if swim_sprite != null else null


func _ready() -> void:
	# Characters and slots must never share dye uniforms, including NPCs.
	for layer in [self, _hair, _top, _pants]:
		layer.material = layer.material.duplicate()
	if swim_sprite != null:
		swim_sprite.material = swim_sprite.material.duplicate()
	if swim_sprite != null and swim_hair != null:
		swim_hair.material = _hair.material
		swim_sprite.frame_changed.connect(_sync_swim_hair)
		_sync_swim_hair()
	frame_changed.connect(_sync_layer_frames)
	_sync_layer_frames()

func set_swimming(swimming: bool) -> void:
	if swim_sprite == null:
		return
	visible = not swimming
	swim_sprite.visible = swimming

func set_swim_frame(row: int, moving: bool, phase: int) -> void:
	if swim_sprite != null:
		var column := phase if moving else SWIM_PHASE_COUNT + phase
		swim_sprite.frame_coords = Vector2i(column, row)

func _sync_swim_hair() -> void:
	# The baked swim frames lower the head by one pixel in phases 2 and 3.
	var coords := swim_sprite.frame_coords
	var hair_height := 12.0 if coords.x % SWIM_PHASE_COUNT >= 2 else 13.0
	swim_hair.position.y = -hair_height
	swim_hair.region_rect = Rect2(0, coords.y * 20, 12, hair_height)

func set_appearance(
	hair_id: int, top_id: int, pants_id: int, hair_color_id: int = 2,
	top_color_id: int = 4, pants_color_id: int = 3, wears_swimsuit := false
) -> void:
	_hair.texture = HAIR_TEXTURES[clampi(hair_id, 0, HAIR_TEXTURES.size() - 1)]
	(_hair.material as ShaderMaterial).set_shader_parameter(
		"hair_color", HAIR_COLORS[clampi(hair_color_id, 0, HAIR_COLORS.size() - 1)]
	)
	_top.texture = TOP_TEXTURES[clampi(top_id, 0, TOP_TEXTURES.size() - 1)]
	_pants.texture = PANTS_TEXTURES[clampi(pants_id, 0, PANTS_TEXTURES.size() - 1)]
	(_top.material as ShaderMaterial).set_shader_parameter(
		"clothing_color", CLOTHING_COLORS[clampi(top_color_id, 0, CLOTHING_COLORS.size() - 1)]
	)
	(_pants.material as ShaderMaterial).set_shader_parameter(
		"clothing_color", CLOTHING_COLORS[clampi(pants_color_id, 0, CLOTHING_COLORS.size() - 1)]
	)
	_sync_layer_frames()
	if swim_sprite != null:
		swim_sprite.texture = swimsuit_atlas if wears_swimsuit else _bare_torso_atlas
	if swim_hair != null:
		swim_hair.texture = _hair.texture

func set_skin_tone(tone_id: int) -> void:
	var tone := SKIN_TONES[clampi(tone_id, 0, SKIN_TONES.size() - 1)]
	for layer in [self, _top, _pants, swim_sprite]:
		if layer != null:
			(layer.material as ShaderMaterial).set_shader_parameter("skin_color", tone)

func _sync_layer_frames() -> void:
	_hair.frame = frame
	_top.frame = frame
	_pants.frame = frame

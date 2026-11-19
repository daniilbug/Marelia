class_name CharacterCreation
extends Control

signal back_requested
signal luggage_requested

const SPRITE := preload("res://scenes/core/character_sprite.tscn")
const HAIRSTYLES := [0, 3, 7, 11, 13, 19]
const HAIR_SWATCHES := [0, 1, 2, 3, 7, 10]
# Garments have fixed fabric colors, like the starting items in the world wardrobe.
const TOPS := [
	[2, 5, &"ui.character_creation.garment.shirt"],
	[0, 0, &"ui.character_creation.garment.tshirt"],
	[3, 7, &"ui.character_creation.garment.jacket"],
	[5, 3, &"ui.character_creation.garment.sweater"],
	[8, 9, &"ui.character_creation.garment.vest"],
	[12, 4, &"ui.character_creation.garment.tank"],
	[18, 6, &"ui.character_creation.garment.coat"],
]
const BOTTOMS := [
	[0, 3, &"ui.character_creation.garment.trousers"],
	[2, 2, &"ui.character_creation.garment.slim_trousers"],
	[6, 4, &"ui.character_creation.garment.jeans"],
	[8, 7, &"ui.character_creation.garment.shorts"],
	[11, 6, &"ui.character_creation.garment.cropped_trousers"],
	[17, 10, &"ui.character_creation.garment.skirt"],
]

var character_name: String

var _gender := Player.Gender.MALE
var _skin_tone_id := CharacterSprite.DEFAULT_SKIN_TONE
var _hair_id := 7
var _hair_color_id := 2
var _top_index := 0
var _bottom_index := 0
var _hair_thumbnails: Array[CharacterSprite] = []

@onready var _spread: Control = %Spread
@onready var _portrait: CharacterSprite = %Portrait
@onready var _tabs: Array[Button] = [%DetailsTab, %HairTab, %ClothingTab]
@onready var _pages: Array[Control] = [%Details, %Hair, %Clothing]

func _ready() -> void:
	%CharacterName.text = character_name
	resized.connect(_fit_spread)
	_fit_spread()
	for i in _tabs.size():
		_tabs[i].pressed.connect(_show_tab.bind(i))
	%Male.pressed.connect(_set_gender.bind(Player.Gender.MALE))
	%Female.pressed.connect(_set_gender.bind(Player.Gender.FEMALE))
	_build_swatches(%SkinSwatches, CharacterSprite.SKIN_TONES, [0, 1, 2, 3, 4, 5], _skin_tone_id, _set_skin_tone)
	_build_hairstyles()
	_build_swatches(%HairSwatches, CharacterSprite.HAIR_COLORS, HAIR_SWATCHES, _hair_color_id, _set_hair_color)
	%TopPrev.pressed.connect(_change_top.bind(-1))
	%TopNext.pressed.connect(_change_top.bind(1))
	%BottomPrev.pressed.connect(_change_bottom.bind(-1))
	%BottomNext.pressed.connect(_change_bottom.bind(1))
	%Back.pressed.connect(back_requested.emit)
	%Continue.pressed.connect(luggage_requested.emit)
	_update_garments()
	_update_appearance()
	_tabs[0].grab_focus()

func _unhandled_key_input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		back_requested.emit()

func _fit_spread() -> void:
	var design_size := _spread.size
	var factor := minf(size.x / design_size.x, size.y / design_size.y)
	_spread.scale = Vector2.ONE * factor
	_spread.position = ((size - design_size * factor) * 0.5).round()

func _show_tab(index: int) -> void:
	for i in _pages.size():
		_pages[i].visible = i == index

func _set_gender(value: Player.Gender) -> void:
	_gender = value

func _set_skin_tone(value: int) -> void:
	_skin_tone_id = value
	_update_appearance()

func _set_hairstyle(value: int) -> void:
	_hair_id = value
	_style_sprite(_portrait, value)

func _set_hair_color(value: int) -> void:
	_hair_color_id = value
	_update_appearance()

func _build_swatches(row: HBoxContainer, colors: Array[Color], ids: Array, selected: int, select: Callable) -> void:
	var group := ButtonGroup.new()
	for id: int in ids:
		var button := _add_choice(row, Vector2(32, 32), &"Swatch", group, id == selected)
		var fill := StyleBoxFlat.new()
		fill.bg_color = colors[id]
		var selection := button.get_theme_stylebox(&"pressed").duplicate() as StyleBoxFlat
		selection.bg_color = colors[id]
		button.add_theme_stylebox_override(&"normal", fill)
		button.add_theme_stylebox_override(&"hover", fill)
		button.add_theme_stylebox_override(&"pressed", selection)
		button.add_theme_stylebox_override(&"hover_pressed", selection)
		button.pressed.connect(select.bind(id))

func _build_hairstyles() -> void:
	var group := ButtonGroup.new()
	for id: int in HAIRSTYLES:
		var button := _add_choice(%HairStyles, Vector2(89, 79), &"SelectableTile", group, id == _hair_id)
		# Clip the shared front-facing sprite to its head, like a passport photo.
		var crop := Control.new()
		crop.position = Vector2(14, 7)
		crop.size = Vector2(60, 65)
		crop.clip_contents = true
		crop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(crop)
		var head := SPRITE.instantiate() as CharacterSprite
		head.position = Vector2(30, 100)
		head.scale = Vector2(5, 5)
		crop.add_child(head)
		_hair_thumbnails.append(head)
		button.pressed.connect(_set_hairstyle.bind(id))

func _add_choice(parent: Container, minimum_size: Vector2, variation: StringName, group: ButtonGroup, selected: bool) -> Button:
	var button := Button.new()
	button.custom_minimum_size = minimum_size
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.theme_type_variation = variation
	button.toggle_mode = true
	button.button_group = group
	button.button_pressed = selected
	parent.add_child(button)
	return button

func _change_top(step: int) -> void:
	_top_index = posmod(_top_index + step, TOPS.size())
	_update_garments()
	_update_appearance()

func _change_bottom(step: int) -> void:
	_bottom_index = posmod(_bottom_index + step, BOTTOMS.size())
	_update_garments()
	_update_appearance()

func _update_garments() -> void:
	var top: Array = TOPS[_top_index]
	var bottom: Array = BOTTOMS[_bottom_index]
	%TopName.text = top[2]
	%BottomName.text = bottom[2]
	%TopColor.color = CharacterSprite.CLOTHING_COLORS[top[1]]
	%BottomColor.color = CharacterSprite.CLOTHING_COLORS[bottom[1]]

func _update_appearance() -> void:
	_style_sprite(_portrait, _hair_id)
	for i in _hair_thumbnails.size():
		_style_sprite(_hair_thumbnails[i], HAIRSTYLES[i])

func _style_sprite(sprite: CharacterSprite, hairstyle: int) -> void:
	var top: Array = TOPS[_top_index]
	var bottom: Array = BOTTOMS[_bottom_index]
	sprite.set_appearance(hairstyle, top[0], bottom[0], _hair_color_id, top[1], bottom[1])
	sprite.set_skin_tone(_skin_tone_id)

func focus_continue() -> void:
	%Continue.grab_focus()

func get_appearance() -> Dictionary:
	var top: Array = TOPS[_top_index]
	var bottom: Array = BOTTOMS[_bottom_index]
	return {
		"gender": _gender, "skin_tone_id": _skin_tone_id,
		"hair_id": _hair_id, "hair_color_id": _hair_color_id,
		"top_id": top[0], "top_color_id": top[1],
		"pants_id": bottom[0], "pants_color_id": bottom[1],
	}

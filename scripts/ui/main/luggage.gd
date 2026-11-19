class_name Luggage
extends Control

signal back_requested
signal boarding_requested

const ITEM_CARD := preload("res://scenes/ui/main/luggage-item.tscn")
const ITEM_ATLAS := preload("res://assets/ui/main/luggage-items.png")
const ICON_SIZE := 42
const SLOT_ICON_SIZE := 72.0
const ATLAS_COLUMNS := 4
const CAPACITY := 4
# These stable IDs also define the order of the item sprites in the menu atlas.
const ITEM_IDS: Array[String] = [
	"language_textbook", "marelia_book", "repair_guide",
	"cash", "family_photo", "wine",
	"phrasebook", "wine_journal", "wrench",
	"clothes", "back_balm", "farming_book",
]

var _packed: Array[Button] = []

@onready var _layout: Control = %Layout
@onready var _items: GridContainer = %Items
@onready var _slots: GridContainer = %Slots
@onready var _atlas_image := ITEM_ATLAS.get_image()
@onready var _empty_slot := _atlas_texture(Rect2(0, 126, ICON_SIZE, ICON_SIZE))

func _ready() -> void:
	resized.connect(_fit_layout)
	_fit_layout()
	_build_items()
	_build_slots()
	%Back.pressed.connect(back_requested.emit)
	%Board.pressed.connect(boarding_requested.emit)
	_refresh()

func _unhandled_key_input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		back_requested.emit()

func focus_items() -> void:
	var card := _items.get_child(0) as Button if _packed.is_empty() else _packed[0]
	card.grab_focus()

func focus_boarding() -> void:
	%Board.grab_focus()

func _fit_layout() -> void:
	var design_size := _layout.size
	var factor := minf(size.x / design_size.x, size.y / design_size.y)
	_layout.scale = Vector2.ONE * factor
	_layout.position = ((size - design_size * factor) * 0.5).round()

func _build_items() -> void:
	for index in ITEM_IDS.size():
		var item := ITEM_IDS[index]
		var caption := StringName("ui.luggage.item." + item)
		var icon := _atlas_texture(Rect2(index % ATLAS_COLUMNS * ICON_SIZE,
			floori(float(index) / ATLAS_COLUMNS) * ICON_SIZE, ICON_SIZE, ICON_SIZE))
		var card := ITEM_CARD.instantiate() as Button
		card.name = item
		var card_icon := card.get_node("%Icon") as TextureRect
		card_icon.texture = icon
		# Align the visible pixels with the top of each item card.
		var bounds := _icon_bounds(icon)
		var padding := Vector2(ICON_SIZE * 0.5 - bounds.get_center().x, -bounds.position.y)
		card_icon.position += padding * (card_icon.size / float(ICON_SIZE))
		card.get_node("%Caption").text = caption
		card.pressed.connect(_toggle_item.bind(card))
		_items.add_child(card)

func _build_slots() -> void:
	var plain := StyleBoxEmpty.new()
	for index in CAPACITY:
		var button := Button.new()
		button.custom_minimum_size = Vector2(180, 82)
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		for state in [&"normal", &"hover", &"pressed", &"disabled"]:
			button.add_theme_stylebox_override(state, plain)
		button.pressed.connect(_unpack_slot.bind(index))
		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(icon)
		icon.set_anchors_preset(Control.PRESET_CENTER)
		_slots.add_child(button)

func _atlas_texture(region: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = ITEM_ATLAS
	texture.region = region
	return texture

func _icon_bounds(texture: AtlasTexture) -> Rect2:
	return Rect2(_atlas_image.get_region(Rect2i(texture.region)).get_used_rect())

func _toggle_item(card: Button) -> void:
	if card in _packed:
		_packed.erase(card)
	elif _packed.size() < CAPACITY:
		_packed.append(card)
	_refresh()

func _unpack_slot(index: int) -> void:
	if index >= _packed.size():
		return
	var card := _packed[index]
	_packed.remove_at(index)
	_refresh()
	card.grab_focus()

func _refresh() -> void:
	var count := _packed.size()
	for card: Button in _items.get_children():
		var selected := card in _packed
		card.set_pressed_no_signal(selected)
		card.disabled = count == CAPACITY and not selected
		card.get_node("%Icon").modulate.a = 0.55 if card.disabled else 1.0
	for index in _slots.get_child_count():
		var slot := _slots.get_child(index) as Button
		var filled := index < count
		slot.disabled = not filled
		var texture: AtlasTexture = _packed[index].get_node("%Icon").texture if filled else _empty_slot
		var icon := slot.get_node("Icon") as TextureRect
		icon.texture = texture
		var offset := -_icon_bounds(texture).get_center() * (SLOT_ICON_SIZE / ICON_SIZE)
		icon.offset_left = offset.x
		icon.offset_top = offset.y
		icon.offset_right = offset.x + SLOT_ICON_SIZE
		icon.offset_bottom = offset.y + SLOT_ICON_SIZE

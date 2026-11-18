@tool
class_name MainMenuCard
extends Button

@export_custom(PROPERTY_HINT_LOCALIZABLE_STRING, "") var title_key := "":
	set(value):
		title_key = value
		_update_content()
@export_custom(PROPERTY_HINT_LOCALIZABLE_STRING, "") var action_key := "":
	set(value):
		action_key = value
		_update_content()
@export var illustration: Texture2D:
	set(value):
		illustration = value
		_update_content()
@export var primary := false:
	set(value):
		primary = value
		_update_content()
@export var show_price := false:
	set(value):
		show_price = value
		_update_content()
@export_range(0, 1000000, 1, "or_greater") var price := 1:
	set(value):
		price = value
		_update_content()

func _ready() -> void:
	_update_content()
	if not Engine.is_editor_hint():
		mouse_entered.connect(grab_focus)

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_update_content()

func _update_content() -> void:
	if not is_node_ready():
		return
	$Content/Art.texture = illustration
	$Content/Body/Layout/Header/Price.visible = show_price
	$Content/Body/Layout/Header/Price/Amount.text = str(price)
	$Content/Body/Layout/Action.theme_type_variation = &"CardPrimaryAction" if primary else &"CardSecondaryAction"
	$Content/Body/Layout/Action/Row/Caption.theme_type_variation = &"PrimaryActionLabel" if primary else &"Label"
	$Content/Body/Layout/Action/Row/Arrow.self_modulate = Color("fff1d2") if primary else Color("553b2a")
	var heading := LocalizedText.render(StringName(title_key))
	var action := LocalizedText.render(StringName(action_key))
	$Content/Body/Layout/Header/Title.text = heading
	$Content/Body/Layout/Action/Row/Caption.text = action
	$Content/Body/Layout/Header/Price/Unit.text = LocalizedText.render(&"common.currency.maren", {}, price)
	accessibility_name = LocalizedText.render(&"ui.menu.card.accessibility", {"title": heading, "action": action})

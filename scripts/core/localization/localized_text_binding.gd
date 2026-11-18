@tool
class_name LocalizedTextBinding
extends Node

## Attach to a Label, Button, RichTextLabel or Label3D to keep its text live.
@export var target_path := NodePath("..")
@export var target_property: StringName = &"text"
@export var message: LocalizedText:
	set(value):
		if message != null and message.changed.is_connected(refresh):
			message.changed.disconnect(refresh)
		message = value
		if message != null:
			message.changed.connect(refresh)
		refresh()

func _ready() -> void:
	auto_translate_mode = AUTO_TRANSLATE_MODE_ALWAYS
	refresh()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		refresh()

func refresh() -> void:
	if not is_inside_tree():
		return
	var target := get_node_or_null(target_path)
	if target == null:
		return
	if target_property == &"text" and target.auto_translate_mode != AUTO_TRANSLATE_MODE_DISABLED:
		target.auto_translate_mode = AUTO_TRANSLATE_MODE_DISABLED
	var resolved := message.resolve() if message != null else ""
	if target.get(target_property) != resolved:
		target.set(target_property, resolved)

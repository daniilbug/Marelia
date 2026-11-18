@tool
class_name LocalizedText
extends Resource

## A language-independent message for UI, dialogue lines and game data.
## Keep this resource, rather than its resolved string, when the language can change.
@export_custom(PROPERTY_HINT_LOCALIZABLE_STRING, "") var key := "":
	set(value):
		key = value
		_notify_changed()
@export var parameters: Dictionary = {}:
	set(value):
		for child in parameters.values():
			if child is LocalizedText and child != self and child.changed.is_connected(_notify_changed):
				child.changed.disconnect(_notify_changed)
		parameters = value
		for child in parameters.values():
			if child is LocalizedText and child != self and not child.changed.is_connected(_notify_changed):
				child.changed.connect(_notify_changed)
		_notify_changed()
## -1 is a regular message; nonnegative values select a gettext plural form.
@export_range(-1, 1000000, 1, "or_greater") var plural_count := -1:
	set(value):
		plural_count = value
		_notify_changed()

var _notifying := false

static var _editor_domain: TranslationDomain

static func make(message_key: StringName, arguments: Dictionary = {}, count := -1) -> LocalizedText:
	var message := LocalizedText.new()
	message.key = String(message_key)
	message.parameters = arguments.duplicate()
	message.plural_count = count
	return message

func resolve() -> String:
	return render(StringName(key), parameters, plural_count)

func set_parameter(name: StringName, value: Variant) -> void:
	var updated := parameters.duplicate()
	updated[String(name)] = value
	parameters = updated

func _notify_changed() -> void:
	if _notifying:
		return
	_notifying = true
	emit_changed()
	_notifying = false

static func render(message_key: StringName, arguments: Dictionary = {}, count := -1, depth := 0) -> String:
	if message_key.is_empty():
		return ""
	if depth >= 16:
		push_error("Cyclic or overly nested localized message: %s" % message_key)
		return String(message_key)
	var plural_key := StringName(String(message_key) + ".plural")
	var translated: String = TranslationServer.translate_plural(message_key, plural_key, count) if count >= 0 else TranslationServer.translate(message_key)
	if Engine.is_editor_hint():
		var domain := _get_editor_domain()
		translated = domain.translate_plural(message_key, plural_key, count) if count >= 0 else domain.translate(message_key)
	var values := {}
	for name in arguments:
		var value: Variant = arguments[name]
		values[String(name)] = render(StringName(value.key), value.parameters, value.plural_count, depth + 1) if value is LocalizedText else value
	if count >= 0 and not values.has("count"):
		values["count"] = count
	return translated.format(values)

static func _get_editor_domain() -> TranslationDomain:
	# The 2D editor may disable the main domain while showing source keys.
	# An isolated native domain keeps tool previews readable without changing it.
	if _editor_domain == null:
		_editor_domain = TranslationDomain.new()
		for path in ProjectSettings.get_setting("internationalization/locale/translations", PackedStringArray()):
			var translation := load(path) as Translation
			if translation != null:
				_editor_domain.add_translation(translation)
	_editor_domain.set_locale_override(str(ProjectSettings.get_setting("internationalization/locale/test", "")))
	return _editor_domain

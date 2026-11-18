extends Node

## Shared entry point: L10n.text(), L10n.plural(), L10n.message(), L10n.bind().
## Languages are discovered from Godot's registered translations, without a code list.
const SETTINGS_PATH := "user://localization.cfg"

func _ready() -> void:
	var config := ConfigFile.new()
	var requested := TranslationServer.get_locale()
	if config.load(SETTINGS_PATH) == OK:
		requested = str(config.get_value("localization", "locale", requested))
	# An explicit Godot --language argument takes precedence over a saved preference.
	var arguments := OS.get_cmdline_args()
	var index := arguments.find("--language")
	if index >= 0 and index + 1 < arguments.size():
		requested = arguments[index + 1]
	if not set_locale(requested, false):
		set_locale(str(ProjectSettings.get_setting("internationalization/locale/fallback", "ru")), false)

func text(key: StringName, parameters: Dictionary = {}) -> String:
	return LocalizedText.render(key, parameters)

func plural(key: StringName, count: int, parameters: Dictionary = {}) -> String:
	assert(count >= 0, "Plural counts must be nonnegative")
	return LocalizedText.render(key, parameters, count)

func message(key: StringName, parameters: Dictionary = {}, count := -1) -> LocalizedText:
	return LocalizedText.make(key, parameters, count)

## Dynamic text updates on both language changes and message parameter changes.
func bind(target: Node, value: LocalizedText, property: StringName = &"text") -> LocalizedTextBinding:
	for child in target.get_children():
		if child is LocalizedTextBinding and child.target_path == NodePath("..") and child.target_property == property:
			child.message = value
			return child
	var binding := LocalizedTextBinding.new()
	binding.target_property = property
	binding.message = value
	target.add_child(binding)
	return binding

func available_locales() -> PackedStringArray:
	var locales := TranslationServer.get_loaded_locales()
	locales.sort()
	return locales

func locale_name(locale: String) -> String:
	for translation: Translation in TranslationServer.find_translations(locale, true):
		var name := String(translation.get_message(&"language.self_name"))
		if not name.is_empty():
			return name
	return locale

func get_locale() -> String:
	return _supported_locale(TranslationServer.get_locale())

## Regional locales, such as en_US, select their base language when necessary.
func set_locale(requested: String, persist := true) -> bool:
	var selected := _supported_locale(requested)
	if selected.is_empty():
		return false
	TranslationServer.set_locale(selected)
	if persist:
		var config := ConfigFile.new()
		config.set_value("localization", "locale", selected)
		var error := config.save(SETTINGS_PATH)
		if error != OK:
			push_warning("Could not save language preference: %d" % error)
	return true

func date_time(unix_time: int) -> LocalizedText:
	var date := Time.get_datetime_dict_from_unix_time(unix_time)
	return message(&"common.datetime", {
		"day": "%02d" % date.day, "month": "%02d" % date.month, "year": str(date.year),
		"hour": "%02d" % date.hour, "minute": "%02d" % date.minute,
	})

func _supported_locale(requested: String) -> String:
	var normalized := TranslationServer.standardize_locale(requested)
	var best := ""
	var best_score := 0
	for locale in available_locales():
		var score := TranslationServer.compare_locales(normalized, locale)
		if score > best_score:
			best = locale
			best_score = score
	return best

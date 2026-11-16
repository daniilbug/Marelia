@tool
class_name TransparencyArea
extends Area2D

## Main collision shape, directly editable on an instance without Editable Children.
@export var shape: Shape2D:
	set(value):
		shape = value
		if is_node_ready():
			$Shape.shape = shape
			update_configuration_warnings()

## Assign a sprite, or a group's root CanvasItem to fade all its children.
## One component owns each target's alpha. Use multiple shapes for a larger zone.
@export var targets: Array[CanvasItem] = []:
	set(value):
		if is_node_ready() and not Engine.is_editor_hint():
			_restore_targets()
		targets = value
		if is_node_ready():
			update_configuration_warnings()
			if not Engine.is_editor_hint():
				_refresh_state(true)

@export_range(0.0, 1.0, 0.05) var inside_alpha := 0.2:
	set(value):
		inside_alpha = clampf(value, 0.0, 1.0)
		if is_node_ready() and not Engine.is_editor_hint():
			_refresh_state(true)

## Zero switches opacity immediately.
@export_range(0.0, 5.0, 0.05, "or_greater") var transition_duration := 0.2

@export var enabled := true:
	set(value):
		enabled = value
		if is_node_ready() and not Engine.is_editor_hint():
			_refresh_state()

var _inside := false
var _tween: Tween

func _ready() -> void:
	$Shape.shape = shape
	set_physics_process(not Engine.is_editor_hint())
	if Engine.is_editor_hint():
		return
	body_entered.connect(_on_body_changed)
	body_exited.connect(_on_body_changed)
	_refresh_state(true)

func _physics_process(_delta: float) -> void:
	# Local-player assignment, teleporting or changing Level can happen while
	# bodies still overlap. Refreshing also handles spawning inside the shape.
	_refresh_state()

func _on_body_changed(_body: Node2D) -> void:
	_refresh_state()

func _refresh_state(force := false) -> void:
	var level := Level.find_level_node(self)
	var player := level.local_player if level != null else null
	var inside := enabled and monitoring and is_instance_valid(player) \
		and player.level_id == level.level_id and overlaps_body(player)
	if inside == _inside and not force:
		return
	_inside = inside
	_transition_to(inside_alpha if inside else 1.0)

func _transition_to(alpha: float) -> void:
	_stop_tween()
	for target in targets:
		if not is_instance_valid(target):
			continue
		if transition_duration <= 0.0:
			target.modulate.a = alpha
		else:
			if _tween == null:
				_tween = create_tween().set_parallel()
			_tween.tween_property(target, "modulate:a", alpha, transition_duration)

func _stop_tween() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null

func _restore_targets() -> void:
	_stop_tween()
	for target in targets:
		if is_instance_valid(target):
			target.modulate.a = 1.0

func _exit_tree() -> void:
	if not Engine.is_editor_hint():
		_restore_targets()

func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if targets.is_empty():
		warnings.append("Assign at least one CanvasItem to Targets.")
	if shape == null:
		warnings.append("Assign a Shape2D to Shape.")
	return warnings

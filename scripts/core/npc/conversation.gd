class_name NPCConversation
extends Node

## Owns an exclusive, server-authorized dialogue session. Content and UI subscribe
## to these signals; the core does not choose topics, choices, scores or presentation.
signal started(player: Player)
signal ended

@export var peer_id := 0:
	set(value):
		peer_id = value
		if is_node_ready():
			_sync_participant()

@onready var npc: NPC = get_parent()
var _participant: Player

func _ready() -> void:
	if multiplayer.is_server():
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	_sync_participant.call_deferred()

func participant() -> Player:
	var level := Level.find_level_node(npc)
	return level.get_player(peer_id) if level != null and peer_id > 0 else null

func _sync_participant() -> void:
	var current := participant()
	if current == _participant:
		return
	if is_instance_valid(_participant):
		_participant.is_world_input_blocked = false
		ended.emit()
	_participant = current
	if is_instance_valid(_participant):
		_participant.is_world_input_blocked = true
		started.emit(_participant)

func interact(player: Player) -> void:
	if not player.is_multiplayer_authority() or player.is_world_input_blocked or not can_talk_to(player):
		return
	if multiplayer.is_server():
		_begin(int(player.name))
	else:
		_request_begin.rpc_id(1)

func close() -> void:
	if multiplayer.is_server():
		_close_for(multiplayer.get_unique_id())
	else:
		_request_close.rpc_id(1)

@rpc("any_peer", "reliable")
func _request_begin() -> void:
	if multiplayer.is_server():
		_begin(multiplayer.get_remote_sender_id())

@rpc("any_peer", "reliable")
func _request_close() -> void:
	if multiplayer.is_server():
		_close_for(multiplayer.get_remote_sender_id())

func _begin(sender: int) -> void:
	var level := Level.find_level_node(npc)
	var player := level.get_player(sender)
	if peer_id != 0 or not can_talk_to(player) or player.is_world_input_blocked:
		return
	for other in level.get_children():
		if other is NPC and other.conversation.peer_id == sender:
			return
	npc.pause_for_conversation()
	peer_id = sender

func _close_for(sender: int) -> void:
	if sender == peer_id:
		_end()

func _end() -> void:
	if peer_id == 0:
		return
	npc.resume_after_conversation()
	peer_id = 0

func _physics_process(_delta: float) -> void:
	if peer_id == 0:
		return
	_sync_participant()
	if multiplayer.is_server() and not can_talk_to(participant(), true):
		_end()

func _on_peer_disconnected(sender: int) -> void:
	_close_for(sender)

func _exit_tree() -> void:
	if is_instance_valid(_participant):
		_participant.is_world_input_blocked = false

func can_talk_to(player: Player, ongoing := false) -> bool:
	if not is_instance_valid(player) or player is NPC or player.is_queued_for_deletion() \
		or player.level_id != npc.level_id or npc.is_queued_for_deletion():
		return false
	if not ongoing and (peer_id != 0 or npc.state == NPC.State.TALKING):
		return false
	if not npc.interaction_area.overlaps_area(player.interaction_area):
		return false
	var excluded: Array[RID] = [npc.get_rid(), player.get_rid()]
	for actor: Player in [npc, player]:
		if not actor.is_sitting:
			continue
		var seat := actor.seated_seat
		if not is_instance_valid(seat):
			for candidate: Seat in Level.find_level_node(npc).find_children("*", "Seat", true, false):
				if candidate.occupant_name == actor.name:
					seat = candidate
					break
		if is_instance_valid(seat):
			for body in seat.interaction_occlusion_exceptions:
				if is_instance_valid(body):
					excluded.append(body.get_rid())
	var offset := Vector2(0, -4) * npc._world_scale
	var ray := PhysicsRayQueryParameters2D.create(npc.global_position + offset, player.global_position + offset, 1, excluded)
	return npc.get_world_2d().direct_space_state.intersect_ray(ray).is_empty()

static func nearest(player: Player, areas: Array[Area2D]) -> NPCConversation:
	var nearest_npc: NPC
	for area in areas:
		var candidate := area.get_parent() as NPC
		if candidate == null or not candidate.conversation.can_talk_to(player):
			continue
		if nearest_npc == null or player.global_position.distance_squared_to(candidate.global_position) < player.global_position.distance_squared_to(nearest_npc.global_position):
			nearest_npc = candidate
	return nearest_npc.conversation if nearest_npc != null else null

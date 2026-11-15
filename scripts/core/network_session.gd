class_name NetworkSession
extends Node

signal started
signal failed(error: Error)
signal disconnected

func _ready() -> void:
	multiplayer.connected_to_server.connect(started.emit)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func start_local() -> void:
	close()
	started.emit()

func host(port := 7777, max_clients := 16) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(port, max_clients)
	if error != OK:
		failed.emit(error)
		return error
	close()
	multiplayer.multiplayer_peer = peer
	started.emit()
	return OK

func join(address: String, port := 7777) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(address, port)
	if error != OK:
		failed.emit(error)
		return error
	close()
	multiplayer.multiplayer_peer = peer
	return OK

func close() -> void:
	var peer := multiplayer.multiplayer_peer
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	if peer != null:
		peer.close()

func _on_connection_failed() -> void:
	close()
	failed.emit(ERR_CANT_CONNECT)

func _on_server_disconnected() -> void:
	close()
	disconnected.emit()

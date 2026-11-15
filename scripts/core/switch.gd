class_name Switch
extends Interactable

signal on_switch()


func interact(_player: Player) -> void:
	on_switch.emit()

extends RefCounted
class_name FactionController

var faction: int
var board
var ui

func on_settlement_selected(_settlement: Settlement) -> void:
	pass

func setup(_faction: int, _board, _ui) -> void:
	faction = _faction
	board = _board
	ui = _ui

func start_turn() -> void:
	pass

func get_action_list() -> Array:
	return []

func handle_action(_action_id: String) -> void:
	pass

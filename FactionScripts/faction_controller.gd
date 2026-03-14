extends RefCounted
class_name FactionController

var faction: int
var board
var ui

func setup(_faction: int, _board, _ui) -> void:
	faction = _faction
	board = _board
	ui = _ui

func start_turn() -> void:
	pass

func end_turn() -> void:
	pass

func get_action_list() -> Array:
	return []

func on_settlement_selected(_settlement: Settlement) -> void:
	pass

func on_empty_board_clicked() -> void:
	pass

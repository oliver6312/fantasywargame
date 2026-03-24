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

func handle_action(_action_id: String) -> void:
	pass

func on_settlement_selected(_settlement: Settlement) -> void:
	pass

func can_start_move_from_settlement(_settlement: Settlement) -> bool:
	return true

func after_successful_move(_source: Settlement, _target: Settlement) -> void:
	pass

func is_in_war_meeting() -> bool:
	return false

func finish_war_meeting() -> void:
	pass

func is_in_movement_mode() -> bool:
	return false

func can_select_settlement_freely() -> bool:
	return true

func is_in_special_selection_mode() -> bool:
	return false

func cancel_current_mode() -> void:
	pass

func can_remove_infiltration() -> bool:
	return false

func remove_infiltration_from_settlement(_settlement: Settlement) -> void:
	pass

func can_delete_buildings() -> bool:
	return false

func delete_building(_settlement: Settlement, _slot_index: int) -> void:
	pass

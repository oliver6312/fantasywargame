extends FactionController
class_name OrcController

const ORC_FACTION := Faction.Type.ORC

const ACTION_MOVE := "move"
const ACTION_RAID := "raid"
const ACTION_BRUTALIZE := "brutalize"

const MODE_NONE := ""
const MODE_RAID := "raid"
const MODE_BRUTALIZE := "brutalize"

const BUILDING_GRUESOME_EFFIGY := "Gruesome Effigy"

var actions_remaining: int = 4
var mode: String = MODE_NONE

func start_turn() -> void:
	actions_remaining = 4
	mode = MODE_NONE
	_refresh_ui()
	print("Orc turn begins with 4 actions")

func end_turn() -> void:
	pass

func is_in_war_meeting() -> bool:
	return false

func is_in_special_selection_mode() -> bool:
	return mode != MODE_NONE

func cancel_current_mode() -> void:
	if mode == MODE_NONE:
		return

	mode = MODE_NONE
	print("Orc action cancelled.")
	_refresh_ui()

func get_action_list() -> Array:
	var actions: Array = []

	actions.append(_make_action(ACTION_MOVE, "Move/Attack (%d)" % _get_available_uses(ACTION_MOVE)))
	actions.append(_make_action(ACTION_RAID, "Raid (%d)" % _get_available_uses(ACTION_RAID)))
	actions.append(_make_action(ACTION_BRUTALIZE, "Brutalize (%d)" % _get_available_uses(ACTION_BRUTALIZE)))

	return actions

func handle_action(action_id: String) -> void:
	if _get_available_uses(action_id) <= 0:
		print("No Orc uses remaining for action: %s" % action_id)
		return

	match action_id:
		ACTION_MOVE:
			_start_move_mode()
		ACTION_RAID:
			_start_raid()
		ACTION_BRUTALIZE:
			_start_brutalize()
		_:
			print("Unknown Orc action: %s" % action_id)

func _get_available_uses(_action_type: String) -> int:
	return actions_remaining

func _spend_action(_action_type: String) -> bool:
	if actions_remaining <= 0:
		return false

	actions_remaining -= 1
	return true

func _make_action(id: String, label: String) -> ActionDefinition:
	var action := ActionDefinition.new()
	action.id = id
	action.label = label
	action.enabled = _get_available_uses(id) > 0
	return action

func on_settlement_selected(settlement: Settlement) -> void:
	match mode:
		MODE_RAID:
			_handle_raid_selected(settlement)
		MODE_BRUTALIZE:
			_handle_brutalize_selected(settlement)

func can_start_move_from_settlement(settlement: Settlement) -> bool:
	if settlement.faction != ORC_FACTION:
		return false

	if mode != ACTION_MOVE and mode != MODE_NONE:
		return false

	return actions_remaining > 0

func _start_move_mode() -> void:
	if _get_available_uses(ACTION_MOVE) <= 0:
		print("No Move/Attack actions remaining.")
		return

	mode = ACTION_MOVE
	print("Select an Orc settlement to move from.")
	_refresh_ui()

func after_successful_move(_source: Settlement, _target: Settlement) -> void:
	if mode != ACTION_MOVE:
		return

	_spend_action(ACTION_MOVE)
	mode = MODE_NONE
	print("Orcs used 1 Move/Attack action.")
	_refresh_ui()

func _get_first_non_empty_non_effigy_slot(settlement: Settlement) -> int:
	for i in range(settlement.building_slots.size()):
		var building := settlement.building_slots[i]
		if building != "" and building != BUILDING_GRUESOME_EFFIGY:
			return i
	return -1

func _has_raidable_building(settlement: Settlement) -> bool:
	return _get_first_non_empty_non_effigy_slot(settlement) != -1

func _start_raid() -> void:
	if _get_available_uses(ACTION_RAID) <= 0:
		print("No Raid actions remaining.")
		return

	mode = MODE_RAID
	print("Select a settlement containing a building to raid.")
	_refresh_ui()

func _handle_raid_selected(settlement: Settlement) -> void:
	if settlement.faction != ORC_FACTION:
		print("You can only raid buildings in Orc-controlled settlements.")
		return

	var slot_index := _get_first_non_empty_non_effigy_slot(settlement)
	if slot_index == -1:
		print("That settlement has no building to raid.")
		return

	if not _spend_action(ACTION_RAID):
		print("No Raid actions remaining.")
		return

	settlement.set_building_in_slot(slot_index, "")
	settlement.set_soldiers(settlement.soldiers + 10)
	TurnState.add_gold(ORC_FACTION, 10)

	mode = MODE_NONE
	print("Raided building. +10 Orcs, +10 Gold.")
	_refresh_ui()

func _start_brutalize() -> void:
	if _get_available_uses(ACTION_BRUTALIZE) <= 0:
		print("No Brutalize actions remaining.")
		return

	mode = MODE_BRUTALIZE
	print("Select a settlement containing a building to brutalize.")
	_refresh_ui()

func _handle_brutalize_selected(settlement: Settlement) -> void:
	if settlement.faction != ORC_FACTION:
		print("You can only raid buildings in Orc-controlled settlements.")
		return

	var slot_index := _get_first_non_empty_non_effigy_slot(settlement)
	if slot_index == -1:
		print("That settlement has no building to brutalize.")
		return

	if not _spend_action(ACTION_BRUTALIZE):
		print("No Brutalize actions remaining.")
		return

	settlement.set_building_in_slot(slot_index, BUILDING_GRUESOME_EFFIGY)

	mode = MODE_NONE
	print("Building brutalized into a Gruesome Effigy.")
	_refresh_ui()

func _refresh_ui() -> void:
	ui.show_faction_actions(get_action_list())

	if board.selected != null:
		ui.show_settlement_details(board.selected)

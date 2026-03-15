extends FactionController
class_name DwarfController

const DWARF_FACTION := Faction.Type.DWARF

# =========================
# Mode
# =========================

const MODE_NONE := ""
const MODE_BUILD_CHOOSE_SETTLEMENT := "build_choose_settlement"
const MODE_MARCH := "march"

# =========================
# Action
# =========================

const ACTION_BUILD := "build"
const ACTION_MARCH := "march"
const ACTION_TRAIN := "train"
const ACTION_MINE := "mine"
const ACTION_SMITH := "smith"

# =========================
# Buildings
# =========================

const BUILDING_GOLD_MINE := "Gold Mine"
const BUILDING_ARMOR_SMITH := "Armor Smith"
const BUILDING_GOAT_STABLE := "Goat Stable"
const BUILDING_TRAINING_GROUNDS := "Training Grounds"

const HOARD_THRESHOLDS := [40, 80, 120, 200, 320, 520]

var normal_actions_remaining: int = 2

var mode: String = MODE_NONE
var build_selected_settlement: Settlement = null

var march_moves_remaining: int = 0
var march_source: Settlement = null

var used_gold_action_thresholds_this_turn := {
	40: false,
	80: false,
	120: false,
	200: false,
	320: false,
	520: false
}

var in_war_meeting: bool = true

# =========================
# Turn and phases
# =========================

func start_turn() -> void:
	normal_actions_remaining = 2
	mode = MODE_NONE
	build_selected_settlement = null
	march_moves_remaining = 0
	march_source = null
	var in_war_meeting: bool = true

	for threshold in HOARD_THRESHOLDS:
		used_gold_action_thresholds_this_turn[threshold] = false

	_refresh_gold_hoard_assignments()
	_refresh_ui()

	print("Dwarf turn begins with 2 actions")
	print("Dwarf War Meeting begins")

func is_in_war_meeting() -> bool:
	return in_war_meeting

func finish_war_meeting() -> void:
	in_war_meeting = false
	print("Dwarf War Meeting ended")
	_refresh_ui()

# =========================
# Public hoard helpers
# =========================

func is_gold_threshold_active(threshold: int) -> bool:
	return _is_threshold_active(threshold)

func get_gold_assignment(threshold: int) -> String:
	return TurnState.get_dwarf_gold_action_assignment(threshold)

func assign_gold_action(threshold: int, action_type: String) -> void:
	if not _is_threshold_active(threshold):
		return

	TurnState.set_dwarf_gold_action_assignment(threshold, action_type)
	print("Assigned threshold %d to %s" % [threshold, action_type])

	_refresh_ui()

func request_gold_assignment(threshold: int) -> void:
	if not in_war_meeting:
		return

	if not _is_threshold_active(threshold):
		return

	if TurnState.get_dwarf_gold_action_assignment(threshold) != "":
		return

	ui.show_dwarf_gold_assignment_picker(threshold)

func on_resources_changed() -> void:
	_refresh_gold_hoard_assignments()
	_refresh_ui()

# =========================
# Selection / move hooks
# =========================

func on_settlement_selected(settlement: Settlement) -> void:
	match mode:
		MODE_BUILD_CHOOSE_SETTLEMENT:
			_handle_build_settlement_selected(settlement)
		MODE_MARCH:
			_handle_march_settlement_selected(settlement)

func is_in_special_move_mode() -> bool:
	return mode == MODE_MARCH

func can_start_move_from_settlement(settlement: Settlement) -> bool:
	if settlement.faction != DWARF_FACTION:
		return false

	return mode == MODE_MARCH and march_moves_remaining > 0

func after_successful_move(_source: Settlement, _target: Settlement) -> void:
	if mode != MODE_MARCH:
		return

	march_moves_remaining -= 1
	print("March move used. %d remaining." % march_moves_remaining)

	if march_moves_remaining <= 0:
		mode = MODE_NONE
		march_source = null
		print("March ended.")

	_refresh_ui()

# =========================
# Action list / action handling
# =========================

func get_action_list() -> Array:
	var actions: Array = []

	actions.append(_make_action(ACTION_BUILD, "Build (%d)" % _get_available_uses(ACTION_BUILD)))
	actions.append(_make_action(ACTION_MINE, "Mine (%d)" % _get_available_uses(ACTION_MINE)))
	actions.append(_make_action(ACTION_SMITH, "Smith (%d)" % _get_available_uses(ACTION_SMITH)))
	actions.append(_make_action(ACTION_TRAIN, "Train (%d)" % _get_available_uses(ACTION_TRAIN)))
	actions.append(_make_action(ACTION_MARCH, "March (%d)" % _get_available_uses(ACTION_MARCH)))

	return actions

func handle_action(action_id: String) -> void:
	if in_war_meeting:
		print("Finish the War Meeting first.")
		return
	
	if _get_available_uses(action_id) <= 0:
		print("No dwarf uses remaining for action: %s" % action_id)
		return

	match action_id:
		ACTION_BUILD:
			_start_build()
		ACTION_MINE:
			_action_mine()
		ACTION_SMITH:
			_action_smith()
		ACTION_TRAIN:
			_action_train()
		ACTION_MARCH:
			_start_march()
		_:
			print("Unknown dwarf action: %s" % action_id)

# =========================
# Build
# =========================

func _start_build() -> void:
	if _get_available_uses(ACTION_BUILD) <= 0:
		print("No Build actions remaining.")
		return

	mode = MODE_BUILD_CHOOSE_SETTLEMENT
	build_selected_settlement = null
	print("Choose a dwarf settlement with an empty building slot.")

func _handle_build_settlement_selected(settlement: Settlement) -> void:
	if settlement.faction != DWARF_FACTION:
		print("You can only build in dwarf settlements.")
		return

	var empty_index := _get_first_empty_building_slot(settlement)
	if empty_index == -1:
		print("That settlement has no empty building slot.")
		return

	build_selected_settlement = settlement
	ui.show_dwarf_build_options()
	print("Choose a building to place.")

func finish_build(building_name: String) -> void:
	if mode != MODE_BUILD_CHOOSE_SETTLEMENT:
		return

	if build_selected_settlement == null:
		return

	var empty_index := _get_first_empty_building_slot(build_selected_settlement)
	if empty_index == -1:
		print("No empty building slot.")
		return

	if not _spend_action(ACTION_BUILD):
		print("No Build actions remaining.")
		return

	build_selected_settlement.set_building_in_slot(empty_index, building_name)

	mode = MODE_NONE
	build_selected_settlement = null

	print("Built %s" % building_name)
	ui.hide_dwarf_build_options()
	_refresh_ui()

# =========================
# March
# =========================

func _start_march() -> void:
	var stables := _count_buildings(BUILDING_GOAT_STABLE)
	if stables <= 0:
		print("No Goat Stables, so no March moves available.")
		return

	if not _spend_action(ACTION_MARCH):
		print("No March actions remaining.")
		return

	mode = MODE_MARCH
	march_moves_remaining = stables
	march_source = null

	print("March started. You may make %d moves." % march_moves_remaining)
	_refresh_ui()

func _handle_march_settlement_selected(settlement: Settlement) -> void:
	if settlement.faction != DWARF_FACTION:
		print("You can only move soldiers in dwarf settlements.")
		return

	print("Choose place to move to.")

# =========================
# Simple actions
# =========================

func _action_mine() -> void:
	if not _spend_action(ACTION_MINE):
		print("No Mine actions remaining.")
		return

	var mines := _count_buildings(BUILDING_GOLD_MINE)
	var gain := mines * 20

	TurnState.add_gold(DWARF_FACTION, gain)

	print("Dwarves mined %d gold" % gain)
	_refresh_ui()

func _action_smith() -> void:
	if not _spend_action(ACTION_SMITH):
		print("No Smith actions remaining.")
		return

	var smiths := _count_buildings(BUILDING_ARMOR_SMITH)
	var gain := smiths * 2

	TurnState.add_armor(DWARF_FACTION, gain)

	print("Dwarves forged %d armor" % gain)
	_refresh_ui()

func _action_train() -> void:
	if not _spend_action(ACTION_TRAIN):
		print("No Train actions remaining.")
		return

	for settlement in _get_owned_settlements():
		if _settlement_has_building(settlement, BUILDING_TRAINING_GROUNDS):
			settlement.set_soldiers(settlement.soldiers + 1)

	print("Dwarves trained soldiers")
	_refresh_ui()

# =========================
# Hoard logic
# =========================

func _spend_action(action_type: String) -> bool:
	for threshold in HOARD_THRESHOLDS:
		if _is_threshold_active(threshold):
			if TurnState.get_dwarf_gold_action_assignment(threshold) == action_type and not used_gold_action_thresholds_this_turn[threshold]:
				used_gold_action_thresholds_this_turn[threshold] = true
				return true

	if normal_actions_remaining > 0:
		normal_actions_remaining -= 1
		return true

	return false

func _get_available_uses(action_type: String) -> int:
	var total := normal_actions_remaining

	for threshold in HOARD_THRESHOLDS:
		if _is_threshold_active(threshold):
			if TurnState.get_dwarf_gold_action_assignment(threshold) == action_type and not used_gold_action_thresholds_this_turn[threshold]:
				total += 1

	return total

func _is_threshold_active(threshold: int) -> bool:
	return TurnState.get_gold(DWARF_FACTION) >= threshold

func _refresh_gold_hoard_assignments() -> void:
	for threshold in HOARD_THRESHOLDS:
		if not _is_threshold_active(threshold):
			TurnState.get_dwarf_gold_action_assignment(threshold) != ""
			used_gold_action_thresholds_this_turn[threshold] = false

func _get_unassigned_active_thresholds() -> Array:
	var result := []
	for threshold in HOARD_THRESHOLDS:
		if _is_threshold_active(threshold) and TurnState.get_dwarf_gold_action_assignment(threshold) == "":
			result.append(threshold)
	return result

# =========================
# Settlement / building helpers
# =========================

func _get_owned_settlements() -> Array:
	var owned := []

	for settlement in board.get_tree().get_nodes_in_group("settlements"):
		if settlement.faction == DWARF_FACTION:
			owned.append(settlement)

	return owned

func _count_buildings(building_name: String) -> int:
	var total := 0

	for settlement in _get_owned_settlements():
		for slot in settlement.building_slots:
			if slot == building_name:
				total += 1

	return total

func _settlement_has_building(settlement: Settlement, building_name: String) -> bool:
	for slot in settlement.building_slots:
		if slot == building_name:
			return true
	return false

func _get_first_empty_building_slot(settlement: Settlement) -> int:
	for i in range(settlement.building_slots.size()):
		if settlement.building_slots[i] == "":
			return i
	return -1

func delete_building(settlement: Settlement, slot_index: int) -> void:
	if settlement == null:
		return

	if settlement.faction != DWARF_FACTION:
		print("You can only delete buildings in dwarf settlements.")
		return

	if slot_index < 0 or slot_index >= settlement.building_slot_count:
		return

	if settlement.building_slots[slot_index] == "":
		print("That slot is already empty.")
		return

	settlement.set_building_in_slot(slot_index, "")
	print("Deleted building from slot %d" % slot_index)

	_refresh_ui()

# =========================
# UI helpers
# =========================

func _make_action(id: String, label: String) -> ActionDefinition:
	var action := ActionDefinition.new()
	action.id = id
	action.label = label
	action.enabled = _get_available_uses(id) > 0
	return action

func _refresh_ui() -> void:
	ui.show_faction_actions(get_action_list())
	ui.update_dwarf_hoard_panel(self)

	if board.selected != null:
		ui.show_settlement_details(board.selected)

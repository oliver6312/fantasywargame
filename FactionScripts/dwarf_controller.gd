extends FactionController
class_name DwarfController

var normal_actions_remaining: int = 2

var mode: String = ""
var build_selected_settlement: Settlement = null

const BUILDING_GOLD_MINE := "Gold Mine"
const BUILDING_ARMOR_SMITH := "Armor Smith"
const BUILDING_GOAT_STABLE := "Goat Stable"
const BUILDING_TRAINING_GROUNDS := "Training Grounds"

var march_moves_remaining: int = 0
var march_source: Settlement = null

const HOARD_THRESHOLDS := [40, 80, 120, 200, 320, 520]

var gold_action_assignments := {
	40: "",
	80: "",
	120: "",
	200: "",
	320: "",
	520: ""
}

var used_gold_action_thresholds_this_turn := {
	40: false,
	80: false,
	120: false,
	200: false,
	320: false,
	520: false
}

func start_turn() -> void:
	normal_actions_remaining = 2
	print("Dwarf turn begins with 2 actions")
	
	for threshold in HOARD_THRESHOLDS:
		used_gold_action_thresholds_this_turn[threshold] = false

	_refresh_gold_hoard_assignments()
#	_prompt_for_unassigned_gold_actions_if_needed()
	_refresh_ui()

func _spend_action(action_type: String) -> bool:
	for threshold in HOARD_THRESHOLDS:
		if _is_threshold_active(threshold):
			if gold_action_assignments[threshold] == action_type and not used_gold_action_thresholds_this_turn[threshold]:
				used_gold_action_thresholds_this_turn[threshold] = true
				return true

	if normal_actions_remaining > 0:
		normal_actions_remaining -= 1
		return true

	return false

func is_gold_threshold_active(threshold: int) -> bool:
	return _is_threshold_active(threshold)

func get_gold_assignment(threshold: int) -> String:
	return gold_action_assignments.get(threshold, "")

func assign_gold_action(threshold: int, action_type: String) -> void:
	if not _is_threshold_active(threshold):
		return

	gold_action_assignments[threshold] = action_type
	print("Assigned threshold %d to %s" % [threshold, action_type])

#	_prompt_for_unassigned_gold_actions_if_needed()
	_refresh_ui()

func request_gold_assignment(threshold: int) -> void:
	if not _is_threshold_active(threshold):
		return

	if gold_action_assignments[threshold] != "":
		return

	ui.show_dwarf_gold_assignment_picker(threshold)

func _get_unassigned_active_thresholds() -> Array:
	var result := []
	for threshold in HOARD_THRESHOLDS:
		if _is_threshold_active(threshold) and gold_action_assignments[threshold] == "":
			result.append(threshold)
	return result

func _is_threshold_active(threshold: int) -> bool:
	return TurnState.get_gold(Faction.Type.DWARF) >= threshold

func _refresh_gold_hoard_assignments() -> void:
	for threshold in HOARD_THRESHOLDS:
		if not _is_threshold_active(threshold):
			gold_action_assignments[threshold] = ""
			used_gold_action_thresholds_this_turn[threshold] = false

func on_settlement_selected(settlement: Settlement) -> void:
	if mode == "build_choose_settlement":
		_handle_build_settlement_selected(settlement)
	elif mode == "march":
		_handle_march_settlement_selected(settlement)

func is_in_special_move_mode() -> bool:
	return mode == "march"

func after_successful_move(_source: Settlement, _target: Settlement) -> void:
	if mode != "march":
		return

	march_moves_remaining -= 1
	print("March move used. %d remaining." % march_moves_remaining)

	if march_moves_remaining <= 0:
		mode = ""
		march_source = null
		print("March ended.")

	_refresh_ui()

func _handle_march_settlement_selected(settlement: Settlement) -> void:
	if settlement.faction != Faction.Type.DWARF:
		print("You can only move soldiers in dwarf settlements.")
		return

	print("Choose place to move to.")

func _handle_build_settlement_selected(settlement: Settlement) -> void:
	if settlement.faction != Faction.Type.DWARF:
		print("You can only build in dwarf settlements.")
		return

	var empty_index := _get_first_empty_building_slot(settlement)
	if empty_index == -1:
		print("That settlement has no empty building slot.")
		return

	build_selected_settlement = settlement
	ui.show_dwarf_build_options()
	print("Choose a building to place.")

func _get_first_empty_building_slot(settlement: Settlement) -> int:
	for i in range(settlement.building_slots.size()):
		if settlement.building_slots[i] == "":
			return i
	return -1

func finish_build(building_name: String) -> void:
	if mode != "build_choose_settlement":
		return
	if build_selected_settlement == null:
		return

	var empty_index := _get_first_empty_building_slot(build_selected_settlement)
	if empty_index == -1:
		print("No empty building slot.")
		return

	build_selected_settlement.set_building_in_slot(empty_index, building_name)

	normal_actions_remaining -= 1
	mode = ""
	build_selected_settlement = null

	print("Built ", building_name)
	_refresh_ui()
	ui.hide_dwarf_build_options()

func _get_available_uses(action_type: String) -> int:
	var total := 0

	if normal_actions_remaining > 0:
		total += normal_actions_remaining

	for threshold in HOARD_THRESHOLDS:
		if _is_threshold_active(threshold):
			if gold_action_assignments[threshold] == action_type and not used_gold_action_thresholds_this_turn[threshold]:
				total += 1

	return total

func get_action_list() -> Array:
	var actions: Array = []

	actions.append(_make_action("build", "Build (%d)" % _get_available_uses("build")))
	actions.append(_make_action("mine", "Mine (%d)" % _get_available_uses("mine")))
	actions.append(_make_action("smith", "Smith (%d)" % _get_available_uses("smith")))
	actions.append(_make_action("train", "Train (%d)" % _get_available_uses("train")))
	actions.append(_make_action("march", "March (%d)" % _get_available_uses("march")))

	return actions

func handle_action(action_id: String) -> void:
	if normal_actions_remaining <= 0:
		print("No dwarf actions remaining.")
		return

	match action_id:
		"build":
			_start_build()
		"mine":
			_action_mine()
		"smith":
			_action_smith()
		"train":
			_action_train()
		"march":
			_start_march()
		_:
			print("Unknown dwarf action: ", action_id)

func _make_action(id: String, label: String) -> ActionDefinition:
	var a := ActionDefinition.new()
	a.id = id
	a.label = label
	a.enabled = normal_actions_remaining > 0
	return a

func _count_buildings(building_name: String) -> int:
	var total := 0

	for s in board.get_tree().get_nodes_in_group("settlements"):
		if s.faction != Faction.Type.DWARF:
			continue

		for slot in s.building_slots:
			if slot == building_name:
				total += 1

	return total

func _start_march() -> void:
	var stables := _count_buildings("Goat Stable")
	if stables <= 0:
		print("No Goat Stables, so no March moves available.")
		return

	normal_actions_remaining -= 1
	mode = "march"
	march_moves_remaining = stables
	march_source = null

	print("March started. You may make %d moves." % march_moves_remaining)
	_refresh_ui()

func _start_build() -> void:
	mode = "build_choose_settlement"
	build_selected_settlement = null
	print("Choose a dwarf settlement with an empty building slot.")

func _action_mine() -> void:
	var mines := _count_buildings("Gold Mine")
	var gain := mines * 20

	TurnState.add_gold(Faction.Type.DWARF, gain)
	normal_actions_remaining -= 1

	print("Dwarves mined ", gain, " gold")
	_refresh_ui()

func _action_smith() -> void:
	var smiths := _count_buildings("Armor Smith")
	var gain := smiths * 2

	TurnState.add_armor(Faction.Type.DWARF, gain)
	normal_actions_remaining -= 1

	print("Dwarves forged ", gain, " armor")
	_refresh_ui()

func _action_train() -> void:
	for s in board.get_tree().get_nodes_in_group("settlements"):
		if s.faction != Faction.Type.DWARF:
			continue

		var has_training := false
		for slot in s.building_slots:
			if slot == "Training Grounds":
				has_training = true
				break

		if has_training:
			print("has_training")
			s.set_soldiers(s.soldiers + 1)

	normal_actions_remaining -= 1

	print("Dwarves trained soldiers")
	_refresh_ui()

func _refresh_ui() -> void:
	ui.show_faction_actions(get_action_list())

	if board.selected != null:
		ui.show_settlement_details(board.selected)

func can_start_move_from_settlement(settlement: Settlement) -> bool:
	if settlement.faction != Faction.Type.DWARF:
		return false

	return mode == "march" and march_moves_remaining > 0

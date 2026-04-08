extends FactionController
class_name OrcController

const ORC_FACTION := Faction.Type.ORC

const ACTION_MOVE := "move"
const ACTION_RAID := "raid"
const ACTION_BRUTALIZE := "brutalize"
const ACTION_MOVE_LORD := "move_lord"

const MODE_NONE := ""
const MODE_RAID := "raid"
const MODE_BRUTALIZE := "brutalize"
const MODE_PICK_LORD_PLACE := "pick_lord_place"
const MODE_MOVE_LORD_SOURCE := "move_lord_source"
const MODE_MOVE_LORD_TARGET := "move_lord_target"
const MODE_PICK_WAR_PROMISE := "pick_war_promise"

const BUILDING_GRUESOME_EFFIGY := "Gruesome Effigy"

var actions_remaining: int = 3
var mode: String = MODE_NONE
var in_war_meeting: bool = true

var pending_dark_lord_pick: String = TurnState.ORC_LORD_NONE
var move_lord_source_settlement: Settlement = null
var move_lord_target_settlement: Settlement = null

var rng := RandomNumberGenerator.new()

func start_turn() -> void:
	rng.randomize()

	actions_remaining = 3 + TurnState.count_orc_owned_war_promises()
	mode = MODE_NONE
	in_war_meeting = true
	pending_dark_lord_pick = TurnState.ORC_LORD_NONE
	move_lord_source_settlement = null
	move_lord_target_settlement = null

	_refresh_ui()

	if not TurnState.has_orc_dark_lord():
		print("Orcs must choose a Dark Lord.")
		return

	if _needs_new_war_promise():
		_start_pick_war_promise()
		print("Orcs must make a War Promise.")
		return

	print("Orc War Meeting begins.")

func end_turn() -> void:
	if TurnState.get_orc_dark_lord() == TurnState.ORC_LORD_DRAGON:
		var lord_settlement := TurnState.find_orc_dark_lord_settlement()
		if lord_settlement != null and lord_settlement.faction == ORC_FACTION:
			var eaten: int = min(1, lord_settlement.soldiers)
			lord_settlement.set_soldiers(lord_settlement.soldiers - eaten)
			print("The Dragon devoured %d Orcs." % eaten)

	_refresh_ui()

func is_in_war_meeting() -> bool:
	return in_war_meeting

func finish_war_meeting() -> void:
	if not TurnState.has_orc_dark_lord():
		print("Choose and place a Dark Lord first.")
		return

	if mode == MODE_PICK_LORD_PLACE:
		print("Place the Dark Lord first.")
		return

	if mode == MODE_PICK_WAR_PROMISE:
		print("Choose a War Promise first.")
		return

	in_war_meeting = false
	mode = MODE_NONE
	print("Orc War Meeting ended.")
	ui.hide_war_meeting_button()
	_refresh_ui()

func is_in_special_selection_mode() -> bool:
	return mode in [
		MODE_RAID,
		MODE_BRUTALIZE,
		MODE_PICK_LORD_PLACE,
		MODE_MOVE_LORD_SOURCE,
		MODE_MOVE_LORD_TARGET,
		MODE_PICK_WAR_PROMISE
	]

func is_in_movement_mode() -> bool:
	return mode == ACTION_MOVE

func cancel_current_mode() -> void:
	if mode == MODE_NONE:
		return

	mode = MODE_NONE
	pending_dark_lord_pick = TurnState.ORC_LORD_NONE
	move_lord_source_settlement = null
	move_lord_target_settlement = null

	print("Orc action cancelled.")
	_refresh_ui()

func get_action_list() -> Array:
	var actions: Array = []

	if in_war_meeting:
		if not TurnState.has_orc_dark_lord():
			actions.append(_make_lord_pick_action(TurnState.ORC_LORD_DRAGON))
			actions.append(_make_lord_pick_action(TurnState.ORC_LORD_WRAITH))
			actions.append(_make_lord_pick_action(TurnState.ORC_LORD_SORCERER))
			actions.append(_make_lord_pick_action(TurnState.ORC_LORD_BLACKSMITH))
		return actions

	actions.append(_make_action(ACTION_MOVE, "Move/Attack (%d)" % _get_available_uses(ACTION_MOVE)))
	actions.append(_make_action(ACTION_RAID, "Raid (%d)" % _get_available_uses(ACTION_RAID)))
	actions.append(_make_action(ACTION_BRUTALIZE, "Brutalize (%d)" % _get_available_uses(ACTION_BRUTALIZE)))

	return actions

func handle_action(action_id: String) -> void:
	if in_war_meeting:
		if not TurnState.has_orc_dark_lord():
			match action_id:
				"pick_lord_dragon":
					_pick_dark_lord(TurnState.ORC_LORD_DRAGON)
				"pick_lord_wraith":
					_pick_dark_lord(TurnState.ORC_LORD_WRAITH)
				"pick_lord_sorcerer":
					_pick_dark_lord(TurnState.ORC_LORD_SORCERER)
				"pick_lord_blacksmith":
					_pick_dark_lord(TurnState.ORC_LORD_BLACKSMITH)
				_:
					print("Unknown Orc lord choice: %s" % action_id)
		return

	match action_id:
		ACTION_MOVE_LORD:
			_start_move_lord()
		ACTION_MOVE:
			_start_move_mode()
		ACTION_RAID:
			_start_raid()
		ACTION_BRUTALIZE:
			_start_brutalize()
		_:
			print("Unknown Orc action: %s" % action_id)

func on_settlement_selected(settlement: Settlement) -> void:
	match mode:
		MODE_RAID:
			_handle_raid_selected(settlement)
		MODE_BRUTALIZE:
			_handle_brutalize_selected(settlement)
		MODE_PICK_LORD_PLACE:
			_handle_dark_lord_placement_selected(settlement)
		MODE_MOVE_LORD_SOURCE:
			_handle_move_lord_source_selected(settlement)
		_:
			pass

func can_start_move_from_settlement(settlement: Settlement) -> bool:
	if settlement.faction != ORC_FACTION:
		return false

	if mode != ACTION_MOVE:
		return false

	return actions_remaining > 0

func after_successful_move(_source: Settlement, _target: Settlement) -> void:
	if mode != ACTION_MOVE:
		return

	if not _spend_action(ACTION_MOVE):
		print("No Move/Attack actions remaining.")
		return

	mode = MODE_NONE
	print("Orcs used 1 Move/Attack action.")
	_refresh_ui()

func can_remove_infiltration() -> bool:
	return not in_war_meeting

func remove_infiltration_from_settlement(settlement: Settlement) -> void:
	if settlement == null:
		return
	if not settlement.has_infiltration():
		print("That settlement has no infiltration.")
		return

	if actions_remaining <= 0:
		print("No actions remaining.")
		return

	actions_remaining -= 1
	settlement.clear_infiltration()

	print("Infiltration removed.")
	_refresh_ui()

func spend_move_lord_action() -> bool:
	return _spend_action(ACTION_MOVE_LORD)

func choose_war_promise(settlement: Settlement) -> void:
	if mode != MODE_PICK_WAR_PROMISE:
		return

	if settlement == null:
		return

	if settlement.faction == ORC_FACTION or settlement.faction == Faction.Type.NEUTRAL:
		print("War Promise must target an enemy settlement.")
		return

	settlement.set_orc_war_promise(true)
	mode = MODE_NONE

	print("War Promise chosen: %s" % settlement.get_display_name())
	_refresh_ui()

func resolve_dark_lord_move(source: Settlement, target: Settlement, soldiers: int, armor: int) -> void:
	if soldiers < 1:
		print("The Dark Lord must move with at least 1 soldier.")
		return

	if not source.has_orc_dark_lord():
		print("Source does not contain the Dark Lord.")
		return

	if not source.is_adjacent_to(target):
		print("Dark Lord can only move to an adjacent settlement.")
		return

	if soldiers > source.soldiers:
		print("Not enough soldiers.")
		return

	if armor < 0 or armor > TurnState.get_armor(ORC_FACTION):
		print("Invalid amount of armor.")
		return

	if not _spend_action(ACTION_MOVE_LORD):
		print("No Move Lord actions remaining.")
		return

	if target.faction == ORC_FACTION:
		source.set_soldiers(source.soldiers - soldiers)
		TurnState.add_armor(ORC_FACTION, -armor)
		TurnState.place_orc_dark_lord_in_settlement(target)
		target.set_soldiers(target.soldiers + soldiers)
		print("Dark Lord moved safely.")
	else:
		board.resolve_dark_lord_attack(source, target, soldiers, armor)

	mode = MODE_NONE
	move_lord_source_settlement = null
	move_lord_target_settlement = null
	_refresh_ui()

func _needs_new_war_promise() -> bool:
	var promises := TurnState.get_orc_war_promise_settlements()
	return promises.is_empty() or TurnState.are_all_war_promises_orc_owned()

func _start_pick_war_promise() -> void:
	mode = MODE_PICK_WAR_PROMISE

	var options := _get_top_3_enemy_settlements_by_soldiers()

	if options.is_empty():
		print("No valid enemy settlements for a War Promise.")
		_refresh_ui()
		return

	print("Choose a War Promise.")
	ui.show_orc_war_promise_picker(options)
	_refresh_ui()

func _get_top_3_enemy_settlements_by_soldiers() -> Array:
	var enemies := []

	for settlement in board.get_tree().get_nodes_in_group("settlements"):
		if settlement.faction == ORC_FACTION:
			continue
		if settlement.faction == Faction.Type.NEUTRAL:
			continue

		enemies.append(settlement)

	enemies.sort_custom(func(a, b): return a.soldiers > b.soldiers)

	if enemies.size() > 2:
		enemies = enemies.slice(0, 2)

	return enemies

func _start_move_lord() -> void:
	if in_war_meeting:
		print("Move Lord can only be used during the Action Phase.")
		return

	if not TurnState.has_orc_dark_lord():
		print("There is no Dark Lord to move.")
		return

	if _get_available_uses(ACTION_MOVE_LORD) <= 0:
		print("No Move Lord actions remaining.")
		return

	mode = MODE_MOVE_LORD_SOURCE
	move_lord_source_settlement = null
	move_lord_target_settlement = null

	print("Select the settlement containing the Dark Lord.")
	_refresh_ui()

func _pick_dark_lord(lord_name: String) -> void:
	if lord_name != TurnState.ORC_LORD_WRAITH and TurnState.is_orc_dark_lord_dead(lord_name):
		print("That Dark Lord is dead and cannot be chosen again.")
		return

	pending_dark_lord_pick = lord_name
	mode = MODE_PICK_LORD_PLACE

	print("Choose an Orc settlement to place the %s." % lord_name)
	_refresh_ui()

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

func _make_lord_pick_action(lord_name: String) -> ActionDefinition:
	var action := ActionDefinition.new()
	action.id = "pick_lord_" + lord_name.to_lower()
	action.label = lord_name

	if lord_name == TurnState.ORC_LORD_WRAITH:
		action.enabled = true
	else:
		action.enabled = not TurnState.is_orc_dark_lord_dead(lord_name)

	return action

func _start_move_mode() -> void:
	if in_war_meeting:
		print("Move/Attack can only be used during the Action Phase.")
		return

	if _get_available_uses(ACTION_MOVE) <= 0:
		print("No Move/Attack actions remaining.")
		return

	mode = ACTION_MOVE
	print("Select an Orc settlement to move from.")
	_refresh_ui()

func _start_raid() -> void:
	if in_war_meeting:
		print("Raid can only be used during the Action Phase.")
		return

	if _get_available_uses(ACTION_RAID) <= 0:
		print("No Raid actions remaining.")
		return

	mode = MODE_RAID
	print("Select a settlement containing a building to raid.")
	_refresh_ui()

func _start_brutalize() -> void:
	if in_war_meeting:
		print("Brutalize can only be used during the Action Phase.")
		return

	if _get_available_uses(ACTION_BRUTALIZE) <= 0:
		print("No Brutalize actions remaining.")
		return

	mode = MODE_BRUTALIZE
	print("Select a settlement containing a building to brutalize.")
	_refresh_ui()

func _handle_move_lord_source_selected(settlement: Settlement) -> void:
	if not settlement.has_orc_dark_lord():
		print("That settlement does not contain the Dark Lord.")
		return

	move_lord_source_settlement = settlement
	mode = MODE_MOVE_LORD_TARGET
	print("Now choose an adjacent settlement to move the Dark Lord into.")
	_refresh_ui()

func _handle_dark_lord_placement_selected(settlement: Settlement) -> void:
	if settlement.faction != ORC_FACTION:
		print("You must place the Dark Lord in an Orc settlement.")
		return

	TurnState.set_orc_dark_lord(pending_dark_lord_pick)
	TurnState.place_orc_dark_lord_in_settlement(settlement)

	mode = MODE_NONE
	pending_dark_lord_pick = TurnState.ORC_LORD_NONE

	print("Dark Lord chosen and placed.")

	if _needs_new_war_promise():
		_start_pick_war_promise()
	else:
		_refresh_ui()

func _get_first_non_empty_non_effigy_slot(settlement: Settlement) -> int:
	for i in range(settlement.building_slots.size()):
		var building := settlement.building_slots[i]
		if building != "" and building != BUILDING_GRUESOME_EFFIGY:
			return i
	return -1

func _has_raidable_building(settlement: Settlement) -> bool:
	return _get_first_non_empty_non_effigy_slot(settlement) != -1

func _handle_raid_selected(settlement: Settlement) -> void:
	var slot_index := _get_first_non_empty_non_effigy_slot(settlement)
	if slot_index == -1:
		print("That settlement has no building to raid.")
		return

	var cmd := RaidCommand.new()
	cmd.settlement = settlement
	cmd.slot_index = slot_index
	cmd.raiding_faction = ORC_FACTION
	cmd.blacksmith_bonus = TurnState.get_orc_dark_lord() == TurnState.ORC_LORD_BLACKSMITH

	if not board._run_command(cmd):
		return

	if not _spend_action(ACTION_RAID):
		print("No Raid actions remaining.")
		return

	mode = MODE_NONE
	_refresh_ui()

func _handle_brutalize_selected(settlement: Settlement) -> void:
	var slot_index := _get_first_non_empty_non_effigy_slot(settlement)
	if slot_index == -1:
		print("That settlement has no building to brutalize.")
		return

	var cmd := BrutalizeCommand.new()
	cmd.settlement = settlement
	cmd.slot_index = slot_index
	cmd.brutalizing_faction = ORC_FACTION

	if not board._run_command(cmd):
		return

	if not _spend_action(ACTION_BRUTALIZE):
		print("No Brutalize actions remaining.")
		return

	mode = MODE_NONE
	_refresh_ui()

func can_delete_buildings() -> bool:
	return not in_war_meeting

func delete_building(settlement: Settlement, slot_index: int) -> void:
	if settlement == null:
		return

	if settlement.faction != ORC_FACTION:
		print("You can only delete buildings in orc settlements.")
		return

	if slot_index < 0 or slot_index >= settlement.building_slot_count:
		return

	if settlement.building_slots[slot_index] == "":
		print("That slot is already empty.")
		return

	settlement.set_building_in_slot(slot_index, "")
	print("Deleted building from slot %d" % slot_index)

	_refresh_ui()

func _refresh_ui() -> void:
	ui.show_faction_actions(get_action_list())

	if board.selected != null:
		ui.show_settlement_details(board.selected)

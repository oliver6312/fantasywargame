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

var in_war_meeting: bool = true

const MODE_PICK_LORD_PLACE := "pick_lord_place"

var pending_dark_lord_pick: String = TurnState.ORC_LORD_NONE

const MODE_MOVE_LORD_SOURCE := "move_lord_source"
const MODE_MOVE_LORD_TARGET := "move_lord_target"

var move_lord_source_settlement: Settlement = null
var move_lord_target_settlement: Settlement = null

var rng := RandomNumberGenerator.new()

func start_turn() -> void:
	rng.randomize()
	actions_remaining = 4
	mode = MODE_NONE
	in_war_meeting = true

	_refresh_ui()

	if not TurnState.has_orc_dark_lord():
		print("Orcs must choose a Dark Lord.")
	else:
		print("Orc War Meeting begins.")

func end_turn() -> void:
	if TurnState.get_orc_dark_lord() == TurnState.ORC_LORD_DRAGON:
		var lord_settlement := TurnState.find_orc_dark_lord_settlement()
		if lord_settlement != null and lord_settlement.faction == ORC_FACTION:
			var eaten : int = min(rng.randi_range(1, 6), lord_settlement.soldiers)
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

	in_war_meeting = false
	print("Orc War Meeting ended.")
	_refresh_ui()

func is_in_special_selection_mode() -> bool:
	return mode == MODE_RAID or mode == MODE_BRUTALIZE

func is_in_movement_mode() -> bool:
	return mode == ACTION_MOVE

func cancel_current_mode() -> void:
	if mode == MODE_NONE:
		return

	mode = MODE_NONE
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
	actions.append(_make_action("move_lord", "Move Lord"))

	return actions

func _make_lord_pick_action(lord_name: String) -> ActionDefinition:
	var action := ActionDefinition.new()
	action.id = "pick_lord_" + lord_name.to_lower()
	action.label = lord_name

	if lord_name == TurnState.ORC_LORD_WRAITH:
		action.enabled = true
	else:
		action.enabled = not TurnState.is_orc_dark_lord_dead(lord_name)

	return action

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
		return

	match action_id:
		"move_lord":
			_start_move_lord()
		ACTION_MOVE:
			_start_move_mode()
		ACTION_RAID:
			_start_raid()
		ACTION_BRUTALIZE:
			_start_brutalize()
		_:
			print("Unknown Orc action: %s" % action_id)

func _start_move_lord() -> void:
	if not TurnState.has_orc_dark_lord():
		print("There is no Dark Lord to move.")
		return

	mode = MODE_MOVE_LORD_SOURCE
	move_lord_source_settlement = null
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

func on_settlement_selected(settlement: Settlement) -> void:
	match mode:
		MODE_RAID:
			_handle_raid_selected(settlement)
		MODE_BRUTALIZE:
			_handle_brutalize_selected(settlement)
	if mode == MODE_PICK_LORD_PLACE:
		_handle_dark_lord_placement_selected(settlement)
	elif mode == MODE_MOVE_LORD_SOURCE:
		_handle_move_lord_source_selected(settlement)
	elif mode == MODE_MOVE_LORD_TARGET:
		_handle_move_lord_target_selected(settlement)

func _handle_move_lord_source_selected(settlement: Settlement) -> void:
	if not settlement.has_orc_dark_lord():
		print("That settlement does not contain the Dark Lord.")
		return

	move_lord_source_settlement = settlement
	mode = MODE_MOVE_LORD_TARGET
	print("Now choose an adjacent settlement to move the Dark Lord into.")

func _handle_move_lord_target_selected(settlement: Settlement) -> void:
	if move_lord_source_settlement == null:
		return

	if not move_lord_source_settlement.is_adjacent_to(settlement):
		print("The Dark Lord may only move to an adjacent settlement.")
		return

	move_lord_target_settlement = settlement
	board.open_dark_lord_move_dialog(move_lord_source_settlement, move_lord_target_settlement)

func _handle_dark_lord_placement_selected(settlement: Settlement) -> void:
	if settlement.faction != ORC_FACTION:
		print("You must place the Dark Lord in an Orc settlement.")
		return

	TurnState.set_orc_dark_lord(pending_dark_lord_pick)
	TurnState.place_orc_dark_lord_in_settlement(settlement)

	mode = MODE_NONE
	pending_dark_lord_pick = TurnState.ORC_LORD_NONE

	print("Dark Lord chosen and placed.")
	_refresh_ui()

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

	if TurnState.get_orc_dark_lord() == TurnState.ORC_LORD_BLACKSMITH:
		TurnState.add_armor(ORC_FACTION, 10)
		print("Blacksmith bonus: +10 Armor.")

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

func resolve_dark_lord_move(source: Settlement, target: Settlement, soldiers: int, armor: int) -> void:
	if not source.has_orc_dark_lord():
		print("Source does not contain the Dark Lord.")
		return

	if not source.is_adjacent_to(target):
		print("Dark Lord can only move to an adjacent settlement.")
		return

	if soldiers < 0 or soldiers > source.soldiers:
		print("Invalid number of soldiers.")
		return

	if armor < 0 or armor > TurnState.get_armor(ORC_FACTION):
		print("Invalid amount of armor.")
		return

	if target.faction == ORC_FACTION:
		source.set_soldiers(source.soldiers - soldiers)
		TurnState.place_orc_dark_lord_in_settlement(target)
		target.set_soldiers(target.soldiers + soldiers)
		print("Dark Lord moved safely.")
	else:
		board.resolve_dark_lord_attack(source, target, soldiers, armor)

	mode = MODE_NONE
	move_lord_source_settlement = null
	move_lord_target_settlement = null
	_refresh_ui()

func _refresh_ui() -> void:
	ui.show_faction_actions(get_action_list())

	if board.selected != null:
		ui.show_settlement_details(board.selected)

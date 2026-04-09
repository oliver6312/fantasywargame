extends FactionController
class_name ElfController

const ELF_FACTION := Faction.Type.ELF
const BUILDING_SACRED_GROVE := "Sacred Grove"

const MODE_NONE := ""
const MODE_SHADOW_SOURCE := "shadow_source"
const MODE_SHADOW_TARGET := "shadow_target"
const MODE_REMOVE_INFILTRATION := "remove_infiltration"

var in_war_meeting: bool = true
var mode: String = MODE_NONE
var shadow_source_settlement: Settlement = null

var extend_season_used_this_turn: bool = false

var elf_magic 

func start_turn() -> void:
	in_war_meeting = true
	mode = MODE_NONE
	shadow_source_settlement = null
	extend_season_used_this_turn = false

	_auto_build_sacred_groves()
	_apply_infiltration_theft()

	_refresh_ui()
	print("Elf War Meeting begins")

func end_turn() -> void:
	var magic_gain := 0

	for settlement in _get_owned_settlements():
		if _settlement_has_building(settlement, BUILDING_SACRED_GROVE):
			magic_gain += 1

	TurnState.add_elf_magic(magic_gain)
	print("Elves gained %d Magic." % magic_gain)

func is_in_war_meeting() -> bool:
	return in_war_meeting

func finish_war_meeting() -> void:
	in_war_meeting = false
	mode = MODE_NONE
	print("Elf War Meeting ended")
	ui.hide_war_meeting_button()
	_refresh_ui()

func cancel_current_mode() -> void:
	if mode == MODE_NONE:
		return

	mode = MODE_NONE
	shadow_source_settlement = null
	print("Elf ritual cancelled.")
	_refresh_ui()

func get_action_list() -> Array:
	var actions: Array = []

	if in_war_meeting:
		actions.append(_make_action("root_of_all_evil", "Root of All Evil", true))
		actions.append(_make_action("extend_season", "Extend Season", not extend_season_used_this_turn))
		actions.append(_make_action("shadow_ritual", "Shadow Ritual", mode == MODE_NONE))
	else:
		actions.append(_make_action("remove_infiltration", "Remove Infiltration", mode == MODE_NONE))

	return actions

func handle_action(action_id: String) -> void:
	if in_war_meeting:
		match action_id:
			"root_of_all_evil":
				_start_root_of_all_evil()
			"extend_season":
				_do_extend_season()
			"shadow_ritual":
				_start_shadow_ritual()
			_:
				print("Unknown elf war meeting action: %s" % action_id)
	else:
		match action_id:
			"remove_infiltration":
				_start_remove_infiltration()
			_:
				print("Unknown elf action: %s" % action_id)

func on_settlement_selected(settlement: Settlement) -> void:
	match mode:
		MODE_SHADOW_SOURCE:
			_handle_shadow_source_selected(settlement)
		MODE_SHADOW_TARGET:
			_handle_shadow_target_selected(settlement)
		MODE_REMOVE_INFILTRATION:
			_handle_remove_infiltration_selected(settlement)

func is_in_special_selection_mode() -> bool:
	return mode == MODE_SHADOW_SOURCE \
		or mode == MODE_SHADOW_TARGET \
		or mode == MODE_REMOVE_INFILTRATION

func is_in_movement_mode() -> bool:
	return not in_war_meeting and mode == MODE_NONE

func can_start_move_from_settlement(settlement: Settlement) -> bool:
	# Elves have unlimited actions and normal movement.
	# But do not allow normal movement while in War Meeting or during another special mode.
	if settlement.faction != ELF_FACTION:
		return false

	if in_war_meeting:
		return false

	if mode != MODE_NONE:
		return false

	return true

func after_successful_move(_source: Settlement, _target: Settlement) -> void:
	# Elves have no special move consumption yet.
	pass

func can_delete_buildings() -> bool:
	return not in_war_meeting

func delete_building(settlement: Settlement, slot_index: int) -> void:
	if settlement == null:
		return

	if _settlement_has_building(settlement, BUILDING_SACRED_GROVE):
		return

	if settlement.faction != ELF_FACTION:
		print("You can only delete buildings in elven settlements.")
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
# Rituals
# =========================

func _start_root_of_all_evil() -> void:
	var available_gold := TurnState.get_gold(ELF_FACTION)
	var spendable_gold := available_gold - (available_gold % 12)

	if spendable_gold < 12:
		print("Not enough gold to convert.")
		return

	convert_gold_to_magic(spendable_gold)

func convert_gold_to_magic(gold_amount: int) -> void:
	if gold_amount > TurnState.get_gold(ELF_FACTION):
		print("Not enough gold.")
		return

	var magic_gain := int(gold_amount / 6)

	TurnState.add_gold(ELF_FACTION, -gold_amount)
	TurnState.add_elf_magic(magic_gain)

	print("Elves converted %d gold into %d magic." % [gold_amount, magic_gain])
	_refresh_ui()

func _do_extend_season() -> void:
	if TurnState.elf_magic == 0:
		return

	if not TurnState.can_elves_extend_season():
		print("Elves may only extend the season once per season.")
		return

	TurnState.elf_magic -= 4
	TurnState.resources_changed.emit()

	TurnState.set_season_extended_this_round(true)

	print("Elves will prevent the season from advancing this round.")
	_refresh_ui()

func _start_shadow_ritual() -> void:
	if TurnState.elf_magic < 8:
		return

	mode = MODE_SHADOW_SOURCE
	shadow_source_settlement = null
	print("Select an elven settlement with at least 1 soldier.")
	_refresh_ui()

func _handle_shadow_source_selected(settlement: Settlement) -> void:
	if settlement.faction != ELF_FACTION:
		print("Must choose an elven settlement.")
		return

	if settlement.soldiers < 1:
		print("Need at least 5 soldiers.")
		return

	shadow_source_settlement = settlement
	mode = MODE_SHADOW_TARGET
	print("Now choose an enemy settlement without infiltration.")
	_refresh_ui()

func _handle_shadow_target_selected(settlement: Settlement) -> void:
	if settlement.faction == ELF_FACTION or settlement.faction == Faction.Type.NEUTRAL:
		print("Must choose an enemy settlement.")
		return

	if settlement.has_infiltration():
		print("That settlement already has an infiltration.")
		return

	shadow_source_settlement.set_soldiers(shadow_source_settlement.soldiers - 1)
	TurnState.elf_magic -= 8
	settlement.set_infiltration(ELF_FACTION)

	mode = MODE_NONE
	shadow_source_settlement = null

	print("Infiltration placed.")
	TurnState.resources_changed.emit()
	_refresh_ui()

# =========================
# Remove infiltration
# =========================

func _start_remove_infiltration() -> void:
	if in_war_meeting:
		return

	mode = MODE_REMOVE_INFILTRATION
	print("Select a settlement containing an infiltration to remove.")
	_refresh_ui()

func _handle_remove_infiltration_selected(settlement: Settlement) -> void:
	if not settlement.has_infiltration():
		print("That settlement has no infiltration.")
		return

	settlement.clear_infiltration()
	mode = MODE_NONE
	print("Infiltration removed.")
	_refresh_ui()

func can_remove_infiltration() -> bool:
	return not in_war_meeting

func remove_infiltration_from_settlement(settlement: Settlement) -> void:
	if settlement == null:
		return
	if not settlement.has_infiltration():
		print("That settlement has no infiltration.")
		return

	settlement.clear_infiltration()
	print("Infiltration removed.")
	_refresh_ui()

# =========================
# Start-of-turn effects
# =========================

func _auto_build_sacred_groves() -> void:
	for settlement in _get_owned_settlements():
		if _settlement_has_building(settlement, BUILDING_SACRED_GROVE):
			continue

		var empty_slot := _get_first_empty_building_slot(settlement)
		if empty_slot != -1:
			settlement.set_building_in_slot(empty_slot, BUILDING_SACRED_GROVE)

func _apply_infiltration_theft() -> void:
	for settlement in board.get_tree().get_nodes_in_group("settlements"):
		if not settlement.has_infiltration():
			continue

		if settlement.infiltration_faction != ELF_FACTION:
			continue

		if settlement.faction == Faction.Type.NEUTRAL:
			continue

		var victim : int = settlement.faction
		var stolen_gold : int = min(5, TurnState.get_gold(victim))
		var stolen_armor : int = min(1, TurnState.get_armor(victim))

		TurnState.add_gold(victim, -stolen_gold)
		TurnState.add_gold(ELF_FACTION, stolen_gold)

		TurnState.add_armor(victim, -stolen_armor)
		TurnState.add_armor(ELF_FACTION, stolen_armor)

		print("Infiltration stole %d gold and %d armor from %s." % [
			stolen_gold,
			stolen_armor,
			TurnState.get_faction_name(victim)
		])

# =========================
# Helpers
# =========================

func _get_owned_settlements() -> Array:
	var owned := []

	for settlement in board.get_tree().get_nodes_in_group("settlements"):
		if settlement.faction == ELF_FACTION:
			owned.append(settlement)

	return owned

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

func _make_action(id: String, label: String, enabled: bool = true) -> ActionDefinition:
	var action := ActionDefinition.new()
	action.id = id
	action.label = label
	action.enabled = enabled
	return action

func _refresh_ui() -> void:
	ui.show_faction_actions(get_action_list())

	if board.selected != null:
		ui.show_settlement_details(board.selected)

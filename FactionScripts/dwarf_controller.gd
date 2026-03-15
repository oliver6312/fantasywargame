extends FactionController
class_name DwarfController

var normal_actions_remaining: int = 2

var mode: String = ""
var build_selected_settlement: Settlement = null

const BUILDING_GOLD_MINE := "Gold Mine"
const BUILDING_ARMOR_SMITH := "Armor Smith"
const BUILDING_GOAT_STABLE := "Goat Stable"
const BUILDING_TRAINING_GROUNDS := "Training Grounds"

func start_turn() -> void:
	normal_actions_remaining = 2
	print("Dwarf turn begins with 2 actions")

func on_settlement_selected(settlement: Settlement) -> void:
	if mode == "build_choose_settlement":
		_handle_build_settlement_selected(settlement)
#	elif mode == "march":
#		_handle_march_settlement_selected(settlement)

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

func get_action_list() -> Array:
	var actions: Array = []

	actions.append(_make_action("build", "Build"))
	actions.append(_make_action("mine", "Mine"))
	actions.append(_make_action("smith", "Smith"))
	actions.append(_make_action("train", "Train"))
	actions.append(_make_action("march", "March"))

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
#		"march":
#			_start_march()
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

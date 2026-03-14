extends FactionController
class_name DwarfController

const ACTION_BUILD := "build"
const ACTION_MARCH := "march"
const ACTION_TRAIN := "train"
const ACTION_MINE := "mine"
const ACTION_SMITH := "smith"

const HOARD_THRESHOLDS := [40, 80, 120, 200, 320, 520]

var normal_actions_remaining: int = 2

var gold_action_assignments := {
	40: "",
	80: "",
	120: "",
	200: "",
	320: "",
	520: ""
}

var used_gold_action_thresholds_this_turn = {
	40: false,
	80: false,
	120: false,
	200: false,
	320: false,
	520: false
}

func get_available_uses_for_action(action_type: String) -> int:
	var total := 0

	total += normal_actions_remaining

	for threshold in HOARD_THRESHOLDS:
		if _is_threshold_active(threshold):
			if gold_action_assignments[threshold] == action_type and not used_gold_action_thresholds_this_turn[threshold]:
				total += 1

	return total

func spend_action(action_type: String) -> bool:
	for threshold in HOARD_THRESHOLDS:
		if _is_threshold_active(threshold):
			if gold_action_assignments[threshold] == action_type and not used_gold_action_thresholds_this_turn[threshold]:
				used_gold_action_thresholds_this_turn[threshold] = true
				return true

	if normal_actions_remaining > 0:
		normal_actions_remaining -= 1
		return true

	return false


#building counters
func get_owned_settlements() -> Array:
	var result := []
	for s in board.get_tree().get_nodes_in_group("settlements"):
		if s.faction == Faction.Type.DWARF:
			result.append(s)
	return result

func count_buildings(building_type: String) -> int:
	var total := 0
	for s in get_owned_settlements():
		for slot in s.building_slots:
			if slot == building_type:
				total += 1
	return total

func count_empty_building_slots() -> int:
	var total := 0
	for s in get_owned_settlements():
		for slot in s.building_slots:
			if slot == "":
				total += 1
	return total

#Dwarf action effects
var current_mode := ""

func perform_train() -> void:
	for s in get_owned_settlements():
		var has_training := false
		for slot in s.building_slots:
			if slot == BuildingTypes.TRAINING_GROUNDS:
				has_training = true
				break
		if has_training:
			s.set_soldiers(s.soldiers + 1)

func perform_mine() -> void:
	var mines := count_buildings(BuildingTypes.GOLD_MINE)
	TurnState.add_gold(Faction.Type.DWARF, mines * 20)

func perform_smith() -> void:
	var smiths := count_buildings(BuildingTypes.ARMOR_SMITH)
	TurnState.add_armor(Faction.Type.DWARF, smiths * 2)

#hoard activation and assingment
func _is_threshold_active(threshold: int) -> bool:
	return TurnState.get_gold(Faction.Type.DWARF) >= threshold

func refresh_gold_action_unlocks() -> void:
	for threshold in HOARD_THRESHOLDS:
		if not _is_threshold_active(threshold):
			gold_action_assignments[threshold] = ""
			used_gold_action_thresholds_this_turn[threshold] = false

func get_unassigned_active_thresholds() -> Array:
	var result := []
	for threshold in HOARD_THRESHOLDS:
		if _is_threshold_active(threshold) and gold_action_assignments[threshold] == "":
			result.append(threshold)
	return result

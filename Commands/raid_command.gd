extends GameCommand
class_name RaidCommand

var settlement: Settlement
var slot_index: int = -1
var raiding_faction: int = Faction.Type.ORC
var blacksmith_bonus: bool = false

func validate(context: CommandContext) -> bool:
	if settlement == null:
		return false

	if raiding_faction != context.current_faction:
		return false

	if slot_index < 0 or slot_index >= settlement.building_slot_count:
		return false

	var building := settlement.building_slots[slot_index]
	if building == "" or building == "Gruesome Effigy":
		return false

	return true

func get_error(context: CommandContext) -> String:
	if settlement == null:
		return "No settlement selected."
	if raiding_faction != context.current_faction:
		return "It is not that faction's turn."
	if slot_index < 0 or slot_index >= settlement.building_slot_count:
		return "Invalid building slot."
	var building := settlement.building_slots[slot_index]
	if building == "" or building == "Gruesome Effigy":
		return "There is no valid building to raid."
	return "Raid failed."

func execute(context: CommandContext) -> void:
	settlement.set_building_in_slot(slot_index, "")
	settlement.set_soldiers(settlement.soldiers + 6)
	context.turn_state.add_gold(raiding_faction, 6)

	print("Raided building.")

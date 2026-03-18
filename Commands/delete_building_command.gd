extends GameCommand
class_name DeleteBuildingCommand

var settlement: Settlement
var slot_index: int = -1

func validate(context: CommandContext) -> bool:
	if settlement == null:
		return false

	if settlement.faction != context.current_faction:
		return false

	if slot_index < 0 or slot_index >= settlement.building_slot_count:
		return false

	if settlement.building_slots[slot_index] == "":
		return false

	return true

func get_error(context: CommandContext) -> String:
	if settlement == null:
		return "No settlement selected."
	if settlement.faction != context.current_faction:
		return "You do not control that settlement."
	if slot_index < 0 or slot_index >= settlement.building_slot_count:
		return "Invalid slot."
	if settlement.building_slots[slot_index] == "":
		return "That slot is already empty."
	return "Could not delete building."

func execute(_context: CommandContext) -> void:
	settlement.set_building_in_slot(slot_index, "")
	print("Deleted building.")

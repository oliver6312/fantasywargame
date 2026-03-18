extends GameCommand
class_name BuildCommand

var settlement: Settlement
var slot_index: int = -1
var building_name: String = ""

func validate(context: CommandContext) -> bool:
	if settlement == null:
		return false

	if settlement.faction != context.current_faction:
		return false

	if slot_index < 0 or slot_index >= settlement.building_slot_count:
		return false

	if settlement.building_slots[slot_index] != "":
		return false

	if building_name == "":
		return false

	return true

func get_error(context: CommandContext) -> String:
	if settlement == null:
		return "No settlement selected."
	if settlement.faction != context.current_faction:
		return "You do not control that settlement."
	if slot_index < 0 or slot_index >= settlement.building_slot_count:
		return "Invalid building slot."
	if settlement.building_slots[slot_index] != "":
		return "That slot is not empty."
	if building_name == "":
		return "No building selected."
	return "Could not build."

func execute(_context: CommandContext) -> void:
	settlement.set_building_in_slot(slot_index, building_name)
	print("Built %s." % building_name)

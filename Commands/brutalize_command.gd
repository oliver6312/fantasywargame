extends GameCommand
class_name BrutalizeCommand

var settlement: Settlement
var slot_index: int = -1
var brutalizing_faction: int = Faction.Type.ORC
var gruesome_effigy_name: String = "Gruesome Effigy"

func validate(context: CommandContext) -> bool:
	if settlement == null:
		return false

	if brutalizing_faction != context.current_faction:
		return false

	if slot_index < 0 or slot_index >= settlement.building_slot_count:
		return false

	var building := settlement.building_slots[slot_index]
	if building == "" or building == gruesome_effigy_name:
		return false

	return true

func get_error(context: CommandContext) -> String:
	if settlement == null:
		return "No settlement selected."
	if brutalizing_faction != context.current_faction:
		return "It is not that faction's turn."
	if slot_index < 0 or slot_index >= settlement.building_slot_count:
		return "Invalid building slot."
	var building := settlement.building_slots[slot_index]
	if building == "" or building == gruesome_effigy_name:
		return "There is no valid building to brutalize."
	return "Brutalize failed."

func execute(_context: CommandContext) -> void:
	settlement.set_building_in_slot(slot_index, gruesome_effigy_name)
	print("Building brutalized into a Gruesome Effigy.")

extends GameCommand
class_name AssignDwarfGoldActionCommand

var faction: int
var threshold: int
var action_type: String

func validate(context: CommandContext) -> bool:
	if context.current_faction != Faction.Type.DWARF:
		return false

	if context.turn_state.get_gold(Faction.Type.DWARF) < threshold:
		return false

	if context.turn_state.get_dwarf_gold_action_assignment(threshold) != "":
		return false

	return true

func get_error(context: CommandContext) -> String:
	if context.current_faction != Faction.Type.DWARF:
		return "Only dwarves can assign hoard actions."
	if context.turn_state.get_gold(Faction.Type.DWARF) < threshold:
		return "That hoard threshold is not active."
	if context.turn_state.get_dwarf_gold_action_assignment(threshold) != "":
		return "That threshold is already assigned."
	return "Could not assign hoard action."

func execute(context: CommandContext) -> void:
	context.turn_state.set_dwarf_gold_action_assignment(threshold, action_type)
	print("Assigned threshold %d to %s" % [threshold, action_type])

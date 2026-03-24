extends GameCommand
class_name SmithCommand

var faction: int
var amount = 4
var building_name: String = "Armor Smith"

func validate(context: CommandContext) -> bool:
	return faction == context.current_faction and amount >= 0

func get_error(context: CommandContext) -> String:
	if faction != context.current_faction:
		return "It is not that faction's turn."
	if amount < 0:
		return "Invalid armor amount."
	return "Could not forge."

func execute(context: CommandContext) -> void:
	context.turn_state.add_armor(faction, amount)
	print("%s forged %d armor." % [context.turn_state.get_faction_name(faction), amount])

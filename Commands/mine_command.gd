extends GameCommand
class_name MineCommand

var faction: int
var amount: int

func validate(context: CommandContext) -> bool:
	return faction == context.current_faction and amount >= 0

func get_error(context: CommandContext) -> String:
	if faction != context.current_faction:
		return "It is not that faction's turn."
	if amount < 0:
		return "Invalid gold amount."
	return "Could not mine."

func execute(context: CommandContext) -> void:
	context.turn_state.add_gold(faction, amount)
	print("%s mined %d gold." % [context.turn_state.get_faction_name(faction), amount])

extends GameCommand
class_name MoveCommand

var source: Settlement
var target: Settlement

var soldiers: int
var attacker_armor: int = 0
var defender_armor: int = 0

var is_attack: bool = false

var bring_dark_lord: bool = false

func validate(context: CommandContext) -> bool:
	if source == null or target == null:
		return false

	if source.faction != context.current_faction:
		return false

	if not source.is_adjacent_to(target):
		return false

	if soldiers <= 0:
		return false

	if soldiers > source.soldiers:
		return false

	# Armor validation
	if is_attack:
		if attacker_armor > context.turn_state.get_armor(source.faction):
			return false

		if target.faction != Faction.Type.NEUTRAL:
			if defender_armor > context.turn_state.get_armor(target.faction):
				return false

	return true

func get_error(context: CommandContext) -> String:
	if source == null or target == null:
		return "Invalid move."

	if source.faction != context.current_faction:
		return "Not your faction."

	if not source.is_adjacent_to(target):
		return "Settlements are not connected."

	if soldiers <= 0:
		return "Must send at least 1 soldier."

	if soldiers > source.soldiers:
		return "Not enough soldiers."

	if is_attack:
		if attacker_armor > context.turn_state.get_armor(source.faction):
			return "Not enough attacker armor."

		if target.faction != Faction.Type.NEUTRAL:
			if defender_armor > context.turn_state.get_armor(target.faction):
				return "Not enough defender armor."

	return "Move failed."

func execute(context: CommandContext) -> void:
	if is_attack:
		context.board.resolve_attack_command(self, context)
	else:
		context.board.resolve_move_command(self, context)

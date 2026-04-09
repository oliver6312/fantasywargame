extends GameCommand
class_name TradeCommand

var sender_faction: int
var receiver_faction: int
var gold_amount: int = 0
var armor_amount: int = 0

func validate(context: CommandContext) -> bool:
	if sender_faction != context.current_faction:
		return false

	if receiver_faction == sender_faction:
		return false

	if gold_amount < 0 or armor_amount < 0:
		return false

	if gold_amount > 40 or armor_amount > 40:
		return false

	if gold_amount > context.turn_state.get_gold(sender_faction):
		return false

	if armor_amount > context.turn_state.get_armor(sender_faction):
		return false

	return true

func get_error(context: CommandContext) -> String:
	if sender_faction != context.current_faction:
		return "It is not that faction's turn."
	if receiver_faction == sender_faction:
		return "Cannot trade to the same faction."
	if gold_amount < 0 or armor_amount < 0:
		return "Trade amounts cannot be negative."
	if gold_amount > context.turn_state.get_gold(sender_faction):
		return "Not enough gold."
	if armor_amount > context.turn_state.get_armor(sender_faction):
		return "Not enough armor."
	return "Trade failed."

func execute(context: CommandContext) -> void:
	context.turn_state.add_gold(sender_faction, -gold_amount)
	context.turn_state.add_gold(receiver_faction, gold_amount)

	context.turn_state.add_armor(sender_faction, -armor_amount)
	context.turn_state.add_armor(receiver_faction, armor_amount)

	SignalBus.emit_signal("has_traded")

	print("%s sent %d gold and %d armor to %s." % [
		context.turn_state.get_faction_name(sender_faction),
		gold_amount,
		armor_amount,
		context.turn_state.get_faction_name(receiver_faction)
	])
